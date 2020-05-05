//
//  ViewController.swift
//  VideoEdit
//
//  Created by milan.mia on 5/2/20.
//  Copyright © 2020 fftsys. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var playerView: PlayerView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let path = Bundle.main.path(forResource: "mask", ofType:"mp4")
        
        print(path!)
        let asset = AVAsset.init(url: URL.init(fileURLWithPath: path!))

        
        
        let vidEdit = videoEditor()
        playerView.player = vidEdit.createShow(asset: asset)
        playerView.player?.play()
    }


}


class videoEditor {
    private func outputURL(ext: String) -> URL? {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory,
                                                               in: .userDomainMask).first else {
                                                                return nil
        }
        return documentDirectory.appendingPathComponent("mergeVideo-\(Date.timeIntervalSinceReferenceDate).\(ext)")
    }
    func createShow(asset:AVAsset) -> AVPlayer {
        let mutableComposition = AVMutableComposition()

        // Create a mutableComposition for all the tracks present in the asset.
        guard let sourceVideoTrack = asset.tracks(withMediaType: AVMediaType.video).first else {
            print("Could not get video track from asset")
            return AVPlayer()
        }
        //let defaultVideoTransform = sourceVideoTrack.preferredTransform

        let sourceAudioTrack = asset.tracks(withMediaType: AVMediaType.audio).first
        let mutableCompositionVideoTrack = mutableComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let mutableCompositionAudioTrack = mutableComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)

        do {
            try mutableCompositionVideoTrack?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: asset.duration), of: sourceVideoTrack, at: CMTime.zero)
            if let sourceAudioTrack = sourceAudioTrack {
                try mutableCompositionAudioTrack?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: asset.duration), of: sourceAudioTrack, at: CMTime.zero)
            }
        }
        catch {
            print("Could not insert time range into video/audio mutable composition: \(error)")
        }
        //mutableCompositionVideoTrack?.preferredTransform = defaultVideoTransform

        
        
//        let videoComposition = AVMutableVideoComposition.init(asset: asset, applyingCIFiltersWithHandler: { (request:AVAsynchronousCIImageFilteringRequest) in
//            let source = request.sourceImage.clampedToExtent()
////            chromaticFilter.inputImage = source;
////            let output = chromaticFilter.outputImage
//            request.finish(with: source, context: nil)
//        })
        
        let img1 = UIImage.init(named: "img1")
        let img2 = UIImage.init(named: "img2")
        
        let ciImg1 = CIImage.init(image: img1!)
        let ciImg2 =  CIImage.init(image: img2!)
        
        let playerItem = AVPlayerItem.init(asset: mutableComposition)
        
        
        playerItem.videoComposition = AVVideoComposition(asset: asset) { request in
            let blurred = request.sourceImage.clampedToExtent()
            let composite = blurred
                .applyingFilter("CISubtractBlendMode",
                                parameters: [kCIInputBackgroundImageKey: ciImg1!])
 /*
            let comp = ciImg2!
                .applyingFilter("CISubtractBlendMode",
                                parameters: [kCIInputBackgroundImageKey: blurred,
                                             kCIInputImageKey: ciImg1!])

            
            let transparent = ciImg2!
                    .applyingFilter("CIMaskToAlpha",
                            parameters: [kCIInputImageKey: blurred])
*/
            let output = composite.clampedToExtent()
            request.finish(with: output, context: nil)
        }
        
        //CIBlendWithMask
        //CISoftLightBlendMode
        //CISubtractBlendMode
        //CGBlendMode.softLight
        //CGBlendMode.sourceIn
        //CISourceInBlendMode
        //CIDifferenceBlendMode
        //CISubtractBlendMode
        //CIExclusionBlendMode
        //CIMaskToAlpha
        //kCIInputImageKey
        
        let avplayer = AVPlayer.init(playerItem: playerItem)
        
        
        let outputurl = outputURL(ext: "mp4")
        print(outputurl ?? "")
        guard let exporter = AVAssetExportSession(asset: mutableComposition,
                                                  presetName: AVAssetExportPresetHighestQuality) else {
                                                    return AVPlayer()
        }
        
        print("Video Duration: \(asset.duration.seconds)")
        print("Composition Duration: \(mutableComposition.duration.seconds)")
        
        exporter.outputURL = outputurl
        exporter.outputFileType = AVFileType.mp4
        exporter.shouldOptimizeForNetworkUse = true
        //exporter.videoComposition = videoComposition // 👈

        exporter.exportAsynchronously {
            switch exporter.status {
            case .completed:
                print(exporter.error?.localizedDescription)
            case .failed:
                print(exporter.error?.localizedDescription)
            default:
                print("Default")
            }
//            PHPhotoLibrary.sharedPhotoLibrary().performChanges({
//                PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(outputURL)
//            }) { (success: Bool, error: NSError?) -> Void in
//                if success {
//                } else {
//                }
//            }
        }
        
        return avplayer
        
    }
}


extension UIImage {
    /// Create UIImage by masking current image with another image.
    /// Treat white as transparent.
    ///
    /// - parameter image: Image for masking
    ///
    /// - returns: The created image. Nil on error.
    func masked(with image: UIImage) -> UIImage? {
        guard let maskRef = image.safeCgImage,
            let ref = safeCgImage,
            let dataProvider = maskRef.dataProvider else {
                return nil
        }

        let mask = CGImage(maskWidth: maskRef.width,
                           height: maskRef.height,
                           bitsPerComponent: maskRef.bitsPerComponent,
                           bitsPerPixel: maskRef.bitsPerPixel,
                           bytesPerRow: maskRef.bytesPerRow,
                           provider: dataProvider,
                           decode: nil,
                           shouldInterpolate: false)
        return mask
            .flatMap { ref.masking($0) }
            .map { UIImage(cgImage: $0) }
    }
}

extension UIImage {
    var safeCiImage: CIImage? {
        return self.ciImage ?? CIImage(image: self)
    }

    var safeCgImage: CGImage? {
        if let cgImge = self.cgImage {
            return cgImge
        }
        if let ciImage = safeCiImage {
            let context = CIContext(options: nil)
            return context.createCGImage(ciImage, from: ciImage.extent)
        }
        return nil
    }
}

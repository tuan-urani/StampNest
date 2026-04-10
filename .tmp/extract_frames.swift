import Foundation
import AVFoundation
import AppKit

let path = "/Users/uranidev/Downloads/snapsave.vn_seedobery_69d3c3ec785ac (online-video-cutter.com).mp4"
let outDir = "/Users/uranidev/Documents/stamp_v2/.tmp/video_swift"

let fm = FileManager.default
try? fm.createDirectory(atPath: outDir, withIntermediateDirectories: true)

let url = URL(fileURLWithPath: path)
let asset = AVURLAsset(url: url)
let duration = CMTimeGetSeconds(asset.duration)
print("duration=\(duration)")

let generator = AVAssetImageGenerator(asset: asset)
generator.appliesPreferredTrackTransform = true
generator.requestedTimeToleranceAfter = .zero
generator.requestedTimeToleranceBefore = .zero

let count = 24
var times: [NSValue] = []
if duration > 0 {
    for i in 0..<count {
        let t = duration * Double(i) / Double(count - 1)
        times.append(NSValue(time: CMTime(seconds: t, preferredTimescale: 600)))
    }
}

for (idx, tVal) in times.enumerated() {
    let t = tVal.timeValue
    do {
        let img = try generator.copyCGImage(at: t, actualTime: nil)
        let rep = NSBitmapImageRep(cgImage: img)
        if let data = rep.representation(using: .png, properties: [:]) {
            let out = "\(outDir)/frame_\(String(format:"%03d", idx)).png"
            try data.write(to: URL(fileURLWithPath: out))
            print("wrote \(out)")
        }
    } catch {
        print("failed at \(CMTimeGetSeconds(t)): \(error)")
    }
}

import UIKit
import Vision
import CoreImage


enum ImagePreProcessor {

    private static let ciContext = CIContext()

    /// Returns a new UIImage whose underlying pixel data matches `.up` orientation.
    /// If the image is already `.up`, it is returned unchanged (no re-draw cost).
    static func normalizeOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        guard let cgImage = image.cgImage else { return image }

        let size = CGSize(width: image.size.width, height: image.size.height)

        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        defer { UIGraphicsEndImageContext() }

        image.draw(in: CGRect(origin: .zero, size: size))

        guard let normalized = UIGraphicsGetImageFromCurrentImageContext() else {
            return UIImage(cgImage: cgImage, scale: image.scale, orientation: .up)
        }
        return normalized
    }

    /// Normalizes orientation and scales the image down so the longest
    /// edge is at most `maxEdge` points.
    static func prepare(_ image: UIImage, maxEdge: CGFloat = 2048) -> UIImage {
        let oriented = normalizeOrientation(image)

        let longest = max(oriented.size.width, oriented.size.height)
        guard longest > maxEdge else { return oriented }

        let scale = maxEdge / longest
        let newSize = CGSize(width: oriented.size.width * scale,
                             height: oriented.size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }

        oriented.draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext() ?? oriented
    }

    // MARK: - Person Background Removal (for avatar/mannequin)

    /// Uses Vision's person segmentation to remove the background behind a person,
    /// returning a transparent-background UIImage.
    static func removePersonBackground(_ image: UIImage) async -> UIImage {
        let prepared = prepare(image)
        guard let cgImage = prepared.cgImage else { return prepared }

        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .accurate
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
            guard let result = request.results?.first else {
                return prepared
            }
            let maskBuffer = result.pixelBuffer
            return applyMask(maskBuffer, to: cgImage) ?? prepared
        } catch {
            print("Person segmentation failed: \(error)")
            return prepared
        }
    }

    // MARK: - Foreground Subject Removal (for clothing items)

    /// Uses Vision's foreground instance mask to isolate the main subject (clothing),
    /// returning a transparent-background UIImage.
    static func removeForegroundBackground(_ image: UIImage) async -> UIImage {
        let prepared = prepare(image)
        guard let cgImage = prepared.cgImage else { return prepared }

        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
            guard let result = request.results?.first else {
                return prepared
            }

            // Generate a mask for all foreground instances
            let allInstances = result.allInstances
            let maskBuffer = try result.generateScaledMaskForImage(
                forInstances: allInstances,
                from: handler
            )
            return applyMask(maskBuffer, to: cgImage) ?? prepared
        } catch {
            print("Foreground segmentation failed: \(error)")
            return prepared
        }
    }

    // MARK: - Shared Mask Application

    /// Applies a grayscale mask pixel buffer to a CGImage, producing a UIImage
    /// with a transparent background where the mask is black.
    private static func applyMask(_ maskBuffer: CVPixelBuffer, to cgImage: CGImage) -> UIImage? {
        let originalCI = CIImage(cgImage: cgImage)
        let maskCI = CIImage(cvPixelBuffer: maskBuffer)

        // Scale mask to match original image size
        let scaleX = originalCI.extent.width / maskCI.extent.width
        let scaleY = originalCI.extent.height / maskCI.extent.height
        let scaledMask = maskCI.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        // Use CIBlendWithMask: where mask is white, show original; where black, show transparent
        let transparentBackground = CIImage(color: CIColor.clear).cropped(to: originalCI.extent)

        guard let blendFilter = CIFilter(name: "CIBlendWithMask") else { return nil }
        blendFilter.setValue(originalCI, forKey: kCIInputImageKey)
        blendFilter.setValue(transparentBackground, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(scaledMask, forKey: kCIInputMaskImageKey)

        guard let outputCI = blendFilter.outputImage,
              let outputCG = ciContext.createCGImage(outputCI, from: originalCI.extent) else {
            return nil
        }

        return UIImage(cgImage: outputCG)
    }
}

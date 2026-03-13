import SwiftUI
import UIKit
import PhotosUI

// MARK: - PHPickerViewController wrapper
// Present this as a .sheet() — works reliably everywhere, no overlay conflicts.
struct PhotoLibraryPicker: UIViewControllerRepresentable {
    var onImage: (UIImage?, String?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onImage: onImage) }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ vc: PHPickerViewController, context: Context) {}

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onImage: (UIImage?, String?) -> Void
        init(onImage: @escaping (UIImage?, String?) -> Void) { self.onImage = onImage }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            // Do NOT call picker.dismiss() here — SwiftUI manages dismissal
            // via the sheet binding. Manual dismiss causes the parent sheet to close too.
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else {
                onImage(nil, nil); return
            }
            let suggestedName = provider.suggestedName
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                DispatchQueue.main.async { self.onImage(object as? UIImage, suggestedName) }
            }
        }
    }
}

// MARK: - Camera picker wrapper
struct CameraPickerUIKit: UIViewControllerRepresentable {
    var onCapture: (UIImage?, String?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let vc = UIImagePickerController()
        vc.delegate = context.coordinator
        // Falls back to photo library on Simulator where camera is unavailable
        vc.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        vc.allowsEditing = false
        return vc
    }

    func updateUIViewController(_ vc: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage?, String?) -> Void
        init(onCapture: @escaping (UIImage?, String?) -> Void) { self.onCapture = onCapture }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            // Let SwiftUI handle dismissal via the binding to avoid closing the parent sheet
            self.onCapture(info[.originalImage] as? UIImage, nil)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            self.onCapture(nil, nil)
        }
    }
}


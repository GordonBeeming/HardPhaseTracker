import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let filename: String
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        // Create a temporary file to share
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        var itemsToShare: [Any] = []
        
        // If the first item is Data, write it to a file
        if let data = items.first as? Data {
            do {
                try data.write(to: tempURL)
                itemsToShare.append(tempURL)
            } catch {
                // Fallback to sharing the data directly
                itemsToShare = items
            }
        } else {
            itemsToShare = items
        }
        
        let controller = UIActivityViewController(
            activityItems: itemsToShare,
            applicationActivities: nil
        )
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

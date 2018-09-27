//
//  Operations.swift
//  InfiniteScroll
//
//  Created by Son HD on 9/18/18.
//  Copyright © 2018 joker. All rights reserved.
//

import Foundation
import UIKit

protocol PhotoCell {
    var imageURL: URL? { get set }
    var image: UIImage? { get set }
    var state: PhotoState { get set }
}

final class ImageDownloader: Operation {
    var photoCell: PhotoCell
    
    init(_ photoCell: PhotoCell) {
        self.photoCell = photoCell
    }
    
    override func main() {
        if isCancelled { return }
        
        guard let url = photoCell.imageURL,
            let imageData = try? Data(contentsOf: url) else { return }
        
        if isCancelled { return }
        
        if imageData.isEmpty {
            photoCell.state = .failed
            photoCell.image = UIImage(color: .red, size: CGSize(width: 400, height: 400))
        } else {
            photoCell.state = .downloaded
            photoCell.image = UIImage(data: imageData)
        }
    }
}

final class ImageFiltration: Operation {
    var photoCell: PhotoCell
    
    init(_ photoCell: PhotoCell) {
        self.photoCell = photoCell
    }
    
    override func main() {
        if isCancelled { return }
        
        guard photoCell.state == .downloaded else { return }
        
        if let image = photoCell.image,
            let filteredImage = applySepiaFilter(image) {
            photoCell.image = filteredImage
            photoCell.state = .filtered
        }
    }
    
    func applySepiaFilter(_ image: UIImage) -> UIImage? {
        guard let data = UIImagePNGRepresentation(image) else { return nil }
        let inputImage = CIImage(data: data)
        
        if isCancelled {
            return nil
        }
        
        let context = CIContext(options: nil)
        
        guard let filter = CIFilter(name: "CISepiaTone") else { return nil }
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(0.8, forKey: "inputIntensity")
        
        if isCancelled {
            return nil
        }
        
        guard
            let outputImage = filter.outputImage,
            let outImage = context.createCGImage(outputImage, from: outputImage.extent)
            else {
                return nil
        }
        
        return UIImage(cgImage: outImage)
    }
}

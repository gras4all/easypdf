//
//  PDFBuilder.swift
//  YourDocs
//
//  Created by Andrei Grunenkov on 30.09.2023.
//

import Foundation
import UIKit
import Photos
import PDFKit

enum Format: String {
    case pdf = "PDF"
    case jpg = "JPG"
}

enum Compression {
    
    case none
    case low
    case medium
    case high
    
    //MARK: - Compression settings
    
    var jpgCompress: CGFloat {
        switch self {
        case .none:
            return 1
        case .low:
            return 0.8
        case .medium:
            return 0.8
        case .high:
            return 0.8
        }
    }
    
    var scale: CGFloat {
        switch self {
        case .none:
            return 1
        case .low:
            return 0.8
        case .medium:
            return 0.6
        case .high:
            return 0.4
        }
    }
}

enum EditType: Equatable {
    case copy
    case move
    case converte
    case selectSequence
    case combine
    case apart
    case compress
    case archive
    case save
    case putHere
    case none
    case addIntoWidget
    case print
    case share
}


protocol IEasyPDFCreator: class {
    func pdfFromAssets(name: String, assets: [PHAsset], author: String, completionHandler: @escaping (URL?)->())
    func pdfFromImages(name: String, images: [UIImage], author: String, completionHandler: @escaping (URL?)->())
    func dividePDF(sourceFileUrl: URL, sourceFileName: String, destinationURL: URL, format: Format, isCopy: Bool, author: String, completionHandler: @escaping ((URL)->Void))
    func compressPDF(moveUrls: [URL], destinationURL: URL, compress: Compression, isCopy: Bool, author: String, completionHandler: @escaping (([URL])->Void))
}

/*struct DocumentsDirectory {
    static let localDocumentsURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: .userDomainMask).last!
    static let iCloudDocumentsURL = FileManager.default.url(forUbiquityContainerIdentifier: AppConstants.iCloud.containerId)?.appendingPathComponent("Documents")
}*/


final class EasyPDFCreator: IEasyPDFCreator {
    
    //var isCloudSyncOn = false
    
    let defaultScale = 0.8
    
    func pdfFromImages(name: String, images: [UIImage], author: String, completionHandler: @escaping (URL?)->()) {
        let documentsPath = FileManager.default.temporaryDirectory
        let newDocumentURL: URL? = documentsPath.appendingPathComponent("\(name).pdf")
        let format = UIGraphicsPDFRendererFormat()
        let metaData = [
            kCGPDFContextAuthor: author
        ]
        format.documentInfo = metaData as [String: Any]
        let pageRect = getPageRect(image: images.first)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect,
                                             format: format)
        let data = renderer.pdfData { (context) in
            images.forEach { (image) in
                context.beginPage()
                let resized = image.resizeImage(image.size.width > image.size.height ? pageRect.width : pageRect.height, opaque: false)
                resized.draw(at: pageRect.origin)
            }
        }
        if let newDocumentURL = newDocumentURL {
            let pdfDocument = PDFDocument(data: data)
            pdfDocument?.write(to: newDocumentURL)
            completionHandler(newDocumentURL)
        } else {
            completionHandler(newDocumentURL)
        }
    }

    func pdfFromAssets(name: String, assets: [PHAsset], author: String, completionHandler: @escaping (URL?)->())  {
        let newName = PHAssetResource.assetResources(for: assets.first!).first?.originalFilename ?? name
        var images: [UIImage] = []
        let assetsGroup = DispatchGroup()
        for asset in assets {
            assetsGroup.enter()
            PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight), contentMode: .default, options: nil) { (image, info) in

                let previewImage = (info?[PHImageResultIsDegradedKey] as? Int ?? 1) == 1
                if !previewImage {
                    if let image = image {
                        images.append(image)
                    }
                    assetsGroup.leave()
                }
            }
        }
        assetsGroup.notify(queue: .main, execute: { [weak self] in
            guard let self = self else { return }
            let documentsPath = FileManager.default.temporaryDirectory
            let newDocumentURL: URL? = documentsPath.appendingPathComponent("\(newName).pdf")
            let format = UIGraphicsPDFRendererFormat()
            let metaData = [
                kCGPDFContextAuthor: author
            ]
            format.documentInfo = metaData as [String: Any]
            let pageRect = self.getPageRect(image: images.first)
            let renderer = UIGraphicsPDFRenderer(bounds: pageRect,
                                                 format: format)
            let data = renderer.pdfData { (context) in
                images.forEach { (image) in
                    context.beginPage()
                    let resized = image.resizeImage(image.size.width > image.size.height ? pageRect.width : pageRect.height, opaque: false)
                    resized.draw(at: pageRect.origin)
                }
            }
            if let newDocumentURL = newDocumentURL {
                let pdfDocument = PDFDocument(data: data)
                pdfDocument?.write(to: newDocumentURL)
                completionHandler(newDocumentURL)
            } else {
                completionHandler(newDocumentURL)
            }
        })
    }
    
    func dividePDF(sourceFileUrl: URL, sourceFileName: String, destinationURL: URL, format: Format, isCopy: Bool, author: String, completionHandler: @escaping ((URL)->Void)) {
        let _ = sourceFileUrl.startAccessingSecurityScopedResource()
        guard let document = CGPDFDocument(sourceFileUrl as CFURL) else {
            completionHandler(destinationURL)
            return
        }
        sourceFileUrl.stopAccessingSecurityScopedResource()
        let pagesGroup = DispatchGroup()
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = String(document.numberOfPages).count
        for i in 1...document.numberOfPages {
            guard let page = document.page(at: i),
                  let numberOfPage = formatter.string(from: i as NSNumber) else { continue }
            
            let folderPath = destinationURL.deletingLastPathComponent()
            let folderName = folderPath.lastPathComponent
            
            let needCopy = isCopy && self.isFileExist(url: sourceFileUrl,
                                                      editType: .apart,
                                                      lastPathComponent: "\(folderName)/\(destinationURL.lastPathComponent)",
                                                      pageNumber: numberOfPage,
                                                      format: format)
            
            let newFileName = sourceFileUrl.getNewFileName(editType: .apart, isCopy: needCopy, pageNumber: numberOfPage, format: format)
            
            let newDocumentUrl = destinationURL.appendingPathComponent(newFileName)
            pagesGroup.enter()
            DispatchQueue.global().async {
                if let pageImage = self.getImageFromDocumentPage(page: page) {
                    switch format {
                    case .jpg:
                        if let data = UIImageJPEGRepresentation(pageImage, 1) {
                            try? data.write(to: newDocumentUrl)
                        }
                    case .pdf:
                        let pdfData = self.getPDFDataFromImages(images: [pageImage],
                                                                pageRect: CGRect(x: 0,
                                                                                 y: 0,
                                                                                 width: pageImage.size.width,
                                                                                 height: pageImage.size.height),
                                                                author: author)
                        let pdfDocument = PDFDocument(data: pdfData)
                        pdfDocument?.write(to: newDocumentUrl)
                    }
                }
                pagesGroup.leave()
            }
        }
        pagesGroup.notify(queue: DispatchQueue.global(), execute: {
            completionHandler(destinationURL)
        })
    }
    
    func compressPDF(moveUrls: [URL], destinationURL: URL, compress: Compression, isCopy: Bool, author: String, completionHandler: @escaping (([URL])->Void)) {
        var newUrls:[URL] = []
        let pdfGroup = DispatchGroup()
        for url in moveUrls {
            let _ = url.startAccessingSecurityScopedResource()
            guard let document = CGPDFDocument(url as CFURL) else { return }
            url.stopAccessingSecurityScopedResource()
            pdfGroup.enter()
            DispatchQueue.global().async {
                
                let needCopy = isCopy && self.isFileExist(url: url, editType: .compress, lastPathComponent: destinationURL.lastPathComponent)
                
                let newFileName = url.getNewFileName(editType: .compress, isCopy: needCopy)
                
                let newDocumentUrl = destinationURL.appendingPathComponent(newFileName)
                var assets: [UIImage] = []
                
                for i in 1...document.numberOfPages {
                    guard let page = document.page(at: i) else { continue }
                    autoreleasepool {
                        if let pageImage = self.getImageFromDocumentPage(page: page, compress: compress) {
                            assets.append(pageImage)
                        }
                    }
                }
                
                if let asset = assets.first {
                    let pdfRect = CGRect(x: 0, y: 0, width: asset.size.width,
                                                     height: asset.size.height)
                    let pdfData = self.getPDFDataFromImages(images: assets,
                                                            pageRect: pdfRect,
                                                            author: author)
                    let pdfDocument = PDFDocument(data: pdfData)
                    
                    pdfDocument?.write(to: newDocumentUrl)
                    newUrls.append(newDocumentUrl)
                }
                
                pdfGroup.leave()
            }
        }
        pdfGroup.notify(queue: DispatchQueue.global(), execute: {
            completionHandler(newUrls)
        })
    
    }
    
}

//MARK: - private methods
private extension EasyPDFCreator {
    
    func getImageFromDocumentPage(page: CGPDFPage, compress: Compression = .none)->UIImage? {
        let pageRect = page.getBoxRect(.mediaBox)
        let imageRect = CGRect(x: 0, y: 0, width: pageRect.size.width * compress.scale,
                               height: pageRect.size.height * compress.scale)
        let renderer = UIGraphicsImageRenderer(size: imageRect.size)
        
        let imageData = renderer.jpegData(withCompressionQuality: compress.jpgCompress) { ctx in
            UIColor.white.set()
            ctx.fill(pageRect)
            ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height * compress.scale)
            ctx.cgContext.scaleBy(x: 1.0 * compress.scale, y: -1.0 * compress.scale)
            ctx.cgContext.drawPDFPage(page)
        }
        return UIImage(data: imageData)
    }
    
    func getPDFDataFromImages(images: [UIImage], pageRect: CGRect, author: String) -> Data {
        let format = UIGraphicsPDFRendererFormat()
        let metaData = [
            kCGPDFContextTitle: author
        ]
        format.documentInfo = metaData as [String: Any]
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        return pdfRenderer.pdfData { (context) in
            images.forEach { (image) in
                context.beginPage()
                image.draw(at: pageRect.origin)
            }
        }

    }
    
    func isFileExist(url: URL, editType: EditType, lastPathComponent: String, pageNumber: String = "1", format: Format = .pdf) -> Bool {
        if detectFileExist(moveUrls: [url], lastPathComponent: lastPathComponent, newFileNameWithExt: url.getNewFileName(editType: editType, pageNumber: pageNumber, format: format)) {
            return true
        }
        return false
    }
    
    func getPageRect(image: UIImage?) -> CGRect {
        let scale = defaultScale
        let pageRect = CGRect(x: 0, y: 0, width: 595 * scale, height: 842 * scale)
        guard let image = image else { return pageRect }
        let resized = image.resizeImage(image.size.width > image.size.height ? pageRect.width : pageRect.height, opaque: false)
        return CGRect(x: 0, y: 0, width: resized.size.width, height: resized.size.height)
    }
    
    func detectFileExist(moveUrls: [URL], lastPathComponent: String, newFileNameWithExt: String? = nil) -> Bool {
        let fileManager = FileManager.default

        for url in moveUrls {
            let urlWithoutExtension = url.deletingPathExtension()
            let fileName = newFileNameWithExt ?? urlWithoutExtension.lastPathComponent
            var toDocumentsPath = getDocumentDiretoryURL().appendingPathComponent(lastPathComponent + "/" + fileName)
            if newFileNameWithExt == nil {
                toDocumentsPath = toDocumentsPath.appendingPathExtension(url.pathExtension)
            }
            return fileManager.fileExists(atPath: toDocumentsPath.path)
        }
        return false
    }
    
    func getDocumentDiretoryURL() -> URL {
        /*if isCloudSyncOn {
            //print(DocumentsDirectory.iCloudDocumentsURL!)
            return DocumentsDirectory.iCloudDocumentsURL!
        } else {
          //  print(DocumentsDirectory.localDocumentsURL)
            return DocumentsDirectory.localDocumentsURL
        }*/
        FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: .userDomainMask).last!
    }
    
}

 

//
//  URL+Filename.swift
//  EasyPDF
//
//  Created by Andrey Grunenkov on 25.11.2023.
//

import Foundation

extension URL {
    
    func getNewFileName(editType: EditType, isCopy: Bool = false, pageNumber: String = "1", format: Format = .pdf) -> String {
        let fileName = deletingPathExtension().lastPathComponent
        let fileExtension = pathExtension
        let copySuffix = isCopy ? " (Copy)" : ""
        switch editType {
        case .compress:
            return "Compressed_\(fileName)\(copySuffix).\(fileExtension)"
        case .apart:
            return "\(fileName) \(pageNumber)\(copySuffix).\(format.rawValue.lowercased())"
        case .converte:
            return "\(fileName)\(copySuffix).pdf"
        case .combine:
            return "NEW_PDF \(fileName)\(copySuffix).pdf"
        default:
            return "NEW_\(fileName)\(copySuffix).\(fileExtension)"
        }
    }
    
}
    


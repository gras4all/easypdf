# EasyPDF

The **EasyPDF** is framework for iOS provides a convenient set of tools for handling PDF creation, manipulation, and compression seamlessly within your iOS applications. With a focus on simplicity and efficiency, this framework offers a variety of functionalities.

## Integration
To integrate the EasyPDF framework into your iOS project, simply include it as a dependency using CocoaPods or another dependency manager.

```ruby
pod 'EasyPDF', :git => 'git@github.com:gras4all/easypdf.git'
```

## Methods description

### 1. `pdfFromAssets`
   - **Description:** Generates a PDF document from a collection of assets.
   - **Parameters:**
     - `name`: The name for the resulting PDF file.
     - `assets`: An array of `PHAsset` objects to include in the PDF.
     - `author`: The author information to be embedded in the PDF metadata.
     - `completionHandler`: A closure called upon completion with the URL of the generated PDF file.

### 2. `pdfFromImages`
   - **Description:** Creates a PDF document from a set of UIImage objects.
   - **Parameters:**
     - `name`: The desired name for the output PDF file.
     - `images`: An array of `UIImage` objects to be included in the PDF.
     - `author`: The author information for the PDF metadata.
     - `completionHandler`: A closure to handle the URL of the generated PDF upon completion.

### 3. `dividePDF`
   - **Description:** Splits an existing PDF file into multiple parts.
   - **Parameters:**
     - `sourceFileUrl`: The URL of the source PDF file.
     - `sourceFileName`: The name of the source PDF file.
     - `destinationURL`: The URL where the divided PDF parts will be saved.
     - `format`: The desired format for the divided PDF parts.
     - `isCopy`: A flag indicating whether to create a copy of the source PDF.
     - `author`: The author information for the PDF metadata.
     - `completionHandler`: A closure to handle the URL of the divided PDF parts upon completion.

### 4. `compressPDF`
   - **Description:** Reduces the size of PDF files by compressing them.
   - **Parameters:**
     - `moveUrls`: An array of URLs for the PDF files to be compressed.
     - `destinationURL`: The URL where the compressed PDF files will be saved.
     - `compress`: The desired compression level.
     - `isCopy`: A flag indicating whether to create a copy of the source PDFs.
     - `author`: The author information for the PDF metadata.
     - `completionHandler`: A closure to handle an array of URLs for the compressed PDF files upon completion.


## Author

Andrei Grunenkov, gras4all@gmail.com

## License

EasyPDF is available under the MIT license. See the LICENSE file for more info.

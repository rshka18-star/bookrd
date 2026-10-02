import Foundation
import PDFKit
import UniformTypeIdentifiers

enum BookLoaderError: LocalizedError {
    case unsupported
    case noText

    var errorDescription: String? {
        switch self {
        case .unsupported: return "This file type is not supported."
        case .noText: return "No readable text was found. Scanned PDFs need OCR."
        }
    }
}

enum BookLoader {
    static let allowedTypes: [UTType] = [.pdf, .plainText, .text, .rtf]

    static func load(url: URL) throws -> LoadedBook {
        let ext = url.pathExtension.lowercased()
        let title = url.deletingPathExtension().lastPathComponent

        if ext == "pdf" {
            guard let pdf = PDFDocument(url: url) else { throw BookLoaderError.unsupported }
            var pages: [BookPage] = []
            for i in 0..<pdf.pageCount {
                let pageText = pdf.page(at: i)?.string?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                pages.append(BookPage(number: i + 1, text: pageText))
            }
            guard pages.contains(where: { !$0.text.isEmpty }) else { throw BookLoaderError.noText }
            return LoadedBook(title: title, pages: pages)
        }

        if ext == "txt" || ext == "text" {
            let text = try String(contentsOf: url, encoding: .utf8)
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw BookLoaderError.noText
            }
            return LoadedBook(title: title, pages: [BookPage(number: 1, text: text)])
        }

        if ext == "rtf" {
            let data = try Data(contentsOf: url)
            let attr = try NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil
            )
            let text = attr.string
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw BookLoaderError.noText
            }
            return LoadedBook(title: title, pages: [BookPage(number: 1, text: text)])
        }

        throw BookLoaderError.unsupported
    }
}

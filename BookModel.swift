import Foundation

struct BookPage: Identifiable, Hashable {
    let id = UUID()
    let number: Int
    let text: String
}

struct LoadedBook {
    let title: String
    let pages: [BookPage]

    var fullText: String {
        pages.map(\.text).joined(separator: "\n\n")
    }
}

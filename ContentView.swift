import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var speech: SpeechManager

    @State private var book: LoadedBook?
    @State private var selectedPage = 1
    @State private var showImporter = false
    @State private var showReader = false
    @State private var errorMessage: String?

    private let cyan = Color(red: 0.12, green: 0.85, blue: 1)
    private let blue = Color(red: 0.12, green: 0.47, blue: 1)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.01, green: 0.03, blue: 0.07),
                    Color(red: 0.01, green: 0.10, blue: 0.20),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    header
                    hero
                    titleBlock
                    progressBlock
                    controls
                    pageSelector
                    openBookButton
                    backgroundBanner
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: BookLoader.allowedTypes,
            allowsMultipleSelection: false,
            onCompletion: handleFile
        )
        .sheet(isPresented: $showReader) {
            if let book {
                ReaderView(book: book, selectedPage: $selectedPage)
            }
        }
        .alert("Spfive", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var header: some View {
        VStack(spacing: 5) {
            Image("SpfiveLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 145)
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .shadow(color: blue.opacity(0.85), radius: 28)

            Text("BOOKS COME TO LIFE")
                .font(.caption2.weight(.medium))
                .tracking(4)
                .foregroundStyle(.white.opacity(0.65))
        }
        .padding(.top, 8)
    }

    private var hero: some View {
        RoundedRectangle(cornerRadius: 28)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.02, green: 0.08, blue: 0.18),
                        Color(red: 0.02, green: 0.24, blue: 0.42),
                        Color(red: 0.01, green: 0.04, blue: 0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                VStack(spacing: 18) {
                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 76))
                        .foregroundStyle(.white)
                        .shadow(color: cyan, radius: 18)

                    Text((book?.title ?? "YOUR BOOK").uppercased())
                        .font(.system(size: 29, weight: .bold, design: .serif))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.55)

                    if let book {
                        Text("\(book.pages.count) PAGE\(book.pages.count == 1 ? "" : "S")")
                            .font(.caption.weight(.semibold))
                            .tracking(3)
                            .foregroundStyle(.white.opacity(0.65))
                    } else {
                        Text("PDF • TXT • RTF")
                            .font(.caption.weight(.semibold))
                            .tracking(3)
                            .foregroundStyle(.white.opacity(0.65))
                    }
                }
                .padding()
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(cyan.opacity(0.75), lineWidth: 1.5)
            )
            .shadow(color: blue.opacity(0.35), radius: 20)
            .frame(height: 330)
    }

    private var titleBlock: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(book?.title ?? "Open a Book")
                    .font(.title2.bold())
                    .lineLimit(1)
                Text(book == nil ? "Spfive Reader" : "Text-to-Speech Book")
                    .foregroundStyle(.white.opacity(0.55))
            }
            Spacer()
            Image(systemName: "heart")
                .font(.title2)
        }
    }

    private var progressBlock: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.14)).frame(height: 5)
                    Capsule()
                        .fill(LinearGradient(colors: [cyan, blue], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(5, geo.size.width * speech.progress), height: 5)
                        .shadow(color: cyan.opacity(0.8), radius: 8)
                }
            }
            .frame(height: 5)

            HStack {
                Text("\(Int(speech.progress * 100))%")
                Spacer()
                Text("PAGE \(speech.currentPage)")
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.white.opacity(0.58))
        }
    }

    private var controls: some View {
        HStack(spacing: 22) {
            Button("↶15") { speech.skipBackSegment() }
                .controlStyle()

            Button {
                if speech.isSpeaking || speech.isPaused {
                    speech.toggle()
                } else if let book {
                    speech.read(book: book, fromPage: selectedPage)
                } else {
                    showImporter = true
                }
            } label: {
                Image(systemName: speech.isSpeaking ? "pause.fill" : "play.fill")
                    .font(.system(size: 30, weight: .bold))
                    .frame(width: 82, height: 82)
                    .background(
                        Circle()
                            .fill(Color(red: 0.01, green: 0.14, blue: 0.30))
                            .overlay(Circle().stroke(cyan, lineWidth: 2))
                            .shadow(color: cyan.opacity(0.8), radius: 18)
                    )
            }

            Button("15↷") { speech.skipForwardSegment() }
                .controlStyle()
        }
        .foregroundStyle(.white)
    }

    private var pageSelector: some View {
        Group {
            if let book, book.pages.count > 1 {
                VStack(spacing: 12) {
                    HStack {
                        Button("‹ Prev") {
                            selectedPage = max(1, selectedPage - 1)
                        }
                        .controlStyle()

                        Spacer()

                        VStack(spacing: 4) {
                            Text("Page")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            TextField("Page", value: $selectedPage, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .frame(width: 70, height: 44)
                                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(cyan.opacity(0.5)))
                                .onChange(of: selectedPage) { _, newValue in
                                    selectedPage = min(max(newValue, 1), book.pages.count)
                                }

                            Text("of \(book.pages.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button("Next ›") {
                            selectedPage = min(book.pages.count, selectedPage + 1)
                        }
                        .controlStyle()
                    }

                    Button("Read This Page") {
                        speech.readSinglePage(book: book, page: selectedPage)
                    }
                    .wideButton(cyan: cyan)

                    Button("Read From This Page") {
                        speech.read(book: book, fromPage: selectedPage)
                    }
                    .wideButton(cyan: blue)
                }
                .padding()
                .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 24))
            }
        }
    }

    private var openBookButton: some View {
        Button {
            showImporter = true
        } label: {
            HStack {
                Image(systemName: "book.fill")
                Text("Open Book").font(.title3.bold())
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding(.horizontal, 24)
            .frame(height: 66)
            .background(
                RoundedRectangle(cornerRadius: 33)
                    .fill(Color(red: 0.02, green: 0.12, blue: 0.26))
                    .overlay(RoundedRectangle(cornerRadius: 33).stroke(cyan, lineWidth: 2))
                    .shadow(color: blue.opacity(0.6), radius: 16)
            )
        }
        .foregroundStyle(.white)
    }

    private var backgroundBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "headphones")
                .font(.title2.bold())
                .foregroundStyle(cyan)
            VStack(alignment: .leading, spacing: 3) {
                Text("Keeps reading in background")
                    .font(.subheadline.bold())
                Text("Home Screen & Lock Screen supported")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
            }
            Spacer()
            Image(systemName: "waveform")
                .foregroundStyle(blue)
        }
        .padding(.horizontal, 18)
        .frame(height: 76)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(blue.opacity(0.35)))
        )
    }

    private func handleFile(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }

            let loaded = try BookLoader.load(url: url)
            speech.stop()
            book = loaded
            selectedPage = 1
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private extension View {
    func controlStyle() -> some View {
        self
            .font(.subheadline.bold())
            .frame(minWidth: 70, minHeight: 48)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
    }

    func wideButton(cyan: Color) -> some View {
        self
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(cyan.opacity(0.8)))
            )
    }
}

struct ReaderView: View {
    let book: LoadedBook
    @Binding var selectedPage: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        ForEach(book.pages) { page in
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Page \(page.number)")
                                    .font(.headline)
                                    .foregroundStyle(.blue)

                                Text(page.text.isEmpty ? "[No readable text on this page]" : page.text)
                                    .font(.system(size: 18, design: .serif))
                                    .lineSpacing(8)
                            }
                            .id(page.number)
                        }
                    }
                    .padding(22)
                }
                .onAppear {
                    proxy.scrollTo(selectedPage, anchor: .top)
                }
            }
            .background(Color(red: 0.02, green: 0.03, blue: 0.055))
            .navigationTitle(book.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

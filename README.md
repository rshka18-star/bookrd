# Spfive Reader — Native iPhone Background Version

This is the version to use if you want the book to KEEP READING when:
- you go to the iPhone Home Screen
- you switch to another app
- the screen locks

The WebApp version cannot guarantee this on iPhone.

## Included
- Complete Xcode project: `SpfiveReader.xcodeproj`
- Spfive logo inside the app
- Spfive logo as app icon
- PDF / TXT / RTF
- PDF page selector
- Previous / Next page
- Read This Page
- Read From This Page
- Text-to-Speech
- Background Audio mode
- Lock Screen / Control Center Play and Pause
- Dark neon-blue Spfive design

## Install on iPhone
You need a Mac with Xcode.

1. Unzip the file.
2. Double-click `SpfiveReader.xcodeproj`.
3. In Xcode select the `SpfiveReader` target.
4. Open **Signing & Capabilities**.
5. Select your Apple ID / Team under Signing.
6. Press `+ Capability`.
7. Add **Background Modes**.
8. Tick **Audio, AirPlay, and Picture in Picture**.
9. Connect your iPhone to the Mac.
10. Choose your iPhone at the top of Xcode.
11. Press ▶ Run.

The project already includes `UIBackgroundModes = audio` and uses
`AVAudioSession(.playback, .spokenAudio)` plus `AVSpeechSynthesizer`.

## Important
If you force-quit the app from the iPhone app switcher, iOS will stop it.
Normal Home Screen / app switching / screen lock is what background audio is designed for.

Scanned image-only PDFs still need OCR.

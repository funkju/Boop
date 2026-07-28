//
//  BoopTheme.swift
//  Boop
//
//  Boop's classic neon palette (from the original Colors.swift), rebuilt as
//  CodeEditSourceEditor themes.
//

import AppKit
import CodeEditSourceEditor

enum BoopTheme {

    // Original Boop accent colors
    private static let redey = NSColor(red: 1, green: 0.298, blue: 0.486, alpha: 1)          // #FF4C7C
    private static let bluish = NSColor(red: 0.5, green: 0.887, blue: 1, alpha: 1)           // #80E2FF
    private static let cyanish = NSColor(red: 0.16, green: 0.951, blue: 0.799, alpha: 1)     // #29F3CC
    private static let greenish = NSColor(red: 0.605, green: 1, blue: 0, alpha: 1)           // #9AFF00
    private static let orangeish = NSColor(red: 1, green: 0.698, blue: 0.298, alpha: 1)      // #FFB24C
    private static let yellowishy = NSColor(red: 0.988, green: 1, blue: 0.298, alpha: 1)     // #FCFF4C
    private static let commentGreyDarkest = NSColor(red: 0.533, green: 0.557, blue: 0.651, alpha: 1) // #888EA6

    private static let redButDarker = NSColor(red: 0.725, green: 0.094, blue: 0.263, alpha: 1)   // #B91843
    private static let blueButDarker = NSColor(red: 0, green: 0.416, blue: 0.718, alpha: 1)      // #006AB7
    private static let greenButDarker = NSColor(red: 0, green: 0.698, blue: 0, alpha: 1)         // #00B200
    private static let orangeABitDarker = NSColor(red: 1, green: 0.396, blue: 0.176, alpha: 1)   // #FF652D
    private static let cyanTinyBitDarker = NSColor(red: 0, green: 0.694, blue: 0.718, alpha: 1)  // #00B1B7
    private static let purpleButDarker = NSColor(red: 0.463, green: 0, blue: 0.463, alpha: 1)    // #760076

    static let dark = EditorTheme(
        text: .init(color: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)),
        insertionPoint: greenish,
        invisibles: .init(color: NSColor(srgbRed: 0.35, green: 0.35, blue: 0.35, alpha: 1)),
        // Semi-transparent so the window's glass material shows through the
        // editor, gutter, and minimap alike.
        background: NSColor(srgbRed: 24 / 255, green: 24 / 255, blue: 28 / 255, alpha: 0.5),
        lineHighlight: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.05),
        selection: NSColor(red: 0.19, green: 0.44, blue: 0.71, alpha: 1),
        keywords: .init(color: redey),
        commands: .init(color: cyanish),
        types: .init(color: bluish),
        attributes: .init(color: orangeish),
        variables: .init(color: bluish),
        values: .init(color: orangeish),
        numbers: .init(color: yellowishy),
        strings: .init(color: greenish),
        characters: .init(color: cyanish),
        comments: .init(color: commentGreyDarkest)
    )

    static let light = EditorTheme(
        text: .init(color: NSColor(srgbRed: 0.1, green: 0.1, blue: 0.1, alpha: 1)),
        insertionPoint: greenButDarker,
        invisibles: .init(color: NSColor(srgbRed: 0.75, green: 0.75, blue: 0.75, alpha: 1)),
        background: NSColor(srgbRed: 0.95, green: 0.95, blue: 0.95, alpha: 0.5),
        lineHighlight: NSColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.04),
        selection: NSColor(red: 0.19, green: 0.44, blue: 0.71, alpha: 0.35),
        keywords: .init(color: redButDarker),
        commands: .init(color: cyanTinyBitDarker),
        types: .init(color: blueButDarker),
        attributes: .init(color: orangeABitDarker),
        variables: .init(color: blueButDarker),
        values: .init(color: orangeABitDarker),
        numbers: .init(color: purpleButDarker),
        strings: .init(color: greenButDarker),
        characters: .init(color: cyanTinyBitDarker),
        comments: .init(color: commentGreyDarkest)
    )

    static func theme(for colorScheme: NSAppearance.Name?) -> EditorTheme {
        colorScheme == .darkAqua ? dark : light
    }
}

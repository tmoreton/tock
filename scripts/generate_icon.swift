#!/usr/bin/env swift
import AppKit
import CoreGraphics
import Foundation

// Renders the Tock app icon at every size required by macOS and writes them
// into the AppIcon.appiconset, also rewriting Contents.json. Re-runnable.

let assetsDir = CommandLine.arguments.dropFirst().first
    ?? "Tock/Assets.xcassets/AppIcon.appiconset"

struct IconEntry {
    let pixels: Int
    let filename: String
    let size: String
    let scale: String
}

let entries: [IconEntry] = [
    .init(pixels: 16,   filename: "icon_16x16.png",      size: "16x16",   scale: "1x"),
    .init(pixels: 32,   filename: "icon_16x16@2x.png",   size: "16x16",   scale: "2x"),
    .init(pixels: 32,   filename: "icon_32x32.png",      size: "32x32",   scale: "1x"),
    .init(pixels: 64,   filename: "icon_32x32@2x.png",   size: "32x32",   scale: "2x"),
    .init(pixels: 128,  filename: "icon_128x128.png",    size: "128x128", scale: "1x"),
    .init(pixels: 256,  filename: "icon_128x128@2x.png", size: "128x128", scale: "2x"),
    .init(pixels: 256,  filename: "icon_256x256.png",    size: "256x256", scale: "1x"),
    .init(pixels: 512,  filename: "icon_256x256@2x.png", size: "256x256", scale: "2x"),
    .init(pixels: 512,  filename: "icon_512x512.png",    size: "512x512", scale: "1x"),
    .init(pixels: 1024, filename: "icon_512x512@2x.png", size: "512x512", scale: "2x"),
]

func drawIcon(pixels: Int) -> Data {
    let s = CGFloat(pixels)

    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = NSSize(width: pixels, height: pixels)

    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx
    let cg = ctx.cgContext

    // Apple-style canvas: squircle inset from edges, slightly higher than centered to leave shadow room.
    let topInset    = s * 0.085
    let bottomInset = s * 0.115
    let sideInset   = s * 0.085
    let iconRect = NSRect(
        x: sideInset,
        y: bottomInset,
        width: s - sideInset * 2,
        height: s - topInset - bottomInset
    )
    let cornerRadius = iconRect.width * 0.2237
    let squircle = NSBezierPath(roundedRect: iconRect, xRadius: cornerRadius, yRadius: cornerRadius)

    // Drop shadow under the squircle.
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
    shadow.shadowOffset = NSSize(width: 0, height: -s * 0.008)
    shadow.shadowBlurRadius = s * 0.025
    shadow.set()
    NSColor.black.setFill()
    squircle.fill()
    NSGraphicsContext.restoreGraphicsState()

    // Tomato-red gradient body.
    NSGraphicsContext.saveGraphicsState()
    squircle.addClip()
    let body = NSGradient(colors: [
        NSColor(srgbRed: 0.98, green: 0.39, blue: 0.32, alpha: 1.0),
        NSColor(srgbRed: 0.80, green: 0.17, blue: 0.13, alpha: 1.0),
    ])!
    body.draw(in: iconRect, angle: -90)

    // Subtle top highlight.
    let highlightRect = NSRect(
        x: iconRect.minX,
        y: iconRect.midY,
        width: iconRect.width,
        height: iconRect.height / 2
    )
    let highlight = NSGradient(colors: [
        NSColor.white.withAlphaComponent(0.18),
        NSColor.white.withAlphaComponent(0.0),
    ])!
    highlight.draw(in: highlightRect, angle: -90)
    NSGraphicsContext.restoreGraphicsState()

    // Timer ring.
    let ringInsetRatio: CGFloat = 0.22
    let ringRect = iconRect.insetBy(
        dx: iconRect.width * ringInsetRatio,
        dy: iconRect.height * ringInsetRatio
    )
    let ringWidth = max(1.5, iconRect.width * 0.06)

    // Faint full ring (track).
    NSColor.white.withAlphaComponent(0.28).setStroke()
    let track = NSBezierPath(ovalIn: ringRect)
    track.lineWidth = ringWidth
    track.stroke()

    // Bright progress arc — 3/4 of the way around, starting at 12 o'clock, clockwise.
    cg.saveGState()
    cg.setStrokeColor(NSColor.white.cgColor)
    cg.setLineWidth(ringWidth)
    cg.setLineCap(.round)
    let center = CGPoint(x: ringRect.midX, y: ringRect.midY)
    let radius = ringRect.width / 2
    cg.addArc(
        center: center,
        radius: radius,
        startAngle: .pi / 2,
        endAngle: .pi / 2 - .pi * 1.5,
        clockwise: true
    )
    cg.strokePath()
    cg.restoreGState()

    // Center pivot dot.
    let dotRadius = iconRect.width * 0.045
    let dotRect = NSRect(
        x: center.x - dotRadius,
        y: center.y - dotRadius,
        width: dotRadius * 2,
        height: dotRadius * 2
    )
    NSColor.white.setFill()
    NSBezierPath(ovalIn: dotRect).fill()

    NSGraphicsContext.restoreGraphicsState()

    return rep.representation(using: .png, properties: [:])!
}

let fm = FileManager.default
let dirURL = URL(fileURLWithPath: assetsDir)
try fm.createDirectory(at: dirURL, withIntermediateDirectories: true)

for entry in entries {
    let png = drawIcon(pixels: entry.pixels)
    let url = dirURL.appendingPathComponent(entry.filename)
    try png.write(to: url)
    print("wrote \(entry.filename) (\(entry.pixels)px)")
}

let images = entries.map { entry -> [String: Any] in
    [
        "filename": entry.filename,
        "idiom": "mac",
        "scale": entry.scale,
        "size": entry.size,
    ]
}
let contents: [String: Any] = [
    "images": images,
    "info": ["author": "xcode", "version": 1],
]
let contentsURL = dirURL.appendingPathComponent("Contents.json")
let data = try JSONSerialization.data(
    withJSONObject: contents,
    options: [.prettyPrinted, .sortedKeys]
)
try data.write(to: contentsURL)
print("wrote Contents.json")

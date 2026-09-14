#!/usr/bin/env swift
// generate_icon.swift — Generate a multi-layered PocketWalker app icon
// Run on macOS: swift generate_icon.swift

import Foundation
import CoreGraphics
import ImageIO

let size = 1024
let outputPath = "PocketWalker/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"

guard let context = CGContext(
    data: nil,
    width: size,
    height: size,
    bitsPerComponent: 8,
    bytesPerRow: size * 4,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fatalError("Failed to create CGContext")
}

// --- Layer 1: Background gradient (dark green → teal) ---
let gradientColors: [CGColor] = [
    CGColor(red: 0.05, green: 0.15, blue: 0.10, alpha: 1.0),
    CGColor(red: 0.10, green: 0.30, blue: 0.25, alpha: 1.0),
]
let locations: [CGFloat] = [0.0, 1.0]
if let gradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: gradientColors as CFArray,
    locations: locations
) {
    context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: CGFloat(size)), options: [])
}

// --- Layer 2: PokéWalker body (dark circle) ---
let cx: CGFloat = 512, cy: CGFloat = 512, r: CGFloat = 380
context.setFillColor(CGColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0))
context.fillEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))

// --- Layer 3: Screen bezel ---
let sw: CGFloat = 320, sh: CGFloat = 220, sy: CGFloat = 420
context.setFillColor(CGColor(red: 0.25, green: 0.25, blue: 0.25, alpha: 1.0))
context.fill(CGRect(x: cx - sw/2 - 16, y: sy - sh/2 - 16, width: sw + 32, height: sh + 32))

// --- Layer 4: LCD screen (green) ---
context.setFillColor(CGColor(red: 0.75, green: 0.85, blue: 0.60, alpha: 1.0))
context.fill(CGRect(x: cx - sw/2, y: sy - sh/2, width: sw, height: sh))

// --- Layer 5: Pokéball on screen ---
let pr: CGFloat = 60
context.setStrokeColor(CGColor(red: 0.10, green: 0.20, blue: 0.05, alpha: 1.0))
context.setLineWidth(4.0)
context.strokeEllipse(in: CGRect(x: cx - pr, y: sy - pr, width: pr * 2, height: pr * 2))
// Horizontal line
context.move(to: CGPoint(x: cx - pr, y: sy))
context.addLine(to: CGPoint(x: cx + pr, y: sy))
context.strokePath()
// Center dot
context.setFillColor(CGColor(red: 0.10, green: 0.20, blue: 0.05, alpha: 1.0))
context.fillEllipse(in: CGRect(x: cx - 10, y: sy - 10, width: 20, height: 20))

// --- Layer 6: Three buttons ---
let by: CGFloat = 620, br: CGFloat = 40
let buttonColor = CGColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 1.0)
let centerBtnColor = CGColor(red: 0.50, green: 0.50, blue: 0.50, alpha: 1.0)
for (bx, clr) in [(CGFloat(380), buttonColor), (cx, centerBtnColor), (CGFloat(644), buttonColor)] {
    context.setFillColor(clr)
    context.fillEllipse(in: CGRect(x: bx - br, y: by - br, width: br * 2, height: br * 2))
}

// --- Layer 7: Shine highlight ---
context.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.08))
context.fillEllipse(in: CGRect(x: cx - r + 40, y: cy - r + 40, width: r * 1.2, height: r * 0.8))

// --- Layer 8: "PW" pixel text ---
let px: CGFloat = 16
let tx: CGFloat = 460, ty: CGFloat = 780
context.setFillColor(CGColor(red: 0.9, green: 0.95, blue: 0.85, alpha: 1.0))

// P shape (pixel rectangles)
let pRects: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
    (tx, ty, px, px * 5),
    (tx, ty, px * 3, px),
    (tx + px * 2, ty, px, px * 2),
    (tx + px, ty + px * 2, px * 2, px),
]
// W shape
let wx: CGFloat = 540
let wRects: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
    (wx, ty, px, px * 5),
    (wx + px * 3, ty, px, px * 5),
    (wx + px, ty + px * 4, px, px),
    (wx + px * 2, ty + px * 4, px, px),
]
for (x, y, w, h) in pRects + wRects {
    context.fill(CGRect(x: x, y: y, width: w, height: h))
}

// --- Save ---
guard let image = context.makeImage() else { fatalError("Failed to create image") }

let fm = FileManager.default
let outputDir = (outputPath as NSString).deletingLastPathComponent
try? fm.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

guard let dest = CGImageDestinationCreateWithURL(
    URL(fileURLWithPath: outputPath) as CFURL, "public.png" as CFString, 1, nil
) else { fatalError("Failed to create destination") }
CGImageDestinationAddImage(dest, image, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("Failed to write") }

print("✅ App icon generated: \(outputPath) (\(size)x\(size))")

#!/usr/bin/env swift
// generate_icon.swift — Generate a multi-layered PocketWalker app icon
// Run on macOS: swift generate_icon.swift
// Requires: macOS with CoreGraphics/SwiftUI

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let outputPath = "PocketWalker/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"

// Create the icon context
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
let colorSpace = CGColorSpaceCreateDeviceRGB()
let gradientColors: [CGColor] = [
    CGColor(red: 0.05, green: 0.15, blue: 0.10, alpha: 1.0),  // dark forest
    CGColor(red: 0.10, green: 0.30, blue: 0.25, alpha: 1.0),  // teal
]
let locations: [CGFloat] = [0.0, 1.0]
if let gradient = CGGradient(
    colorsSpace: colorSpace,
    colors: gradientColors as CFArray,
    locations: locations
) {
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: 0),
        end: CGPoint(x: 0, y: CGFloat(size)),
        options: []
    )
}

// --- Layer 2: PokéWalker silhouette (circle with screen cutout) ---
// Outer circle (the walker body)
let walkerCenter = CGPoint(x: 512, y: 512)
let walkerRadius: CGFloat = 380

// Draw walker body (dark gray)
context.setFillColor(CGColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0))
context.fillEllipse(in: CGRect(
    x: walkerCenter.x - walkerRadius,
    y: walkerCenter.y - walkerRadius,
    width: walkerRadius * 2,
    height: walkerRadius * 2
))

// --- Layer 3: LCD screen (green-tinted) ---
let screenCenter = CGPoint(x: 512, y: 420)
let screenWidth: CGFloat = 320
let screenHeight: CGFloat = 220

// Screen bezel
let bezelRect = CGRect(
    x: screenCenter.x - screenWidth/2 - 16,
    y: screenCenter.y - screenHeight/2 - 16,
    width: screenWidth + 32,
    height: screenHeight + 32
)
context.setFillColor(CGColor(red: 0.25, green: 0.25, blue: 0.25, alpha: 1.0))
context.fill(roundedRect: bezelRect, cornerWidth: 12, cornerHeight: 12)

// Screen surface (LCD green)
let screenRect = CGRect(
    x: screenCenter.x - screenWidth/2,
    y: screenCenter.y - screenHeight/2,
    width: screenWidth,
    height: screenHeight
)
context.setFillColor(CGColor(red: 0.75, green: 0.85, blue: 0.60, alpha: 1.0))
context.fill(roundedRect: screenRect, cornerWidth: 4, cornerHeight: 4)

// --- Layer 4: Pixel art on screen (simple Pokéball outline) ---
let pokeCenter = CGPoint(x: 512, y: 420)
let pokeRadius: CGFloat = 60

// Pokéball circle
context.setStrokeColor(CGColor(red: 0.10, green: 0.20, blue: 0.05, alpha: 1.0))
context.setLineWidth(4.0)
context.strokeEllipse(in: CGRect(
    x: pokeCenter.x - pokeRadius,
    y: pokeCenter.y - pokeRadius,
    width: pokeRadius * 2,
    height: pokeRadius * 2
))

// Horizontal line
context.move(to: CGPoint(x: pokeCenter.x - pokeRadius, y: pokeCenter.y))
context.addLine(to: CGPoint(x: pokeCenter.x + pokeRadius, y: pokeCenter.y))
context.strokePath()

// Center dot
context.setFillColor(CGColor(red: 0.10, green: 0.20, blue: 0.05, alpha: 1.0))
context.fillEllipse(in: CGRect(
    x: pokeCenter.x - 10,
    y: pokeCenter.y - 10,
    width: 20,
    height: 20
))

// --- Layer 5: Three buttons at bottom ---
let buttonY: CGFloat = 620
let buttonRadius: CGFloat = 40

// Left button
context.setFillColor(CGColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 1.0))
context.fillEllipse(in: CGRect(
    x: 380 - buttonRadius,
    y: buttonY - buttonRadius,
    width: buttonRadius * 2,
    height: buttonRadius * 2
))

// Center button
context.setFillColor(CGColor(red: 0.50, green: 0.50, blue: 0.50, alpha: 1.0))
context.fillEllipse(in: CGRect(
    x: 512 - buttonRadius,
    y: buttonY - buttonRadius,
    width: buttonRadius * 2,
    height: buttonRadius * 2
))

// Right button
context.setFillColor(CGColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 1.0))
context.fillEllipse(in: CGRect(
    x: 644 - buttonRadius,
    y: buttonY - buttonRadius,
    width: buttonRadius * 2,
    height: buttonRadius * 2
))

// --- Layer 6: Highlight/shine effect ---
context.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.08))
context.fillEllipse(in: CGRect(
    x: walkerCenter.x - walkerRadius + 40,
    y: walkerCenter.y - walkerRadius + 40,
    width: walkerRadius * 1.2,
    height: walkerRadius * 0.8
))

// --- Layer 7: "PW" text at top ---
// Simple pixel-style text
let textY: CGFloat = 780
context.setFillColor(CGColor(red: 0.9, green: 0.95, blue: 0.85, alpha: 1.0))
context.setFont(CTFontCreateWithName("Courier-Bold" as CFString, 80, nil))

// Render "PW" as simple rectangles (pixel font)
let pixelSize: CGFloat = 16
let letterSpacing: CGFloat = pixelSize * 6

// P
let pStartX: CGFloat = 460
let pLines: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
    (pStartX, textY, pixelSize, pixelSize * 5),
    (pStartX, textY, pixelSize * 2, pixelSize),
    (pStartX + pixelSize * 2, textY, pixelSize, pixelSize * 2),
    (pStartX + pixelSize, textY + pixelSize * 2, pixelSize * 2, pixelSize),
]

// W
let wStartX: CGFloat = 540
let wLines: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
    (wStartX, textY, pixelSize, pixelSize * 5),
    (wStartX + pixelSize * 3, textY, pixelSize, pixelSize * 5),
    (wStartX + pixelSize, textY + pixelSize * 4, pixelSize, pixelSize),
    (wStartX + pixelSize * 2, textY + pixelSize * 4, pixelSize, pixelSize),
]

context.setFillColor(CGColor(red: 0.9, green: 0.95, blue: 0.85, alpha: 1.0))
for (x, y, w, h) in pLines + wLines {
    context.fill(CGRect(x: x, y: y, width: w, height: h))
}

// --- Save ---
guard let image = context.makeImage() else {
    fatalError("Failed to create image")
}

// Create output directory
let fm = FileManager.default
let outputDir = (outputPath as NSString).deletingLastPathComponent
try? fm.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

// Write PNG
guard let destination = CGImageDestinationCreateWithURL(
    URL(fileURLWithPath: outputPath) as CFURL,
    "public.png" as CFString,
    1,
    nil
) else {
    fatalError("Failed to create image destination")
}
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else {
    fatalError("Failed to write image")
}

print("✅ App icon generated at: \(outputPath)")
print("   Size: \(size)x\(size) PNG")

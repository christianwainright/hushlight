// Packages the table lamp artwork as App Store-ready icons (decision 0055).
// The versioned raster masters and their provenance live in
// docs/design/hushlight/icon/README.md. This exporter resizes and encodes them;
// it does not redraw the lamp or regenerate its appearance variants. The tinted
// export passes through grayscale so the OS receives a neutral luminance map.
//
// swift scripts/make-hushlight-icon.swift <out.png> [--layer flat|dark|tinted|marketing]
// Regenerate all four catalog files together; marketing deliberately uses dark.

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let usage = """
Usage: swift scripts/make-hushlight-icon.swift <out.png> [--layer flat|dark|tinted|marketing]

Exports a 1024x1024 opaque RGB PNG in sRGB from a versioned raster master.
  flat       Light appearance (default): source-light.png
  dark       Dark appearance: source-dark.png
  tinted     Tinted appearance: source-tinted.png
  marketing  App Store artwork: source-dark.png
  --help     Show this help

Masters: docs/design/hushlight/icon/ (resolved relative to this script).
Background/foreground layer exports are unavailable for this raster artwork.
"""

struct ExportError: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) { self.description = description }
}

struct Options {
    let output: URL
    let layer: String

    var sourceName: String {
        switch layer {
        case "flat": "source-light.png"
        case "tinted": "source-tinted.png"
        default: "source-dark.png"
        }
    }
}

func parseOptions() throws -> Options? {
    let arguments = Array(CommandLine.arguments.dropFirst())
    if arguments == ["--help"] || arguments == ["-h"] {
        print(usage)
        return nil
    }
    var output: String?
    var layer: String?
    var index = 0
    while index < arguments.count {
        let argument = arguments[index]
        if argument == "--layer" {
            guard layer == nil else { throw ExportError("Specify --layer only once.") }
            guard index + 1 < arguments.count, !arguments[index + 1].hasPrefix("-") else {
                throw ExportError("--layer requires flat, dark, tinted, or marketing.")
            }
            layer = arguments[index + 1]
            index += 2
        } else if argument.hasPrefix("-") {
            throw ExportError("Unknown option '\(argument)'. Use --help for usage.")
        } else {
            guard output == nil else { throw ExportError("Unexpected argument '\(argument)'; specify one output path.") }
            output = argument
            index += 1
        }
    }
    let selectedLayer = layer ?? "flat"
    if selectedLayer == "background" || selectedLayer == "foreground" {
        throw ExportError("The raster artwork has no separable \(selectedLayer) layer. Export flat, dark, tinted, or marketing; a layered icon requires new source artwork.")
    }
    guard ["flat", "dark", "tinted", "marketing"].contains(selectedLayer) else {
        throw ExportError("Unknown layer '\(selectedLayer)'; choose flat, dark, tinted, or marketing.")
    }
    guard let output, !output.isEmpty else { throw ExportError("Missing output PNG path.\n\n\(usage)") }
    let outputURL = URL(fileURLWithPath: output).standardizedFileURL
    guard outputURL.pathExtension.lowercased() == "png" else {
        throw ExportError("Output must use the .png extension: \(output)")
    }
    return Options(output: outputURL, layer: selectedLayer)
}

func export(_ options: Options) throws {
    let sourceDirectory = URL(fileURLWithPath: #filePath)
        .standardizedFileURL.resolvingSymlinksInPath()
        .deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("docs/design/hushlight/icon", isDirectory: true)
    let sourceURL = sourceDirectory.appendingPathComponent(options.sourceName)
    guard FileManager.default.isReadableFile(atPath: sourceURL.path) else {
        throw ExportError("Missing or unreadable master: \(sourceURL.path). Restore the versioned source artwork before exporting.")
    }
    // Decode before opening the destination, so invalid artwork cannot truncate
    // an existing catalog image. Ignore input metadata when encoding the result.
    guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
          CGImageSourceGetCount(source) == 1,
          let image = CGImageSourceCreateImageAtIndex(source, 0, [kCGImageSourceShouldCacheImmediately: true] as CFDictionary),
          CGImageSourceGetStatusAtIndex(source, 0) == .statusComplete else {
        throw ExportError("Corrupt or unsupported master: \(sourceURL.path). Expected one complete PNG image.")
    }
    guard CGImageSourceGetType(source) as String? == UTType.png.identifier else {
        throw ExportError("Master must be a PNG image: \(sourceURL.path)")
    }
    guard image.width > 0, image.width == image.height else {
        throw ExportError("Master must be square; found \(image.width)x\(image.height): \(sourceURL.path)")
    }
    let masterURLs = ["source-light.png", "source-dark.png", "source-tinted.png"].map {
        sourceDirectory.appendingPathComponent($0).resolvingSymlinksInPath()
    }
    guard !masterURLs.contains(options.output.resolvingSymlinksInPath()) else {
        throw ExportError("Output cannot overwrite a source master: \(options.output.path)")
    }

    let dimension = 1024
    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
          let context = CGContext(
            data: nil, width: dimension, height: dimension,
            bitsPerComponent: 8, bytesPerRow: dimension * 4,
            space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
          ) else { throw ExportError("Could not create the 1024x1024 sRGB export context.") }
    let bounds = CGRect(x: 0, y: 0, width: dimension, height: dimension)
    // Masters are complete compositions. An opaque backing also guarantees a
    // valid output if their PNG container carries an unused alpha channel.
    context.setFillColor(CGColor(gray: options.layer == "flat" ? 1 : 0, alpha: 1))
    context.fill(bounds)
    context.interpolationQuality = .high
    if options.layer == "tinted" {
        // A generated monochrome master can retain a trace of colour. Convert
        // through a calibrated gray space, then encode that luminance in RGB.
        guard let graySpace = CGColorSpace(name: CGColorSpace.genericGrayGamma2_2),
              let grayContext = CGContext(
                data: nil, width: dimension, height: dimension,
                bitsPerComponent: 8, bytesPerRow: dimension,
                space: graySpace, bitmapInfo: CGImageAlphaInfo.none.rawValue
              ) else { throw ExportError("Could not create the tinted luminance context.") }
        grayContext.setFillColor(CGColor(gray: 0, alpha: 1))
        grayContext.fill(bounds)
        grayContext.interpolationQuality = .high
        grayContext.draw(image, in: bounds)
        guard let grayImage = grayContext.makeImage() else {
            throw ExportError("Could not render the tinted luminance map.")
        }
        context.draw(grayImage, in: bounds)
    } else {
        context.draw(image, in: bounds)
    }
    guard let result = context.makeImage() else { throw ExportError("Could not render the icon.") }

    let data = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else {
        throw ExportError("Could not create the PNG encoder.")
    }
    CGImageDestinationAddImage(destination, result, nil)
    guard CGImageDestinationFinalize(destination) else { throw ExportError("Could not encode the PNG.") }
    do {
        try (data as Data).write(to: options.output, options: .atomic)
    } catch {
        throw ExportError("Could not write \(options.output.path): \(error.localizedDescription)")
    }
    print("wrote \(options.output.path) (\(options.layer)) — \(dimension)x\(dimension), opaque sRGB")
}

do {
    if let options = try parseOptions() { try export(options) }
} catch {
    FileHandle.standardError.write(Data("error: \(error)\n".utf8))
    exit(1)
}

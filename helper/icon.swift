// Kuro's app icon: an all-black squircle with a gray UwU face, drawn from vectors at every size.
// usage: swift helper/icon.swift <out-dir> [logo.png]  ( writes <out-dir>/AppIcon.iconset, plus a 512px logo if given a path )
import AppKit

let black = CGColor(gray: 0, alpha: 1)
let gray = CGColor(srgbRed: 0.58, green: 0.58, blue: 0.58, alpha: 1) // #949494, a calm neutral gray

// the face on Apple's 1024 grid: its radius, then the rest in units of that radius ( y up from the center )
typealias Face = (r: CGFloat, eyeX: CGFloat, eyeHalf: CGFloat, eyeTop: CGFloat, eyeBowl: CGFloat, mouth: CGFloat, mouthY: CGFloat, line: CGFloat)
let big: Face = (262, 0.38, 0.15, 0.21, 0.09, 0.10, -0.23, 0.11)
let tiny: Face = (360, 0.444, 0.178, 0.32, 0.17, 0.12, -0.28, 0.19) // 16 and 32 px: bigger face, fatter lines, eyes on whole pixels

// Big Sur's icon body ( 824 of 1024, centered ) as a superellipse, which gives the smooth continuous corners
func squircle(_ half: CGFloat, n: CGFloat = 5) -> CGPath {
    let p = CGMutablePath()
    for i in 0..<360 {
        let t = CGFloat(i) * .pi / 180, c = cos(t), s = sin(t)
        let pt = CGPoint(x: half * copysign(pow(abs(c), 2 / n), c), y: half * copysign(pow(abs(s), 2 / n), s))
        i == 0 ? p.move(to: pt) : p.addLine(to: pt)
    }
    p.closeSubpath()
    return p
}

// the UwU: two U eyes ( down, round the bottom, back up ) and a w mouth ( two little bowls side by side )
func uwu(_ f: Face) -> CGPath {
    let p = CGMutablePath(), r = f.r
    for side: CGFloat in [-1, 1] {
        let x = side * f.eyeX * r, half = f.eyeHalf * r
        p.move(to: CGPoint(x: x - half, y: f.eyeTop * r))
        p.addArc(center: CGPoint(x: x, y: f.eyeBowl * r), radius: half, startAngle: .pi, endAngle: 0, clockwise: false)
        p.addLine(to: CGPoint(x: x + half, y: f.eyeTop * r))
    }
    let m = f.mouth * r, y = f.mouthY * r
    p.move(to: CGPoint(x: -2 * m, y: y))
    p.addArc(center: CGPoint(x: -m, y: y), radius: m, startAngle: .pi, endAngle: 0, clockwise: false)
    p.addArc(center: CGPoint(x: m, y: y), radius: m, startAngle: .pi, endAngle: 0, clockwise: false)
    return p
}

// one s x s pixel PNG, drawn straight from the vectors ( no downscaling, so tiny sizes can get their own face )
func render(_ s: Int) -> Data {
    let ctx = CGContext(data: nil, width: s, height: s, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    let k = CGFloat(s) / 1024, f = s <= 32 ? tiny : big
    ctx.scaleBy(x: k, y: k) // from here on we draw on Apple's 1024 grid
    ctx.translateBy(x: 512, y: 512)

    ctx.saveGState() // the body, with Apple's soft drop shadow ( shadows ignore the scale, hence the k )
    if s > 32 { ctx.setShadow(offset: CGSize(width: 0, height: -10 * k), blur: 20 * k, color: CGColor(gray: 0, alpha: 0.3)) }
    ctx.addPath(squircle(412))
    ctx.setFillColor(black)
    ctx.fillPath()
    ctx.restoreGState()

    ctx.addEllipse(in: CGRect(x: -f.r, y: -f.r, width: 2 * f.r, height: 2 * f.r))
    ctx.setFillColor(gray)
    ctx.fillPath()
    ctx.addPath(uwu(f))
    ctx.setStrokeColor(black)
    ctx.setLineWidth(f.line * f.r)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.strokePath()

    return NSBitmapImageRep(cgImage: ctx.makeImage()!).representation(using: .png, properties: [:])!
}

let args = CommandLine.arguments
guard args.count > 1 else { print("usage: swift helper/icon.swift <out-dir> [logo.png]"); exit(1) }
let iconset = URL(fileURLWithPath: args[1]).appendingPathComponent("AppIcon.iconset")
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for pt in [16, 32, 128, 256, 512] { // Apple's iconset names: icon_16x16.png, icon_16x16@2x.png, ...
    try render(pt).write(to: iconset.appendingPathComponent("icon_\(pt)x\(pt).png"))
    try render(pt * 2).write(to: iconset.appendingPathComponent("icon_\(pt)x\(pt)@2x.png"))
}
if args.count > 2 { try render(512).write(to: URL(fileURLWithPath: args[2])) }
print("wrote \(iconset.path)")

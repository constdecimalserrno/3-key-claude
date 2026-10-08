// 3-key Claude's app icon: a black squircle, a gray UwU face and the pad's three keys under it, drawn from vectors at every size.
// usage: swift helper/icon.swift <out-dir> [logo.png]  ( writes <out-dir>/AppIcon.iconset, plus a 512px logo if given a path )
import AppKit

let black = CGColor(gray: 0, alpha: 1)
let gray = CGColor(srgbRed: 0.58, green: 0.58, blue: 0.58, alpha: 1) // #949494, a calm neutral gray

// everything sits on Apple's 1024 grid, y up from the center
// the face: its radius and height, then the rest in units of that radius ( mouthX is where each bowl of the w sits )
typealias Face = (r: CGFloat, y: CGFloat, eyeX: CGFloat, eyeHalf: CGFloat, eyeTop: CGFloat, eyeBowl: CGFloat, mouthX: CGFloat, mouth: CGFloat, mouthY: CGFloat, line: CGFloat)
// the three keys ( talk, hop, enter ): one key's size, the gap between them, the row's top edge and the corner radius
typealias Keys = (w: CGFloat, h: CGFloat, gap: CGFloat, top: CGFloat, round: CGFloat)
typealias Look = (face: Face, keys: Keys?)

let big: Look = ((224, 72, 0.38, 0.15, 0.21, 0.09, 0.10, 0.10, -0.23, 0.11), (128, 96, 32, -192, 28)) // 4:3 keys, edges on the 64 px grid
let px: CGFloat = 32, rpx: CGFloat = 8.5 // one pixel of the 32 px icon, and its face radius in pixels
let small: Look = ((rpx * px, 2.5 * px, 4 / rpx, 1.5 / rpx, 2 / rpx, 0.5 / rpx, 1.5 / rpx, 1 / rpx, -3 / rpx, 1 / rpx),
                   (4 * px, 3 * px, 2 * px, -8 * px, px)) // 32 px: 1 px lines, the w split in two, every edge on a whole pixel
let tiny: Look = ((360, 0, 0.444, 0.178, 0.32, 0.17, 0.12, 0.12, -0.28, 0.19), nil) // 16 px: just the face, keys that small turn to mush

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
        p.move(to: CGPoint(x: x - half, y: f.y + f.eyeTop * r))
        p.addArc(center: CGPoint(x: x, y: f.y + f.eyeBowl * r), radius: half, startAngle: .pi, endAngle: 0, clockwise: false)
        p.addLine(to: CGPoint(x: x + half, y: f.y + f.eyeTop * r))
    }
    let x = f.mouthX * r, m = f.mouth * r, y = f.y + f.mouthY * r
    p.move(to: CGPoint(x: -x - m, y: y))
    p.addArc(center: CGPoint(x: -x, y: y), radius: m, startAngle: .pi, endAngle: 0, clockwise: false)
    p.addArc(center: CGPoint(x: x, y: y), radius: m, startAngle: .pi, endAngle: 0, clockwise: false)
    return p
}

// one s x s pixel PNG, drawn straight from the vectors ( no downscaling, so tiny sizes can get their own look )
func render(_ s: Int) -> Data {
    let ctx = CGContext(data: nil, width: s, height: s, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    let k = CGFloat(s) / 1024, (f, keys) = s <= 16 ? tiny : s <= 32 ? small : big
    ctx.scaleBy(x: k, y: k) // from here on we draw on Apple's 1024 grid
    ctx.translateBy(x: 512, y: 512)

    ctx.saveGState() // the body, with Apple's soft drop shadow ( shadows ignore the scale, hence the k )
    if s > 32 { ctx.setShadow(offset: CGSize(width: 0, height: -10 * k), blur: 20 * k, color: CGColor(gray: 0, alpha: 0.3)) }
    ctx.addPath(squircle(412))
    ctx.setFillColor(black)
    ctx.fillPath()
    ctx.restoreGState()

    ctx.setFillColor(gray)
    ctx.addEllipse(in: CGRect(x: -f.r, y: f.y - f.r, width: 2 * f.r, height: 2 * f.r))
    if let b = keys { // three equal keycaps, centered under the face
        for i in -1...1 {
            let key = CGRect(x: CGFloat(i) * (b.w + b.gap) - b.w / 2, y: b.top - b.h, width: b.w, height: b.h)
            ctx.addPath(CGPath(roundedRect: key, cornerWidth: b.round, cornerHeight: b.round, transform: nil))
        }
    }
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

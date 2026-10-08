// 3-key Claude's app icon: a black squircle, a gray UwU face and the pad's three keys under it, drawn from vectors at every size.
// usage: swift helper/icon.swift <out-dir> [logo.png]  ( writes <out-dir>/AppIcon.iconset and the .dmg background, plus a 512px logo if given a path )
import AppKit

let black = CGColor(gray: 0, alpha: 1)
let gray = CGColor(srgbRed: 0.58, green: 0.58, blue: 0.58, alpha: 1) // #949494, a calm neutral gray
let skirt = CGColor(srgbRed: 0.37, green: 0.37, blue: 0.37, alpha: 1) // #5E5E5E, the sides and front of each keycap, a shade under the face

// everything sits on Apple's 1024 grid, y up from the center
// the face: its radius and height, then the features from the face's center ( mouthX is where each bowl of the w sits, a bit under its radius so the middle point dips )
typealias Face = (r: CGFloat, y: CGFloat, eyeX: CGFloat, eyeHalf: CGFloat, eyeTop: CGFloat, eyeBowl: CGFloat, mouthX: CGFloat, mouth: CGFloat, mouthY: CGFloat, line: CGFloat)
// the three keys ( talk, hop, confirm ): one key's size, the gap between them, the row's top edge, the corner radius,
// then how much of the keycap's side and front shows around its top ( 0 for a flat key )
typealias Keys = (w: CGFloat, h: CGFloat, gap: CGFloat, top: CGFloat, round: CGFloat, rim: CGFloat, lip: CGFloat)
typealias Look = (face: Face, keys: Keys?)

let big: Look = ((224, 80, 92, 32, 36, 8, 20, 22, -46, 24), (128, 96, 32, -192, 28, 16, 24)) // edges on the 8 grid, so 128 px stays crisp
let px: CGFloat = 32 // one pixel of the 32 px icon
// below 64 px every edge sits on a whole pixel: 1 px lines, and a mouth of 0 means the w is laid down pixel by pixel
let small: Look = ((8.5 * px, 2.5 * px, 4 * px, 1.5 * px, 2 * px, 0.5 * px, 0, 0, -3 * px, px),
                   (4 * px, 3 * px, 2 * px, -8 * px, px, 0, px)) // 32 px: each key keeps a 1 px front
let tiny: Look = ((352, 0, 160, 64, 160, 96, 0, 0, -96, 64), nil) // 16 px: just the face, keys that small turn to mush

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

// the UwU: two U eyes ( down, round the bottom, back up ) and a w mouth ( two little bowls that meet in a soft point )
func uwu(_ f: Face) -> CGPath {
    let p = CGMutablePath()
    for side: CGFloat in [-1, 1] {
        let x = side * f.eyeX, half = f.eyeHalf
        p.move(to: CGPoint(x: x - half, y: f.y + f.eyeTop))
        p.addArc(center: CGPoint(x: x, y: f.y + f.eyeBowl), radius: half, startAngle: .pi, endAngle: 0, clockwise: false)
        p.addLine(to: CGPoint(x: x + half, y: f.y + f.eyeTop))
    }
    guard f.mouth > 0 else { return p }
    let x = f.mouthX, m = f.mouth, y = f.y + f.mouthY, a = acos(min(x / m, 1)) // a: where the bowls cross, 0 if they only touch
    p.move(to: CGPoint(x: -x - m, y: y))
    p.addArc(center: CGPoint(x: -x, y: y), radius: m, startAngle: .pi, endAngle: -a, clockwise: false)
    p.addArc(center: CGPoint(x: x, y: y), radius: m, startAngle: .pi + a, endAngle: 0, clockwise: false)
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
    ctx.addPath(squircle(s > 32 ? 412 : (412 * k).rounded(.up) / k)) // small sizes put its flat sides on whole pixels, for a crisp edge
    ctx.setFillColor(black)
    ctx.fillPath()
    ctx.restoreGState()

    ctx.setFillColor(gray)
    ctx.fillEllipse(in: CGRect(x: -f.r, y: f.y - f.r, width: 2 * f.r, height: 2 * f.r))
    if let b = keys { // three equal keycaps, centered under the face: the cap in the darker gray, its top face in the face's gray
        for i in -1...1 {
            let key = CGRect(x: CGFloat(i) * (b.w + b.gap) - b.w / 2, y: b.top - b.h, width: b.w, height: b.h)
            let cap = CGRect(x: key.minX + b.rim, y: key.minY + b.lip, width: b.w - 2 * b.rim, height: b.h - b.lip - b.rim / 2)
            if b.lip > 0 {
                ctx.setFillColor(skirt)
                ctx.addPath(CGPath(roundedRect: key, cornerWidth: b.round, cornerHeight: b.round, transform: nil))
                ctx.fillPath()
            }
            ctx.setFillColor(gray)
            let round = b.round - b.rim
            ctx.addPath(CGPath(roundedRect: cap, cornerWidth: round, cornerHeight: round, transform: nil))
            ctx.fillPath()
        }
    }
    ctx.addPath(uwu(f))
    ctx.setStrokeColor(black)
    ctx.setLineWidth(f.line)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.strokePath()
    if f.mouth == 0 { // arcs that small blur, so the w goes down as six square pixels: X.XX.X over .X..X.
        ctx.setFillColor(black)
        for (x, y) in [(-3, 0), (-1, 0), (0, 0), (2, 0), (-2, -1), (1, -1)] as [(CGFloat, CGFloat)] {
            ctx.fill(CGRect(x: x * f.line, y: f.y + f.mouthY + (y - 0.5) * f.line, width: f.line, height: f.line))
        }
    }

    return NSBitmapImageRep(cgImage: ctx.makeImage()!).representation(using: .png, properties: [:])!
}

// the .dmg window's background, 640 x 400 points with y down from the top, the way Finder places icons
// true black like the icon, a gray hop from the app to Applications, and the one thing to do
// the app sits at ( 160, 185 ) and Applications at ( 480, 185 ), the same spots install.sh hands Finder
// ponytail: Finder draws its icon labels black over a background picture ( in dark mode too ), so on true black they vanish,
// the face, the folder and the hint line say it all
func background(_ scale: CGFloat) -> Data {
    let size = CGSize(width: 640, height: 400)
    let ctx = CGContext(data: nil, width: Int(size.width * scale), height: Int(size.height * scale), bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.setFillColor(black)
    ctx.fill(CGRect(x: 0, y: 0, width: size.width * scale, height: size.height * scale))
    ctx.translateBy(x: 0, y: size.height * scale)
    ctx.scaleBy(x: scale, y: -scale) // from here on, points with y down

    // the hop: a soft arc over the gap, in the same round strokes as the face, with a little chevron landing on Applications
    let from = CGPoint(x: 238, y: 182), to = CGPoint(x: 402, y: 182), top = CGPoint(x: 320, y: 142)
    ctx.move(to: from)
    ctx.addQuadCurve(to: to, control: top)
    let a = atan2(to.y - top.y, to.x - top.x) // which way it lands
    for turn: CGFloat in [-0.6, 0.6] {
        ctx.move(to: to)
        ctx.addLine(to: CGPoint(x: to.x - 11 * cos(a + turn), y: to.y - 11 * sin(a + turn)))
    }
    ctx.setStrokeColor(skirt)
    ctx.setLineWidth(2.5)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.strokePath()

    // text in SF Pro Rounded, the 3KC window's keycap face, centered on x = 320 with y as its top
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: true)
    func say(_ text: String, _ y: CGFloat, _ pt: CGFloat, _ weight: NSFont.Weight, _ color: CGColor) {
        let plain = NSFont.systemFont(ofSize: pt, weight: weight)
        let font = NSFont(descriptor: plain.fontDescriptor.withDesign(.rounded) ?? plain.fontDescriptor, size: pt) ?? plain
        let line = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: NSColor(cgColor: color)!])
        line.draw(at: CGPoint(x: 320 - line.size().width / 2, y: y))
    }
    say("talk. hop. confirm.", 44, 13, .semibold, skirt)
    say("drag me into Applications - then open me from there", 300, 15, .medium, gray)
    say("blocked the first time? System Settings > Privacy & Security > Open Anyway", 330, 11, .regular, skirt)

    let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
    rep.size = NSSize(width: size.width, height: size.height) // 144 dpi at 2x, so tiffutil can pair the two up for Retina
    return rep.representation(using: .png, properties: [:])!
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
// ponytail: every build draws the .dmg background too, only ./install.sh dmg uses it, but it's a blink and saves a flag
try background(1).write(to: URL(fileURLWithPath: args[1]).appendingPathComponent("background.png"))
try background(2).write(to: URL(fileURLWithPath: args[1]).appendingPathComponent("background@2x.png"))
print("wrote \(iconset.path)")

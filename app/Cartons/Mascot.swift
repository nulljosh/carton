import SwiftUI

/// Tuck, the Cartons mascot: a kraft box with its flaps up and a face. Drawn in a 200 pt space and scaled.
struct Mascot: View {
    var size: CGFloat = 200
    var lively = true  // blinks, waves its flaps and bobs
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let moving = lively && !reduceMotion
        TimelineView(.animation(minimumInterval: 1 / 30, paused: !moving)) { ctx in
            let t = moving ? ctx.date.timeIntervalSinceReferenceDate : 0
            let blink = moving && t.truncatingRemainder(dividingBy: 3.6) < 0.14
            let wave = sin(t * 3.2) * 9
            let bob = -abs(sin(t * 2.4)) * 5
            ZStack {
                Ellipse().fill(.black.opacity(0.12)).frame(width: 118 + bob * 2, height: 12).position(x: 100, y: 193)
                Group {
                    // side flaps hinge just inside the top corners (the body hides the joint) and swing like arms
                    flap.rotationEffect(.degrees(-105 - wave), anchor: .leading).position(x: 74, y: 82)
                    flap.rotationEffect(.degrees(105 + wave), anchor: .trailing).position(x: 126, y: 82)
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(colors: [hex(0xc88f55), hex(0xa66d3a)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 140, height: 120).position(x: 100, y: 130)
                    Capsule().fill(hex(0xf2cf9c).opacity(0.85)).frame(width: 124, height: 4).position(x: 100, y: 73)
                    Rectangle().fill(hex(0xf0d39d).opacity(0.92)).frame(width: 24, height: 30).position(x: 100, y: 85)
                    face(blink: blink)
                    label.rotationEffect(.degrees(-6)).position(x: 145, y: 170)
                }
                .offset(y: bob)
            }
            .frame(width: 200, height: 200)
        }
        .scaleEffect(size / 200)
        .frame(width: size, height: size)
        .accessibilityLabel("Tuck, the Cartons box")
    }

    private var flap: some View {
        RoundedRectangle(cornerRadius: 5)
            .fill(LinearGradient(colors: [hex(0xe8bd86), hex(0xd9a76c)], startPoint: .top, endPoint: .bottom))
            .frame(width: 68, height: 22)
    }

    private func face(blink: Bool) -> some View {
        let ink = hex(0x2b1a0c)
        return ZStack {
            ForEach([80.0, 120.0], id: \.self) { x in
                Ellipse().fill(ink).frame(width: 13, height: blink ? 2 : 17).position(x: x, y: 128)
                if !blink { Circle().fill(.white).frame(width: 4.5, height: 4.5).position(x: x + 3, y: 124) }
                Ellipse().fill(hex(0x8c4a22).opacity(0.28)).frame(width: 16, height: 9).position(x: x < 100 ? 64 : 136, y: 146)
            }
            Path { $0.addArc(center: CGPoint(x: 100, y: 140), radius: 9, startAngle: .degrees(25), endAngle: .degrees(155), clockwise: false) }
                .stroke(ink, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
        }
    }

    private var label: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4).fill(hex(0xfbfaf5)).frame(width: 34, height: 26)
            HStack(spacing: 2) {
                ForEach([3.0, 1.5, 4, 1.5, 2.5, 1.5, 3], id: \.self) { Rectangle().fill(hex(0x2b2b2b)).frame(width: $0, height: 12) }
            }
            .offset(y: 3)
        }
    }

    private func hex(_ v: UInt32) -> Color {
        Color(red: Double(v >> 16 & 0xff) / 255, green: Double(v >> 8 & 0xff) / 255, blue: Double(v & 0xff) / 255)
    }
}

/// Shown for a beat at launch, after the system launch screen.
struct Splash: View {
    @State private var shown = false

    var body: some View {
        VStack(spacing: 16) {
            Mascot(size: 160).scaleEffect(shown ? 1 : 0.6).opacity(shown ? 1 : 0)
            Text("Cartons").font(.carton(.largeTitle, "Bold")).opacity(shown ? 1 : 0).offset(y: shown ? 0 : 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
        .onAppear { withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { shown = true } }
    }
}

/// First-run walkthrough: three animated glyph pages, then Tuck.
struct Onboarding: View {
    var done: () -> Void
    @State private var page = ProcessInfo.processInfo.arguments.firstIndex(of: "-page").map { Int(ProcessInfo.processInfo.arguments[$0 + 1]) ?? 0 } ?? 0  // QA hook: -page 3
    @State private var forward = true

    private let pages: [(String, LocalizedStringKey, LocalizedStringKey)] = [
        ("doc.on.clipboard", "Copy a tracking number", "Cartons sees a UPS number on your clipboard and fills it in for you."),
        ("box.truck.fill", "Watch it move", "Every scan from label to doorstep, in one tidy list."),
        ("calendar.badge.clock", "Know the day", "A big countdown to delivery day. No account, no ads, nothing to sign up for."),
    ]
    private var last: Bool { page == pages.count }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                if !last { Button("Skip", action: done).font(.carton(.body, "Medium")).keyboardShortcut(.cancelAction) }
            }
            .frame(height: 44)
            Spacer()
            Group {
                if last {
                    card(title: "Meet Tuck", body: "Tuck keeps an eye on your boxes so you don't have to.") { Mascot(size: 200) }
                } else {
                    let p = pages[page]
                    card(title: p.1, body: p.2) { Glyph(name: p.0) }
                }
            }
            .id(page)
            .transition(.asymmetric(insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
                                    removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity)))
            Spacer()
            HStack(spacing: 8) {
                ForEach(0...pages.count, id: \.self) { i in
                    Capsule().fill(i == page ? Brand.accent : Color.secondary.opacity(0.3)).frame(width: i == page ? 20 : 8, height: 8)
                }
            }
            .padding(.bottom, 24)
            .accessibilityElement()
            .accessibilityLabel("Page \(page + 1) of \(pages.count + 1)")
            Button { last ? done() : go(1) } label: {
                Text(last ? "Start tracking" : "Next").font(.carton(.headline, "Semibold")).foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 48).background(Capsule().fill(Brand.accent)).contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .frame(maxWidth: 440)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 30).onEnded { v in
            if v.translation.width < -50, !last { go(1) } else if v.translation.width > 50, page > 0 { go(-1) }
        })
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: page)
    }

    private func go(_ step: Int) {
        forward = step > 0
        page += step
    }

    private func card(title: LocalizedStringKey, body: LocalizedStringKey, @ViewBuilder art: () -> some View) -> some View {
        VStack(spacing: 32) {
            art().frame(height: 220)
            VStack(spacing: 12) {
                Text(title).font(.carton(.title, "Bold"))
                Text(body).font(.carton(.body)).foregroundStyle(.secondary).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// A big accent glyph that bounces every couple of seconds inside a pulsing ring.
private struct Glyph: View {
    let name: String
    @State private var ring = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle().stroke(Brand.accent.opacity(ring ? 0 : 0.35), lineWidth: 2).frame(width: 180, height: 180).scaleEffect(ring ? 1.25 : 1)
            Circle().fill(Brand.accent.opacity(0.12)).frame(width: 180, height: 180)
            TimelineView(.periodic(from: .now, by: 1.8)) { ctx in
                Image(systemName: name).font(.system(size: 76, weight: .semibold)).foregroundStyle(Brand.accent)
                    .symbolEffect(.bounce, value: reduceMotion ? .distantPast : ctx.date)
            }
        }
        .accessibilityHidden(true)
        .onAppear { if !reduceMotion { withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) { ring = true } } }
    }
}

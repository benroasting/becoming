//
//  JourneyStrip.swift
//  Becoming
//
//  Two tracks on one horizontal timeline: the trail (running total, climbing and
//  dipping) above, and a heat strip with one cell per day below. Hairlines tie each
//  moment to the trail point it created. Scrolls sideways; it opens with only a few
//  days of history in view so most of the width is the road ahead.
//

import SwiftUI

struct JourneyStrip: View {
    let days: [JourneyDay]
    let milestone: Int

    // Layout
    private let dayWidth: CGFloat = 22
    private let sidePadding: CGFloat = 24
    /// Days of history visible when the strip first opens.
    private let openingHistoryDays = 3
    private let minimumFutureDays = 8
    private let topPadding: CGFloat = 40
    private let trackHeight: CGFloat = 130
    private let gap: CGFloat = 34
    private let cellHeight: CGFloat = 26
    private let axisHeight: CGFloat = 34

    @State private var position = ScrollPosition(edge: .leading)

    private var height: CGFloat { topPadding + trackHeight + gap + cellHeight + axisHeight }

    /// Enough days ahead of today to fill the viewport after the opening history.
    private func futureDays(viewportWidth: CGFloat) -> Int {
        let visibleDays = Int((viewportWidth / dayWidth).rounded(.down))
        return max(minimumFutureDays, visibleDays - openingHistoryDays)
    }

    /// Scroll offset that leaves `openingHistoryDays` of history before today.
    private var openingOffset: CGFloat {
        let firstVisible = max(0, days.count - 1 - openingHistoryDays)
        return firstVisible == 0 ? 0 : sidePadding + CGFloat(firstVisible) * dayWidth - 6
    }

    var body: some View {
        GeometryReader { proxy in
            let future = futureDays(viewportWidth: proxy.size.width)
            let width = sidePadding * 2 + CGFloat(days.count + future) * dayWidth
            ScrollView(.horizontal, showsIndicators: false) {
                Canvas { context, _ in draw(&context, futureDays: future) }
                    .frame(width: width, height: height)
            }
            .scrollPosition($position)
            .onAppear { position.scrollTo(x: openingOffset) }
        }
        .frame(height: height)
        .accessibilityElement()
        .accessibilityLabel("Journey timeline")
        .accessibilityValue("Net \(days.last?.total ?? 0) over \(days.count) days")
    }

    // MARK: Geometry

    private func x(_ index: Int) -> CGFloat {
        sidePadding + (CGFloat(index) + 0.5) * dayWidth
    }

    private var scale: (lo: Int, unit: CGFloat) {
        let totals = days.map(\.total)
        let lo = min(0, totals.min() ?? 0)
        let hi = max(milestone, totals.max() ?? 0)
        return (lo, min(trackHeight / CGFloat(max(hi - lo, 1)), 30))
    }

    private func y(_ total: Int) -> CGFloat {
        let s = scale
        return topPadding + trackHeight - CGFloat(total - s.lo) * s.unit
    }

    private var heatTop: CGFloat { topPadding + trackHeight + gap }

    // MARK: Drawing

    private func draw(_ context: inout GraphicsContext, futureDays: Int) {
        guard let last = days.last else { return }
        let todayIndex = days.count - 1
        let accent = Theme.accent

        // Trail: S-curves between consecutive days so steps read as terrain.
        var trail = Path()
        trail.move(to: CGPoint(x: x(0), y: y(days[0].total)))
        for i in 1..<max(days.count, 1) {
            let a = CGPoint(x: x(i - 1), y: y(days[i - 1].total))
            let b = CGPoint(x: x(i), y: y(days[i].total))
            let midX = (a.x + b.x) / 2
            trail.addCurve(to: b, control1: CGPoint(x: midX, y: a.y), control2: CGPoint(x: midX, y: b.y))
        }
        context.stroke(trail, with: .color(accent.opacity(0.16)),
                       style: StrokeStyle(lineWidth: 16, lineCap: .round, lineJoin: .round))
        context.stroke(trail, with: .color(accent),
                       style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))

        // Road ahead: dashed climb toward the next milestone, with a flag.
        let here = CGPoint(x: x(todayIndex), y: y(last.total))
        let flagX = x(todayIndex + futureDays - 1)
        let flagY = y(milestone)
        var ahead = Path()
        ahead.move(to: here)
        let midX = (here.x + flagX) / 2
        ahead.addCurve(to: CGPoint(x: flagX, y: flagY),
                       control1: CGPoint(x: midX, y: here.y), control2: CGPoint(x: midX, y: flagY))
        context.stroke(ahead, with: .color(.secondary.opacity(0.5)),
                       style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [1, 8]))

        var pole = Path()
        pole.move(to: CGPoint(x: flagX, y: flagY))
        pole.addLine(to: CGPoint(x: flagX, y: flagY - 30))
        context.stroke(pole, with: .color(.secondary), lineWidth: 2)
        var flag = Path()
        flag.move(to: CGPoint(x: flagX, y: flagY - 30))
        flag.addLine(to: CGPoint(x: flagX + 20, y: flagY - 23))
        flag.addLine(to: CGPoint(x: flagX, y: flagY - 16))
        flag.closeSubpath()
        context.fill(flag, with: .color(accent))
        context.draw(Text("Next: +\(milestone)").font(.caption2).foregroundStyle(.secondary),
                     at: CGPoint(x: flagX - 6, y: flagY + 14), anchor: .trailing)

        // Marked days: hairline down to the heat cell, and a dot on the trail.
        for (i, day) in days.enumerated() {
            guard let impact = day.impact else { continue }
            var line = Path()
            line.move(to: CGPoint(x: x(i), y: y(day.total) + 8))
            line.addLine(to: CGPoint(x: x(i), y: heatTop - 2))
            context.stroke(line, with: .color(impact.color.opacity(0.35)),
                           style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
            let dot = CGRect(x: x(i) - 6, y: y(day.total) - 6, width: 12, height: 12)
            context.fill(Path(ellipseIn: dot.insetBy(dx: -2, dy: -2)), with: .color(Theme.card))
            context.fill(Path(ellipseIn: dot), with: .color(impact.color))
        }

        // You are here.
        context.fill(Path(ellipseIn: CGRect(x: here.x - 15, y: here.y - 15, width: 30, height: 30)),
                     with: .color(accent.opacity(0.16)))
        let ring = CGRect(x: here.x - 8, y: here.y - 8, width: 16, height: 16)
        context.fill(Path(ellipseIn: ring), with: .color(Theme.card))
        context.stroke(Path(ellipseIn: ring.insetBy(dx: 1.75, dy: 1.75)), with: .color(accent), lineWidth: 3.5)
        context.draw(Text("You · \(signed(last.total))").font(.caption.weight(.bold)).foregroundStyle(accent),
                     at: CGPoint(x: here.x, y: here.y - 28), anchor: .center)

        // Heat strip: one cell per day.
        for (i, day) in days.enumerated() {
            let rect = CGRect(x: x(i) - (dayWidth - 4) / 2, y: heatTop, width: dayWidth - 4, height: cellHeight)
            let fill: Color = day.impact?.color ?? Color.secondary.opacity(0.14)
            context.fill(Path(roundedRect: rect, cornerRadius: 6), with: .color(fill))
        }
        for f in 1...futureDays {
            let rect = CGRect(x: x(todayIndex + f) - (dayWidth - 4) / 2, y: heatTop, width: dayWidth - 4, height: cellHeight)
            context.fill(Path(roundedRect: rect, cornerRadius: 6), with: .color(Color.secondary.opacity(0.06)))
        }
        let todayRect = CGRect(x: x(todayIndex) - (dayWidth - 4) / 2 - 2, y: heatTop - 2,
                               width: dayWidth, height: cellHeight + 4)
        context.stroke(Path(roundedRect: todayRect, cornerRadius: 8), with: .color(.primary), lineWidth: 1.5)

        // Axis: a date every week, then TODAY.
        let axisY = heatTop + cellHeight + 14
        for i in stride(from: todayIndex, through: 0, by: -7) where i != todayIndex {
            if todayIndex - i < 4 { continue }
            context.draw(
                Text(days[i].date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.system(size: 10)).foregroundStyle(.secondary),
                at: CGPoint(x: x(i), y: axisY), anchor: .center)
        }
        context.draw(Text("TODAY").font(.system(size: 10, weight: .bold)).foregroundStyle(.primary),
                     at: CGPoint(x: x(todayIndex), y: axisY), anchor: .center)
    }

    private func signed(_ n: Int) -> String {
        n > 0 ? "+\(n)" : n < 0 ? "−\(abs(n))" : "0"
    }
}

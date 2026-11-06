//
//  ValueJourney.swift
//  Becoming
//
//  Pure computation of a value's "journey": the running total of Growth (+1) /
//  Neutral (0) / Setback (-1) tags across journal entries, laid out day by day.
//

import Foundation

nonisolated struct JourneyDay: Identifiable, Hashable {
    var id: Date { date }
    /// Start of the calendar day.
    let date: Date
    /// Cumulative total at the end of this day (carried forward through quiet days).
    let total: Int
    /// The day's overall impact, or nil if nothing was tagged. Several moments on one
    /// day are netted: positive = growth, negative = setback, zero = neutral.
    let impact: Impact?
}

nonisolated struct JourneyMoment: Identifiable, Hashable {
    let id: String
    let date: Date
    let content: String
    let impact: Impact
}

nonisolated struct ValueJourney {
    /// Every calendar day from the start of the journey (the value's creation, or its
    /// earliest tagged entry if that is older) through today, oldest first.
    let days: [JourneyDay]
    /// Tagged entries, newest first.
    let moments: [JourneyMoment]

    var net: Int { moments.reduce(0) { $0 + $1.impact.rawValue } }
    var growthCount: Int { moments.filter { $0.impact == .growth }.count }
    var neutralCount: Int { moments.filter { $0.impact == .neutral }.count }
    var setbackCount: Int { moments.filter { $0.impact == .setback }.count }
    var isEmpty: Bool { moments.isEmpty }

    /// The next multiple of 5 above the current net (never below +5).
    var nextMilestone: Int { (max(net, 0) / 5 + 1) * 5 }

    init(value: Value, entries: [JournalEntry], now: Date = .now, calendar: Calendar = .current) {
        var tagged: [JourneyMoment] = []
        for entry in entries {
            for tag in entry.valueTags ?? [] where tag.valueID == value.id {
                guard let impact = Impact(rawValue: tag.impact) else { continue }
                tagged.append(JourneyMoment(
                    id: "\(entry.id)-\(tag.valueID)-\(tagged.count)",
                    date: entry.createdAt,
                    content: entry.content,
                    impact: impact
                ))
            }
        }

        let ascending = tagged.sorted { $0.date < $1.date }
        let today = calendar.startOfDay(for: now)
        let earliest = min(value.createdAt, ascending.first?.date ?? value.createdAt)
        let firstDay = min(calendar.startOfDay(for: earliest), today)

        var deltaByDay: [Date: Int] = [:]
        for moment in ascending {
            deltaByDay[calendar.startOfDay(for: moment.date), default: 0] += moment.impact.rawValue
        }

        var days: [JourneyDay] = []
        var running = 0
        var day = firstDay
        while day <= today {
            let delta = deltaByDay[day]
            if let delta { running += delta }
            let impact: Impact? = delta.map { $0 > 0 ? .growth : $0 < 0 ? .setback : .neutral }
            days.append(JourneyDay(date: day, total: running, impact: impact))
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }

        self.days = days
        self.moments = ascending.reversed()
    }
}

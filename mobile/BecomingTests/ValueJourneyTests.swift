//
//  ValueJourneyTests.swift
//  BecomingTests
//

import Foundation
import Testing
@testable import Becoming

struct ValueJourneyTests {
    private var cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()
    private let t0 = Date(timeIntervalSince1970: 1_000_000)
    private func day(_ n: Int) -> Date { t0.addingTimeInterval(Double(n) * 86_400) }

    private func value(id: String = "v1") -> Value {
        Value(id: id, title: "Faith", description: "", status: .active, createdAt: t0, updatedAt: t0)
    }

    private func entry(_ id: String, day n: Int, tags: [(String, Int)]?) -> JournalEntry {
        JournalEntry(
            id: id, content: "entry \(id)",
            valueTags: tags?.map { JournalValueTag(valueID: $0.0, impact: $0.1) },
            createdAt: day(n), updatedAt: day(n)
        )
    }

    private func journey(_ entries: [JournalEntry], now: Int = 10) -> ValueJourney {
        ValueJourney(value: value(), entries: entries, now: day(now), calendar: cal)
    }

    private func total(_ j: ValueJourney, on n: Int) -> Int? {
        j.days.first { $0.date == cal.startOfDay(for: day(n)) }?.total
    }

    @Test func accumulatesChronologicallyRegardlessOfInputOrder() {
        let j = journey([
            entry("c", day: 3, tags: [("v1", -1)]),
            entry("a", day: 1, tags: [("v1", 1)]),
            entry("b", day: 2, tags: [("v1", 1)]),
        ])
        #expect([1, 2, 3, 10].map { total(j, on: $0) } == [1, 2, 1, 1])
        #expect(j.net == 1)
        #expect(j.growthCount == 2)
        #expect(j.setbackCount == 1)
    }

    @Test func coversEveryDayFromCreationThroughToday() {
        let j = journey([entry("a", day: 1, tags: [("v1", 1)])])
        // Value created on day 0, now is day 10: no padding before creation.
        #expect(j.days.count == 11)
        #expect(j.days.first?.date == cal.startOfDay(for: day(0)))
        #expect(j.days.last?.date == cal.startOfDay(for: day(10)))
        // Consecutive days, no gaps.
        for pair in zip(j.days, j.days.dropFirst()) {
            #expect(cal.dateComponents([.day], from: pair.0.date, to: pair.1.date).day == 1)
        }
    }

    @Test func longJourneyExtendsBackToFirstEntry() {
        let j = journey([entry("a", day: 0, tags: [("v1", 1)])], now: 60)
        #expect(j.days.count == 61)
    }

    @Test func momentsOnTheSameDayAreNetted() {
        let both = journey([entry("a", day: 2, tags: [("v1", 1)]), entry("b", day: 2, tags: [("v1", -1)])])
        #expect(both.days.first { $0.date == cal.startOfDay(for: day(2)) }?.impact == .neutral)
        #expect(total(both, on: 2) == 0)

        let twice = journey([entry("a", day: 2, tags: [("v1", 1)]), entry("b", day: 2, tags: [("v1", 1)])])
        #expect(twice.days.first { $0.date == cal.startOfDay(for: day(2)) }?.impact == .growth)
        #expect(total(twice, on: 2) == 2)
    }

    @Test func quietDaysCarryTotalForwardWithNoImpact() {
        let j = journey([entry("a", day: 1, tags: [("v1", 1)])])
        let quiet = j.days.first { $0.date == cal.startOfDay(for: day(5)) }
        #expect(quiet?.impact == nil)
        #expect(quiet?.total == 1)
    }

    @Test func ignoresEntriesTaggedToOtherValuesOrUntagged() {
        let j = journey([
            entry("a", day: 1, tags: [("other", 1)]),
            entry("b", day: 2, tags: nil),
            entry("c", day: 3, tags: [("v1", 0)]),
        ])
        #expect(j.moments.count == 1)
        #expect(j.net == 0)
        #expect(j.neutralCount == 1)
    }

    @Test func emptyWhenNothingTagged() {
        let j = journey([])
        #expect(j.isEmpty)
        #expect(j.net == 0)
    }

    @Test func momentsAreNewestFirst() {
        let j = journey([entry("a", day: 1, tags: [("v1", 1)]), entry("b", day: 5, tags: [("v1", -1)])])
        #expect(j.moments.map(\.content) == ["entry b", "entry a"])
    }

    @Test func skipsOutOfRangeImpact() {
        #expect(journey([entry("a", day: 1, tags: [("v1", 7)])]).isEmpty)
    }

    @Test func nextMilestoneIsNextMultipleOfFive() {
        func net(_ n: Int) -> Int {
            let tags = (0..<abs(n)).map { entry("e\($0)", day: $0 % 9, tags: [("v1", n > 0 ? 1 : -1)]) }
            return journey(tags).nextMilestone
        }
        #expect(net(4) == 5)
        #expect(net(5) == 10)
        #expect(net(0) == 5)
        #expect(net(-2) == 5)
    }
}

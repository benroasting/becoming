//
//  ValueDetailView.swift
//  Becoming
//

import SwiftUI

struct ValueDetailView: View {
    @State private var viewModel: ValueJourneyViewModel

    init(value: Value, journalService: any JournalServicing) {
        _viewModel = State(initialValue: ValueJourneyViewModel(value: value, service: journalService))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !viewModel.value.description.isEmpty {
                    Text(viewModel.value.description)
                        .font(Theme.serif(.body, weight: .regular))
                        .foregroundStyle(.secondary)
                }
                content
            }
            .padding(16)
        }
        .screenBackground()
        .navigationTitle(viewModel.value.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity).padding(.top, 40)
        case .failed(let message):
            ContentUnavailableView {
                Label("Couldn't load journey", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Retry") { Task { await viewModel.load() } }
            }
        case .loaded:
            if let journey = viewModel.journey {
                if journey.isEmpty {
                    emptyState
                } else {
                    stats(journey)
                    card {
                        VStack(alignment: .leading, spacing: 12) {
                            sectionLabel("Your journey")
                            JourneyStrip(days: journey.days, milestone: journey.nextMilestone)
                            legend
                        }
                    }
                    moments(journey)
                }
            }
        }
    }

    private var emptyState: some View {
        card {
            VStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.largeTitle).foregroundStyle(.secondary)
                Text("No journey yet").font(Theme.serif(.headline))
                Text("Tag this value in a journal entry as Growth, Neutral or Setback, and your progress will start to take shape here.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var legend: some View {
        HStack(spacing: 16) {
            ForEach(Impact.allCases.reversed()) { impact in
                Label(impact.label, systemImage: "circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .labelStyle(LegendLabelStyle(color: impact.color))
            }
        }
    }

    private func stats(_ journey: ValueJourney) -> some View {
        HStack(spacing: 12) {
            statTile(title: "Net", value: signed(journey.net), emphasized: true)
            statTile(title: "Growth", value: "\(journey.growthCount)", tint: Impact.growth.color)
            statTile(title: "Setbacks", value: "\(journey.setbackCount)", tint: Impact.setback.color)
        }
    }

    private func statTile(title: String, value: String, tint: Color = .primary, emphasized: Bool = false) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Theme.serif(.title, weight: .bold))
                .foregroundStyle(emphasized ? Theme.accent : tint)
            Text(title.uppercased())
                .font(.caption2.weight(.semibold)).tracking(0.8)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
    }

    private func moments(_ journey: ValueJourney) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Moments")
            ForEach(journey.moments) { moment in
                card {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Label(moment.impact.label, systemImage: moment.impact.symbol)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(moment.impact.color)
                            Spacer()
                            Text(moment.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Text(moment.content)
                            .font(Theme.serif(.subheadline, weight: .regular))
                            .lineLimit(4)
                    }
                }
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold)).tracking(0.8)
            .foregroundStyle(.secondary)
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
    }

    private func signed(_ n: Int) -> String {
        n > 0 ? "+\(n)" : n < 0 ? "−\(abs(n))" : "0"
    }
}

private struct LegendLabelStyle: LabelStyle {
    let color: Color
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            configuration.title
        }
    }
}

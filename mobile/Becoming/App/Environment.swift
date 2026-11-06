//
//  Environment.swift
//  Becoming
//

import SwiftUI

private struct ValueServiceKey: EnvironmentKey {
    static let defaultValue: any ValueServicing = APIClient(baseURL: AppConfiguration.apiBaseURL)
}

extension EnvironmentValues {
    var valueService: any ValueServicing {
        get { self[ValueServiceKey.self] }
        set { self[ValueServiceKey.self] = newValue }
    }
}

private struct HabitServiceKey: EnvironmentKey {
    static let defaultValue: any HabitServicing = APIClient(baseURL: AppConfiguration.apiBaseURL)
}

private struct CheckInServiceKey: EnvironmentKey {
    static let defaultValue: any CheckInServicing = APIClient(baseURL: AppConfiguration.apiBaseURL)
}

extension EnvironmentValues {
    var habitService: any HabitServicing {
        get { self[HabitServiceKey.self] }
        set { self[HabitServiceKey.self] = newValue }
    }
    var checkInService: any CheckInServicing {
        get { self[CheckInServiceKey.self] }
        set { self[CheckInServiceKey.self] = newValue }
    }
}

private struct GoalServiceKey: EnvironmentKey {
    static let defaultValue: any GoalServicing = APIClient(baseURL: AppConfiguration.apiBaseURL)
}

extension EnvironmentValues {
    var goalService: any GoalServicing {
        get { self[GoalServiceKey.self] }
        set { self[GoalServiceKey.self] = newValue }
    }
}

private struct JournalServiceKey: EnvironmentKey {
    static let defaultValue: any JournalServicing = APIClient(baseURL: AppConfiguration.apiBaseURL)
}

extension EnvironmentValues {
    var journalService: any JournalServicing {
        get { self[JournalServiceKey.self] }
        set { self[JournalServiceKey.self] = newValue }
    }
}

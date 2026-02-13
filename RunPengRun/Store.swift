import Foundation
import Combine
import UserNotifications

final class LocalStore: ObservableObject {
    @Published private(set) var state: AppState
    
    let newPRSubject = PassthroughSubject<(String, Double), Never>()

    private let fileURL: URL
    private var cancellables = Set<AnyCancellable>()

    init() {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = directory.appendingPathComponent("runpengrun_state.json")

        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode(AppState.self, from: data) {
            state = decoded
            migrateLegacyWarmups() // Add this migration call
        } else {
            state = AppState(
                profile: nil,
                progress: ProgressState(totalSessions: 0, level: 0, lastSessionDate: nil, missedExercises: []),
                sessions: [],
                machineLoads: [:],
                machineReps: [:],
                machinePreferences: [:]
            )
        }

        $state
            .dropFirst()
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .sink { [weak self] newState in
                self?.persist(newState)
            }
            .store(in: &cancellables)
    }

    private func migrateLegacyWarmups() {
        for index in state.sessions.indices {
            if (state.sessions[index].warmupExercises == nil || state.sessions[index].warmupExercises!.isEmpty),
               let legacyWarmups = state.sessions[index].warmup, !legacyWarmups.isEmpty {
                
                let exercises = legacyWarmups.map { name in
                    WorkoutExercise(
                        id: UUID(),
                        name: name,
                        machine: name,
                        sets: 1,
                        reps: 10,
                        restSeconds: 0,
                        tempo: "Normal",
                        targetRPE: 3.0,
                        recommendedLoadKg: 0,
                        notes: "从历史记录迁移的热身项"
                    )
                }
                
                state.sessions[index].warmupExercises = exercises
                state.sessions[index].warmup = nil
            }
        }
    }
    
    func updateProfile(_ profile: UserProfile) {
        state.profile = profile
        NotificationManager.shared.scheduleNotifications(profile: profile)
    }

    func saveSession(_ session: WorkoutSession) {
        if let index = state.sessions.firstIndex(where: { $0.id == session.id }) {
            state.sessions[index] = session
        } else {
            state.sessions.append(session)
        }
    }

    func markSessionCompleted(on date: Date, rpeFeedback: Double? = nil) {
        // This function is now used to finalize stats or just trigger auto-regulation logic
        // Since 'completed' is computed, we don't set it manually anymore.
        // We just run the progression logic based on the session's current state.
        
        guard let session = state.sessions.session(on: date) else { return }
        
        // Recalculate total sessions based on actual completion status
        // This ensures the count decreases if a session becomes incomplete
        // Use 'started' instead of 'completed' so partial workouts count as a session
        state.progress.totalSessions = state.sessions.filter { $0.started }.count
        state.progress.level = max(state.progress.level, state.progress.totalSessions / 4)
        state.progress.lastSessionDate = date
        
        // Check for incomplete exercises to carry over
        var missed: [String] = []
        for exercise in session.exercises {
            if exercise.completedSets == 0 {
                missed.append(exercise.machine)
            }
        }
        state.progress.missedExercises = missed
        
        guard let profile = state.profile else { return }
































        let deload = Planner.isDeloadWeek(for: profile, referenceDate: date)
        
        for exercise in session.exercises {
            let group = MachineCatalog.info(for: exercise.machine)?.group ?? .chest
            
            // Only progress weight if user did at least one set
            if exercise.completedSets > 0 {
                let currentPR = state.progress.personalRecords[exercise.machine] ?? 0
                if exercise.recommendedLoadKg > currentPR {
                    state.progress.personalRecords[exercise.machine] = exercise.recommendedLoadKg
                    newPRSubject.send((exercise.name, exercise.recommendedLoadKg))
                }
                
                var nextLoad = Planner.progressedLoad(current: exercise.recommendedLoadKg, goal: profile.goal, isDeload: deload, group: group)
                
                if let feedback = rpeFeedback, feedback < 6.0 {
                    let increment = Planner.progressedLoad(current: 0, goal: profile.goal, isDeload: false, group: group)
                    nextLoad += increment
                }
                
                state.machineLoads[exercise.machine] = nextLoad
            }
            // Always remember reps
            state.machineReps[exercise.machine] = exercise.reps
        }
    }

    func updateExercise(on date: Date, exerciseId: UUID, update: (inout WorkoutExercise) -> Void) {
        guard var session = state.sessions.session(on: date) else { return }
        
        if let index = session.exercises.firstIndex(where: { $0.id == exerciseId }) {
            update(&session.exercises[index])
        } else if var warmups = session.warmupExercises, let index = warmups.firstIndex(where: { $0.id == exerciseId }) {
            update(&warmups[index])
            session.warmupExercises = warmups
        } else {
            return
        }
        saveSession(session)
    }

    func setMachineLoad(machineId: String, load: Double) {
        state.machineLoads[machineId] = load
    }

    func setMachineReps(machineId: String, reps: Int) {
        state.machineReps[machineId] = reps
    }

    func setMachinePreference(for group: String, machineId: String) {
        state.machinePreferences[group] = machineId
    }

    func setScheduleOverride(for dateStr: String, isTraining: Bool) {
        state.scheduleOverrides[dateStr] = isTraining
    }
    
    func resetAllData() {
        state = AppState(
            profile: nil,
            progress: ProgressState(totalSessions: 0, level: 0, lastSessionDate: nil, missedExercises: []),
            sessions: [],
            machineLoads: [:],
            machineReps: [:],
            machinePreferences: [:]
        )
    }

    func exportState() -> URL? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let filename = "runpengrun_backup_\(formatter.string(from: Date())).json"
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let exportURL = directory.appendingPathComponent(filename)
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: exportURL, options: .atomic)
            return exportURL
        } catch {
            return nil
        }
    }

    func importState(from url: URL) -> Bool {
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(AppState.self, from: data)
            state = decoded
            persist(decoded)
            return true
        } catch {
            return false
        }
    }

    private func persist(_ newState: AppState) {
        do {
            let data = try JSONEncoder().encode(newState)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Intentionally ignore write errors to keep UI responsive.
        }
    }
}

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleNotifications(profile: UserProfile?) {
        guard let profile = profile else { return }
        
        let center = UNUserNotificationCenter.current()
        
        // Cancel all existing notifications to avoid duplicates or outdated plans
        center.removeAllPendingNotificationRequests()
        
        let calendar = Calendar.current
        let today = Date()
        
        // Schedule for the next 30 days
        for dayOffset in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            
            // Check if it's a training day
            if Planner.shouldTrain(on: date, trainingDays: profile.trainingDays, overrides: [:]) {
                scheduleNotification(for: date, center: center)
            }
        }
    }
    
    private func scheduleNotification(for date: Date, center: UNUserNotificationCenter) {
        let content = UNMutableNotificationContent()
        content.title = "今日训练提醒"
        content.body = QuoteLibrary.quote(for: date)
        content.sound = .default
        
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
        dateComponents.hour = 8
        dateComponents.minute = 0
        dateComponents.second = 0
        
        // If the time has already passed for today, don't schedule (or it will trigger immediately/fail depending on OS version, usually just won't fire)
        // Actually for UNCalendarNotificationTrigger, if the date is in the past, it won't fire.
        // But if we use specific year-month-day-hour, it targets that specific point.
        // Let's ensure we don't schedule for 8am today if it's already 9am.
        if let triggerDate = Calendar.current.date(from: dateComponents), triggerDate < Date() {
            return
        }
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "workout_reminder_\(dateComponents.year!)_\(dateComponents.month!)_\(dateComponents.day!)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
}

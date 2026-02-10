import Foundation

struct Planner {
    static let machineLibrary: [WorkoutExerciseTemplate] = [
        .init(name: "坐姿胸推", machine: "Chest Press", primary: .chest),
        .init(name: "蝴蝶机夹胸", machine: "Pec Deck", primary: .chest),
        .init(name: "上斜胸推", machine: "Incline Chest Press", primary: .chest),
        .init(name: "绳索夹胸", machine: "Cable Fly", primary: .chest),
        .init(name: "高位下拉", machine: "Lat Pulldown", primary: .back),
        .init(name: "坐姿划船", machine: "Seated Row", primary: .back),
        .init(name: "坐姿高位划船", machine: "High Row", primary: .back),
        .init(name: "反向飞鸟机", machine: "Rear Delt Fly", primary: .back),
        .init(name: "坐姿肩推", machine: "Shoulder Press", primary: .shoulders),
        .init(name: "侧平举机", machine: "Lateral Raise", primary: .shoulders),
        .init(name: "反向肩推", machine: "Reverse Shoulder Press", primary: .shoulders),
        .init(name: "腿举", machine: "Leg Press", primary: .legs),
        .init(name: "腿伸展", machine: "Leg Extension", primary: .legs),
        .init(name: "腿弯举", machine: "Leg Curl", primary: .legs),
        .init(name: "臀桥机", machine: "Glute Bridge", primary: .legs),
        .init(name: "髋外展", machine: "Hip Abductor", primary: .legs),
        .init(name: "髋内收", machine: "Hip Adductor", primary: .legs),
        .init(name: "坐姿提踵", machine: "Calf Raise", primary: .calves),
        .init(name: "绳索下压", machine: "Cable Pushdown", primary: .arms),
        .init(name: "二头弯举机", machine: "Biceps Curl", primary: .arms),
        .init(name: "三头伸展机", machine: "Triceps Extension", primary: .arms),
        .init(name: "反握弯举机", machine: "Reverse Curl", primary: .arms),
        .init(name: "腹肌卷腹机", machine: "Ab Crunch", primary: .core)
    ]

    static func workout(for date: Date, profile: UserProfile, progress: ProgressState, loadOverrides: [String: Double], repsOverrides: [String: Int], machinePreferences: [String: String]) -> WorkoutSession {
        let intensity = intensityProfile(for: profile, progress: progress)
        let focus = focusFor(date: date, profile: profile)
        let exercises = buildRoutine(intensity: intensity, goal: profile.goal, focus: focus, profile: profile, loadOverrides: loadOverrides, repsOverrides: repsOverrides, machinePreferences: machinePreferences)

        return WorkoutSession(
            id: UUID(),
            date: date.startOfDay,
            difficultyLevel: intensity.level,
            exercises: exercises
        )
    }

    static func shouldTrain(on date: Date, trainingDays: [Int], overrides: [String: Bool]) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: date)
        
        if let override = overrides[dateStr] {
            return override
        }
        
        let weekday = Calendar.current.component(.weekday, from: date)
        let mondayBased = ((weekday + 5) % 7) + 1 // convert Sunday=1 to Monday=1
        return trainingDays.contains(mondayBased)
    }

    static func nextTrainingDay(from date: Date, trainingDays: [Int], overrides: [String: Bool]) -> Date {
        for offset in 1...7 {
            let candidate = date.addingDays(offset)
            if shouldTrain(on: candidate, trainingDays: trainingDays, overrides: overrides) {
                return candidate
            }
        }
        return date.addingDays(1)
    }

    static func cycleWeek(for profile: UserProfile, referenceDate: Date = Date()) -> Int {
        let weeks = Calendar.current.dateComponents([.weekOfYear], from: profile.createdAt, to: referenceDate).weekOfYear ?? 0
        return (weeks % 5) + 1
    }

    static func isDeloadWeek(for profile: UserProfile, referenceDate: Date = Date()) -> Bool {
        cycleWeek(for: profile, referenceDate: referenceDate) == 5
    }

    static func intensityProfile(for profile: UserProfile, progress: ProgressState) -> IntensityProfile {
        let level = max(0, progress.level)
        let ageFactor: Double
        switch profile.age {
        case 0..<30: ageFactor = 1.0
        case 30..<40: ageFactor = 0.97
        case 40..<50: ageFactor = 0.94
        case 50..<60: ageFactor = 0.90
        default: ageFactor = 0.86
        }

        let weightFactor: Double
        switch profile.weightKg {
        case 0..<55: weightFactor = 0.94
        case 55..<75: weightFactor = 1.0
        case 75..<95: weightFactor = 1.03
        default: weightFactor = 1.05
        }

        var progressionBoost = 1.0 + Double(level) * 0.03
        let deloadModifier = isDeloadWeek(for: profile) ? 0.85 : 1.0
        
        // Auto-Rollback: Reduce intensity if user hasn't trained for a while
        if let lastDate = progress.lastSessionDate {
            let daysSince = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            if daysSince > 14 {
                progressionBoost *= 0.9 // Reduce by 10% if missed > 2 weeks
            } else if daysSince > 7 {
                progressionBoost *= 0.95 // Reduce by 5% if missed > 1 week
            }
        }
        
        let readiness = min(1.15, ageFactor * weightFactor * progressionBoost * deloadModifier)

        return IntensityProfile(level: level, readiness: readiness, missedExercises: progress.missedExercises)
    }

    private static func buildRoutine(intensity: IntensityProfile, goal: TrainingGoal, focus: TrainingFocus, profile: UserProfile, loadOverrides: [String: Double], repsOverrides: [String: Int], machinePreferences: [String: String]) -> [WorkoutExercise] {
        let deloadSetsAdjustment = focus.isDeload ? -1 : 0
        let baseSets = (Int(Double(goal.baseSetRange.upperBound) * intensity.readiness) + deloadSetsAdjustment)
            .clamped(to: goal.baseSetRange)
        let baseReps = Int(Double(goal.baseRepRange.upperBound) * intensity.readiness).clamped(to: goal.baseRepRange)

        var templates = machineLibrary.filter { focus.primaryGroups.contains($0.primary) }
        if templates.count < 4 {
            templates = machineLibrary
        }
        
        // Seed shuffle with block ID (4-week blocks) to keep routine consistent within a block
        // Calculate block index based on weeks since start (weeks 0-3 = block 0, 4-7 = block 1...)
        let weeksSinceStart = Calendar.current.dateComponents([.weekOfYear], from: profile.createdAt, to: Date()).weekOfYear ?? 0
        let blockIndex = weeksSinceStart / 4
        
        // Custom deterministic shuffle based on blockIndex
        // Simple seeded generator simulation
        var seed = blockIndex
        templates.sort { t1, t2 in
            seed = (seed &* 1664525 &+ 1013904223)
            return (seed % 2) == 0
        }
        
        // Prioritize preferred machines if available in templates
        templates.sort { t1, t2 in
            let pref1 = machinePreferences[t1.primary.rawValue] == t1.machine
            let pref2 = machinePreferences[t2.primary.rawValue] == t2.machine
            
            // Priority: Missed > Preferred > Random
            let missed1 = intensity.missedExercises.contains(t1.machine)
            let missed2 = intensity.missedExercises.contains(t2.machine)
            
            if missed1 && !missed2 { return true }
            if !missed1 && missed2 { return false }
            
            if pref1 && !pref2 { return true }
            if !pref1 && pref2 { return false }
            return false 
        }

        let pickCount = min(8, max(5, 5 + intensity.level / 2))
        let selected = Array(templates.prefix(pickCount))

        let tempo = intensity.level >= 6 ? "3-1-2" : "2-1-2"
        let rpe = min(9.0, goal.baseRPE + Double(intensity.level) * 0.1)

        return selected.map { template in
            let load = loadOverrides[template.machine] ?? recommendedLoadKg(for: template.primary, profile: profile, intensity: intensity)
            let reps = repsOverrides[template.machine] ?? baseReps
            return WorkoutExercise(
                id: UUID(),
                name: template.name,
                machine: template.machine,
                sets: baseSets,
                reps: reps,
                restSeconds: goal.restSeconds,
                tempo: tempo,
                targetRPE: rpe,
                recommendedLoadKg: load,
                notes: "建议重量为参考值，若RPE偏离目标请微调。"
            )
        }
    }

    static func focusFor(date: Date, profile: UserProfile, lastFocus: FocusType? = nil) -> TrainingFocus {
        let resolvedSplit = resolveSplit(profile)
        // If lastFocus is provided, calculate the next one in sequence
        // Otherwise fallback to calendar-based (legacy behavior or first run)
        
        let focusType: FocusType
        if let last = lastFocus {
            focusType = nextFocus(after: last, split: resolvedSplit)
        } else {
            // Fallback to calendar index if no history
            let index = trainingDayIndex(on: date, trainingDays: profile.trainingDays)
            focusType = focusByIndex(index, split: resolvedSplit)
        }
        
        return TrainingFocus(type: focusType, isDeload: isDeloadWeek(for: profile))
    }
    
    private static func nextFocus(after current: FocusType, split: TrainingSplit) -> FocusType {
        let order: [FocusType]
        switch split {
        case .auto, .fullBody: order = [.fullBody]
        case .pushPullLegs: order = [.push, .pull, .legs]
        case .upperLower: order = [.upper, .lower]
        case .pplul: order = [.push, .pull, .legs, .upper, .lower]
        case .pplupl: order = [.push, .pull, .legs, .upper, .push, .legs]
        }
        
        if let index = order.firstIndex(of: current) {
            return order[(index + 1) % order.count]
        }
        return order.first ?? .fullBody
    }
    
    private static func focusByIndex(_ index: Int, split: TrainingSplit) -> FocusType {
        switch split {
        case .auto, .fullBody: return .fullBody
        case .pushPullLegs:
            let order: [FocusType] = [.push, .pull, .legs]
            return order[max(0, index) % order.count]
        case .upperLower:
            let order: [FocusType] = [.upper, .lower]
            return order[max(0, index) % order.count]
        case .pplul:
            let order: [FocusType] = [.push, .pull, .legs, .upper, .lower]
            return order[max(0, index) % order.count]
        case .pplupl:
            let order: [FocusType] = [.push, .pull, .legs, .upper, .push, .legs]
            return order[max(0, index) % order.count]
        }
    }

    private static func resolveSplit(_ profile: UserProfile) -> TrainingSplit {
        switch profile.split {
        case .auto:
            if profile.trainingDays.count == 3 { return .pushPullLegs }
            if profile.trainingDays.count == 4 { return .upperLower }
            if profile.trainingDays.count == 5 { return .pplul }
            if profile.trainingDays.count >= 6 { return .pplupl }
            return .fullBody
        default:
            return profile.split
        }
    }

    private static func trainingDayIndex(on date: Date, trainingDays: [Int]) -> Int {
        let weekday = Calendar.current.component(.weekday, from: date)
        let mondayBased = ((weekday + 5) % 7) + 1
        let sorted = trainingDays.sorted()
        return sorted.firstIndex(of: mondayBased) ?? 0
    }

    private static func recommendedLoadKg(for group: PrimaryGroup, profile: UserProfile, intensity: IntensityProfile) -> Double {
        let baseFactor: Double
        switch group {
        case .legs: baseFactor = 0.70
        case .back: baseFactor = 0.55
        case .chest: baseFactor = 0.45
        case .shoulders: baseFactor = 0.30
        case .arms: baseFactor = 0.25
        case .calves: baseFactor = 0.40
        case .core: baseFactor = 0.20
        }
        let goalFactor: Double
        switch profile.goal {
        case .strength: goalFactor = 1.05
        case .hypertrophy: goalFactor = 1.0
        case .fatLoss: goalFactor = 0.9
        }
        let deloadFactor: Double = isDeloadWeek(for: profile) ? 0.85 : 1.0
        let load = profile.weightKg * baseFactor * goalFactor * intensity.readiness * deloadFactor
        return max(5.0, (load / 2.5).rounded() * 2.5)
    }

    static func progressedLoad(current: Double, goal: TrainingGoal, isDeload: Bool, group: PrimaryGroup = .chest) -> Double {
        if isDeload {
            return max(5.0, (current * 0.9 / 2.5).rounded() * 2.5)
        }
        
        let increment: Double
        if group == .legs || group == .back {
            increment = 2.5
        } else {
            increment = 1.25
        }
        
        let next = current + increment
        return max(5.0, (next / 2.5).rounded() * 2.5)
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

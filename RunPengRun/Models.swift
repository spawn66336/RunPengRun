import Foundation

enum TrainingGoal: String, Codable, CaseIterable, Identifiable {
    case strength
    case hypertrophy
    case fatLoss

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .strength: return "力量"
        case .hypertrophy: return "增肌"
        case .fatLoss: return "减脂"
        }
    }

    var description: String {
        switch self {
        case .strength: return "低次数、高强度"
        case .hypertrophy: return "中次数、中高强度"
        case .fatLoss: return "较高次数、较短休息"
        }
    }

    var baseSetRange: ClosedRange<Int> {
        switch self {
        case .strength: return 4...5
        case .hypertrophy: return 3...4
        case .fatLoss: return 2...3
        }
    }

    var baseRepRange: ClosedRange<Int> {
        switch self {
        case .strength: return 4...8
        case .hypertrophy: return 8...12
        case .fatLoss: return 12...16
        }
    }

    var restSeconds: Int {
        switch self {
        case .strength: return 150
        case .hypertrophy: return 90
        case .fatLoss: return 60
        }
    }

    var baseRPE: Double {
        switch self {
        case .strength: return 8.0
        case .hypertrophy: return 7.5
        case .fatLoss: return 7.0
        }
    }
}

enum TrainingSplit: String, Codable, CaseIterable, Identifiable {
    case auto
    case fullBody
    case pushPullLegs
    case upperLower
    case pplul
    case pplupl

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .auto: return "自动"
        case .fullBody: return "全身"
        case .pushPullLegs: return "推/拉/腿"
        case .upperLower: return "上/下肢"
        case .pplul: return "PPLUL"
        case .pplupl: return "PPLUPL"
        }
    }

    var description: String {
        switch self {
        case .auto: return "根据训练天数自动选择"
        case .fullBody: return "每次训练覆盖主要部位"
        case .pushPullLegs: return "推、拉、腿循环"
        case .upperLower: return "上肢与下肢交替"
        case .pplul: return "推/拉/腿/上/下"
        case .pplupl: return "推/拉/腿/上/推/腿"
        }
    }
}

enum PrimaryGroup: String {
    case chest
    case back
    case shoulders
    case legs
    case calves
    case arms
    case core
}

enum FocusType: String {
    case fullBody
    case push
    case pull
    case legs
    case upper
    case lower
}

struct TrainingFocus {
    let type: FocusType
    let isDeload: Bool

    var primaryGroups: [PrimaryGroup] {
        switch type {
        case .fullBody:
            return [.chest, .back, .shoulders, .legs, .calves, .arms, .core]
        case .push:
            return [.chest, .shoulders, .arms]
        case .pull:
            return [.back, .arms]
        case .legs:
            return [.legs, .calves, .core]
        case .upper:
            return [.chest, .back, .shoulders, .arms]
        case .lower:
            return [.legs, .calves, .core]
        }
    }
}

struct UserProfile: Codable {
    var age: Int
    var weightKg: Double
    var goal: TrainingGoal
    var trainingDays: [Int] // 1...7 (Mon...Sun)
    var split: TrainingSplit
    var createdAt: Date

    init(age: Int, weightKg: Double, goal: TrainingGoal, trainingDays: [Int], split: TrainingSplit = .auto, createdAt: Date) {
        self.age = age
        self.weightKg = weightKg
        self.goal = goal
        self.trainingDays = trainingDays
        self.split = split
        self.createdAt = createdAt
    }

    private enum CodingKeys: String, CodingKey {
        case age, weightKg, goal, trainingDays, split, createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        age = try container.decode(Int.self, forKey: .age)
        weightKg = try container.decode(Double.self, forKey: .weightKg)
        goal = try container.decode(TrainingGoal.self, forKey: .goal)
        trainingDays = try container.decode([Int].self, forKey: .trainingDays)
        split = try container.decodeIfPresent(TrainingSplit.self, forKey: .split) ?? .auto
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}

struct WorkoutExercise: Codable, Identifiable {
    var id: UUID
    var name: String
    var machine: String
    var sets: Int
    var reps: Int
    var restSeconds: Int
    var tempo: String
    var targetRPE: Double
    var recommendedLoadKg: Double
    var notes: String
    var completedSets: Int = 0

    private enum CodingKeys: String, CodingKey {
        case id, name, machine, sets, reps, restSeconds, tempo, targetRPE, recommendedLoadKg, notes, completedSets
    }

    init(id: UUID, name: String, machine: String, sets: Int, reps: Int, restSeconds: Int, tempo: String, targetRPE: Double, recommendedLoadKg: Double, notes: String, completedSets: Int = 0) {
        self.id = id
        self.name = name
        self.machine = machine
        self.sets = sets
        self.reps = reps
        self.restSeconds = restSeconds
        self.tempo = tempo
        self.targetRPE = targetRPE
        self.recommendedLoadKg = recommendedLoadKg
        self.notes = notes
        self.completedSets = completedSets
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        machine = try container.decode(String.self, forKey: .machine)
        sets = try container.decode(Int.self, forKey: .sets)
        reps = try container.decode(Int.self, forKey: .reps)
        restSeconds = try container.decode(Int.self, forKey: .restSeconds)
        tempo = try container.decode(String.self, forKey: .tempo)
        targetRPE = try container.decode(Double.self, forKey: .targetRPE)
        recommendedLoadKg = try container.decodeIfPresent(Double.self, forKey: .recommendedLoadKg) ?? 20.0
        notes = try container.decode(String.self, forKey: .notes)
        completedSets = try container.decodeIfPresent(Int.self, forKey: .completedSets) ?? 0
    }
}

struct WorkoutExerciseTemplate {
    let name: String
    let machine: String
    let primary: PrimaryGroup
}

struct IntensityProfile {
    let level: Int
    let readiness: Double
    let missedExercises: [String]
}

struct WorkoutSession: Codable, Identifiable {
    var id: UUID
    var date: Date
    var difficultyLevel: Int
    var exercises: [WorkoutExercise]
    var completed: Bool {
        guard !exercises.isEmpty else { return false }
        let totalSets = exercises.reduce(0) { $0 + $1.sets }
        let completedSets = exercises.reduce(0) { $0 + $1.completedSets }
        return completedSets == totalSets
    }
}

struct ProgressState: Codable {
    var totalSessions: Int
    var level: Int
    var lastSessionDate: Date?
    var missedExercises: [String] = [] // List of machine IDs skipped in the last relevant session
}

struct AppState: Codable {
    var profile: UserProfile?
    var progress: ProgressState
    var sessions: [WorkoutSession]
    var machineLoads: [String: Double]
    var machineReps: [String: Int]
    var machinePreferences: [String: String]
    var scheduleOverrides: [String: Bool] // YYYY-MM-DD -> true(train)/false(rest)

    init(profile: UserProfile?, progress: ProgressState, sessions: [WorkoutSession], machineLoads: [String: Double] = [:], machineReps: [String: Int] = [:], machinePreferences: [String: String] = [:], scheduleOverrides: [String: Bool] = [:]) {
        self.profile = profile
        self.progress = progress
        self.sessions = sessions
        self.machineLoads = machineLoads
        self.machineReps = machineReps
        self.machinePreferences = machinePreferences
        self.scheduleOverrides = scheduleOverrides
    }

    private enum CodingKeys: String, CodingKey {
        case profile, progress, sessions, machineLoads, machineReps, machinePreferences, scheduleOverrides
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        profile = try container.decodeIfPresent(UserProfile.self, forKey: .profile)
        progress = try container.decode(ProgressState.self, forKey: .progress)
        sessions = try container.decode([WorkoutSession].self, forKey: .sessions)
        machineLoads = try container.decodeIfPresent([String: Double].self, forKey: .machineLoads) ?? [:]
        machineReps = try container.decodeIfPresent([String: Int].self, forKey: .machineReps) ?? [:]
        machinePreferences = try container.decodeIfPresent([String: String].self, forKey: .machinePreferences) ?? [:]
        scheduleOverrides = try container.decodeIfPresent([String: Bool].self, forKey: .scheduleOverrides) ?? [:]
    }
}

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    func addingDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }
}

extension Array where Element == WorkoutSession {
    func session(on date: Date) -> WorkoutSession? {
        first { $0.date.isSameDay(as: date) }
    }
}

struct QuoteLibrary {
    static let quotes: [String] = [
        "古之立大事者，不惟有超世之才，亦必有坚忍不拔之志。 —— 苏轼",
        "锲而舍之，朽木不折；锲而不舍，金石可镂。 —— 荀子",
        "宝剑锋从磨砺出，梅花香自苦寒来。",
        "天行健，君子以自强不息。",
        "千里之行，始于足下。 —— 老子",
        "世上无难事，只要肯登攀。 —— 毛泽东",
        "与其临渊羡鱼，不如退而结网。",
        "欲穷千里目，更上一层楼。",
        "既然选择了远方，便只顾风雨兼程。 —— 汪国真",
        "流水不腐，户枢不蠹，动也。",
        "伟大的作品不是靠力量，而是靠坚持来完成的。 —— 约翰·约翰逊",
        "疼痛是暂时的，放弃的痛苦是永远的。 (Pain is temporary. Quitting lasts forever.)",
        "唯一的坏训练是那个你没去做的训练。",
        "罗马不是一天建成的。",
        "不要等待机会，而要创造机会。",
        "成功由一次又一次的失败积累而来，只要不丧失热情。 —— 丘吉尔",
        "你未完成的那些训练，正是你与目标之间的距离。",
        "自律即自由。 (Discipline is Freedom.)",
        "昨天你说是明天。 (Yesterday you said tomorrow.)",
        "没有什么能阻挡一颗向往强壮的心。",
        "强者征服今天，懦夫哀叹昨天，懒汉坐等明天。",
        "身体是革命的本钱。",
        "汗水是脂肪在哭泣。",
        "种一棵树最好的时间是十年前，其次是现在。",
        "看似不起眼的日复一日，会在将来的某一天，突然让你看到坚持的意义。",
        "也不要因为走得太远，而忘了为什么出发。",
        "即使慢，也比停滞不前好。",
        "改变就在每一次的坚持之中。",
        "你流下的每一滴汗水，都不会辜负你。",
        "自律不仅仅是让自己变得更好，而是为了让自己有更多的选择。"
    ]
    
    static func randomQuote() -> String {
        quotes.randomElement() ?? "坚持就是胜利！"
    }
    
    static func quote(for date: Date) -> String {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 0
        let index = dayOfYear % quotes.count
        return quotes[index]
    }
}

import Foundation

struct MachineInfo: Identifiable, Hashable {
    let id: String
    let displayName: String
    let englishName: String
    let iconName: String
    let group: PrimaryGroup
    let description: String
    let loadType: MachineLoadType
    
    init(_ id: String, displayName: String, englishName: String, iconName: String, group: PrimaryGroup, description: String, loadType: MachineLoadType = .stack(increment: 5.0)) {
        self.id = id
        self.displayName = displayName
        self.englishName = englishName
        self.iconName = iconName
        self.group = group
        self.description = description
        self.loadType = loadType
    }
}

enum MachineLoadType: Hashable, Codable {
    case plateLoaded // 挂片式 (Standard Olympic Plates)
    case stack(increment: Double) // 插片式 (Fixed increment)
}

enum MachineCatalog {
    static let machines: [MachineInfo] = [
        .init("Chest Press", displayName: "坐姿胸推", englishName: "Chest Press", iconName: "MachineIcons/Chest_Press", group: .chest, description: "锻炼胸大肌整体，增强推力", loadType: .stack(increment: 5)),
        .init("Pec Deck", displayName: "蝴蝶机夹胸", englishName: "Pec Deck", iconName: "MachineIcons/Pec_Deck", group: .chest, description: "孤立锻炼胸大肌中缝", loadType: .stack(increment: 5)),
        .init("Incline Chest Press", displayName: "上斜胸推", englishName: "Incline Chest Press", iconName: "MachineIcons/Incline_Chest_Press", group: .chest, description: "侧重上胸部肌肉", loadType: .stack(increment: 5)),
        .init("Cable Fly", displayName: "绳索夹胸", englishName: "Cable Fly", iconName: "MachineIcons/Cable_Fly", group: .chest, description: "全程保持胸肌张力，修饰胸型", loadType: .stack(increment: 2.5)),
        .init("Lat Pulldown", displayName: "高位下拉", englishName: "Lat Pulldown", iconName: "MachineIcons/Lat_Pulldown", group: .back, description: "锻炼背阔肌宽度", loadType: .stack(increment: 5)),
        .init("Seated Row", displayName: "坐姿划船", englishName: "Seated Row", iconName: "MachineIcons/Seated_Row", group: .back, description: "锻炼背部厚度与中下斜方肌", loadType: .stack(increment: 5)),
        .init("High Row", displayName: "坐姿高位划船", englishName: "High Row", iconName: "MachineIcons/High_Row", group: .back, description: "侧重背阔肌下部与大圆肌", loadType: .plateLoaded), // Often Hammer Strength
        .init("Rear Delt Fly", displayName: "反向飞鸟机", englishName: "Rear Delt Fly", iconName: "MachineIcons/Rear_Delt_Fly", group: .back, description: "锻炼三角肌后束", loadType: .stack(increment: 5)),
        .init("Shoulder Press", displayName: "坐姿肩推", englishName: "Shoulder Press", iconName: "MachineIcons/Shoulder_Press", group: .shoulders, description: "锻炼三角肌前束与中束", loadType: .stack(increment: 5)),
        .init("Lateral Raise", displayName: "侧平举机", englishName: "Lateral Raise", iconName: "MachineIcons/Lateral_Raise", group: .shoulders, description: "孤立锻炼三角肌中束，增加肩宽", loadType: .stack(increment: 2.5)),
        .init("Reverse Shoulder Press", displayName: "反向肩推", englishName: "Reverse Shoulder Press", iconName: "MachineIcons/Reverse_Shoulder_Press", group: .shoulders, description: "辅助肩部与上胸训练", loadType: .stack(increment: 5)),
        .init("Leg Press", displayName: "腿举", englishName: "Leg Press", iconName: "MachineIcons/Leg_Press", group: .legs, description: "大重量复合动作，刺激腿部整体", loadType: .plateLoaded),
        .init("Leg Extension", displayName: "腿伸展", englishName: "Leg Extension", iconName: "MachineIcons/Leg_Extension", group: .legs, description: "孤立锻炼股四头肌", loadType: .stack(increment: 5)),
        .init("Leg Curl", displayName: "腿弯举", englishName: "Leg Curl", iconName: "MachineIcons/Leg_Curl", group: .legs, description: "孤立锻炼股二头肌", loadType: .stack(increment: 5)),
        .init("Glute Bridge", displayName: "臀桥机", englishName: "Glute Bridge", iconName: "MachineIcons/Glute_Bridge", group: .legs, description: "针对臀大肌的孤立训练", loadType: .plateLoaded),
        .init("Hip Abductor", displayName: "髋外展", englishName: "Hip Abductor", iconName: "MachineIcons/Hip_Abductor", group: .legs, description: "锻炼臀中肌与大腿外侧", loadType: .stack(increment: 5)),
        .init("Hip Adductor", displayName: "髋内收", englishName: "Hip Adductor", iconName: "MachineIcons/Hip_Adductor", group: .legs, description: "锻炼大腿内侧肌群", loadType: .stack(increment: 5)),
        .init("Calf Raise", displayName: "坐姿提踵", englishName: "Calf Raise", iconName: "MachineIcons/Calf_Raise", group: .calves, description: "锻炼小腿三头肌", loadType: .plateLoaded),
        .init("Cable Pushdown", displayName: "绳索下压", englishName: "Cable Pushdown", iconName: "MachineIcons/Cable_Pushdown", group: .arms, description: "孤立锻炼肱三头肌", loadType: .stack(increment: 2.5)),
        .init("Biceps Curl", displayName: "二头弯举机", englishName: "Biceps Curl", iconName: "MachineIcons/Biceps_Curl", group: .arms, description: "孤立锻炼肱二头肌", loadType: .stack(increment: 5)),
        .init("Triceps Extension", displayName: "三头伸展机", englishName: "Triceps Extension", iconName: "MachineIcons/Triceps_Extension", group: .arms, description: "针对肱三头肌长头", loadType: .stack(increment: 5)),
        .init("Reverse Curl", displayName: "反握弯举机", englishName: "Reverse Curl", iconName: "MachineIcons/Reverse_Curl", group: .arms, description: "锻炼前臂与肱肌", loadType: .stack(increment: 5)),
        .init("Ab Crunch", displayName: "腹肌卷腹机", englishName: "Ab Crunch", iconName: "MachineIcons/Ab_Crunch", group: .core, description: "锻炼腹直肌", loadType: .stack(increment: 5)),
        
        // Warmup & Cardio
        .init("Treadmill", displayName: "跑步机", englishName: "Treadmill", iconName: "figure.run", group: .cardio, description: "有氧热身，提升体温", loadType: .plateLoaded), // Using plateLoaded as placeholder for 'manual'
        .init("Shoulder Circle", displayName: "肩部环绕", englishName: "Shoulder Circle", iconName: "figure.cooldown", group: .warmup, description: "活动肩关节", loadType: .plateLoaded),
        .init("Face Pull", displayName: "面拉", englishName: "Face Pull", iconName: "figure.strengthtraining.functional", group: .shoulders, description: "激活肩袖肌群与后束", loadType: .stack(increment: 2.5)),
        .init("Push Up", displayName: "俯卧撑", englishName: "Push Up", iconName: "figure.pushup", group: .chest, description: "激活胸肌与三头肌", loadType: .plateLoaded),
        .init("Scapular Pull Up", displayName: "肩胛骨引体", englishName: "Scapular Pull Up", iconName: "figure.arms.open", group: .back, description: "激活背部与肩胛骨", loadType: .plateLoaded),
        .init("Straight Arm Pulldown", displayName: "直臂下压", englishName: "Straight Arm Pulldown", iconName: "figure.core.training", group: .back, description: "激活背阔肌", loadType: .stack(increment: 2.5)),
        .init("Squat Jump", displayName: "深蹲跳", englishName: "Squat Jump", iconName: "figure.jumprope", group: .legs, description: "激活腿部爆发力", loadType: .plateLoaded),
        .init("Hip Mobility", displayName: "髋关节活动", englishName: "Hip Mobility", iconName: "figure.flexibility", group: .warmup, description: "打开髋关节", loadType: .plateLoaded),
        .init("Air Squat", displayName: "空手深蹲", englishName: "Air Squat", iconName: "figure.squat", group: .legs, description: "激活下肢肌群", loadType: .plateLoaded),
        .init("Jumping Jack", displayName: "开合跳", englishName: "Jumping Jack", iconName: "figure.mixed.cardio", group: .cardio, description: "全身热身，提升心率", loadType: .plateLoaded)
    ]

    static func info(for machineId: String) -> MachineInfo? {
        machines.first { $0.id == machineId }
    }

    static func equivalents(for machineId: String) -> [MachineInfo] {
        guard let info = info(for: machineId) else { return [] }
        return machines.filter { $0.group == info.group }
    }

    static func displayName(for machineId: String) -> String {
        info(for: machineId)?.displayName ?? machineId
    }

    static func englishName(for machineId: String) -> String {
        info(for: machineId)?.englishName ?? machineId
    }

    static func description(for machineId: String) -> String {
        info(for: machineId)?.description ?? ""
    }

    static func iconName(for machineId: String) -> String {
        info(for: machineId)?.iconName ?? "figure.strengthtraining.traditional"
    }
}

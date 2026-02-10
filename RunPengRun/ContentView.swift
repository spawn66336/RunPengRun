import SwiftUI
import UIKit
import UniformTypeIdentifiers

// MARK: - Reusable Modifiers

struct ModernCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(Color(uiColor: .systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 5)
    }
}

extension View {
    func modernCard() -> some View {
        modifier(ModernCardModifier())
    }
}

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject private var store: LocalStore

    var body: some View {
        if let profile = store.state.profile {
            TabView {
                NavigationStack {
                    HomeView(profile: profile)
                }
                .tabItem {
                    Label("计划", systemImage: "calendar")
                }

                StatsView()
                    .tabItem {
                        Label("统计", systemImage: "chart.xyaxis.line")
                    }
            }
        } else {
            NavigationStack {
                OnboardingView()
            }
        }
    }
}

// MARK: - RPEGuideView (Merged)
struct RPEGuideView: View {
    @Environment(\.dismiss) var dismiss
    
    let rpeLevels: [(level: Double, title: String, description: String, color: Color)] = [
        (10.0, "极限 (Failure)", "无法再多做一个动作，甚至无法维持标准姿势。", .red),
        (9.0, "极累 (1 RIR)", "还能标准完成最后一个动作，但绝对做不了两个。", .orange),
        (8.0, "很累 (2 RIR)", "还能完成2个动作。通常是训练组的推荐强度。", .yellow),
        (7.0, "累 (3 RIR)", "还能完成3个动作。移动速度开始变慢。", .green),
        (6.0, "有些累 (4 RIR)", "还能做4个左右。适合爆发力训练。", .blue),
        (5.0, "轻松", "还能做5个以上。通常用于热身。", .gray)
    ]
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("RPE (Rating of Perceived Exertion) 是自觉运动强度量表，用于衡量你在训练中的费力程度。\n\nRIR (Reps In Reserve) 是保留次数，即“还能做几个”。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16))
                }
                
                ForEach(rpeLevels, id: \.level) { item in
                    HStack(spacing: 16) {
                        Text("\(Int(item.level))")
                            .font(.system(.title2, design: .rounded).bold())
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .background(item.color)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.headline)
                            Text(item.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("RPE 强度对照表")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - MachineWeightHelperView
struct MachineWeightHelperView: View {
    @Binding var targetWeight: Double
    var machineName: String
    var loadType: MachineLoadType
    @Environment(\.dismiss) var dismiss
    
    @State private var baseWeight: Double = 0.0
    @State private var splitSides: Bool = false
    
    let plates: [Double] = [25, 20, 15, 10, 5, 2.5, 1.25]
    
    var weightToLoad: Double {
        max(0, targetWeight - baseWeight)
    }
    
    var weightPerSide: Double {
        splitSides ? weightToLoad / 2.0 : weightToLoad
    }
    
    var calculatedPlates: [(weight: Double, count: Int)] {
        var remaining = weightPerSide
        var result: [(Double, Int)] = []
        
        for plate in plates {
            let count = Int(remaining / plate)
            if count > 0 {
                result.append((plate, count))
                remaining -= Double(count) * plate
            }
        }
        return result
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(machineName)
                            .font(.headline)
                        
                        switch loadType {
                        case .plateLoaded:
                            Text("计算挂片式器械所需的配重片组合")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        case .stack(let increment):
                            Text("插片式配重 (每格 \(String(format: "%.1f", increment)) kg)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                }
                
                Section("设置") {
                    HStack {
                        Text("目标总重量")
                        Spacer()
                        TextField("kg", value: $targetWeight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    if case .plateLoaded = loadType {
                        HStack {
                            Text("器械初始阻力")
                            Spacer()
                            TextField("0", value: $baseWeight, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }
                        
                        Toggle("双侧均分模式", isOn: $splitSides)
                            .tint(.blue)
                        if splitSides {
                            Text("适用于倒蹬机、悍马机等左右对称挂片的器械")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                switch loadType {
                case .plateLoaded:
                    plateLoadedView
                case .stack(let increment):
                    stackView(increment: increment)
                }
            }
            .navigationTitle("配重助手")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    @ViewBuilder
    var plateLoadedView: some View {
        Section(splitSides ? "单侧需要挂片" : "总共需要挂片") {
            if weightPerSide <= 0 {
                Text("无需挂片")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(calculatedPlates, id: \.weight) { item in
                    HStack {
                        Circle()
                            .fill(plateColor(item.weight))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Text("\(Int(item.weight))")
                                    .font(.caption2)
                                    .foregroundStyle(.white)
                            )
                        
                        Text("\(item.weight.formatted()) kg")
                        Spacer()
                        Text("x \(item.count)")
                            .bold()
                    }
                }
            }
        }
        
        Section("可视化演示") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 10, height: 100)
                    
                    ForEach(calculatedPlates, id: \.weight) { item in
                        ForEach(0..<item.count, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(plateColor(item.weight))
                                .frame(width: plateWidth(item.weight), height: plateHeight(item.weight))
                                .overlay(
                                    Rectangle()
                                        .strokeBorder(Color.black.opacity(0.1), lineWidth: 1)
                                )
                        }
                    }
                    
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 20, height: 10)
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    @ViewBuilder
    func stackView(increment: Double) -> some View {
        // 智能计算：判断是否需要使用2.5kg微调片
        // 只有当主配重增量 >= 5kg 时，微调片才有意义（否则直接插下一格即可）
        let microWeight = 2.5
        let supportsMicro = increment >= 4.5
        
        var bestSlot = 0
        var useMicro = false
        var minDiff = Double.infinity
        
        // 遍历寻找最接近的组合
        // 尝试范围：理论格数上下浮动，结合有无微调片
        let approxSlots = Int(targetWeight / increment)
        for slot in max(0, approxSlots - 1)...(approxSlots + 1) {
            let base = Double(slot) * increment
            
            // 组合1：仅主配重
            let diff1 = abs(targetWeight - base)
            if diff1 < minDiff {
                minDiff = diff1
                bestSlot = slot
                useMicro = false
            }
            
            // 组合2：主配重 + 微调
            if supportsMicro {
                let diff2 = abs(targetWeight - (base + microWeight))
                if diff2 < minDiff {
                    minDiff = diff2
                    bestSlot = slot
                    useMicro = true
                }
            }
        }
        
        let actualWeight = Double(bestSlot) * increment + (useMicro ? microWeight : 0)
        
        return VStack(spacing: 20) {
            Section("插销位置建议") {
                if bestSlot <= 0 && !useMicro {
                    Text("无需负重")
                        .foregroundStyle(.secondary)
                } else {
                    HStack(spacing: 20) {
                        // 主配重指示
                        VStack {
                            Text("插在第")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(bestSlot)")
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                    .foregroundStyle(.blue)
                                Text("格")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                            Text("(\(Int(Double(bestSlot) * increment)) kg)")
                                .font(.caption.bold())
                                .foregroundStyle(.blue)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // 微调片指示
                        if useMicro {
                            Image(systemName: "plus")
                                .foregroundStyle(.secondary)
                            
                            VStack {
                                Text("微调片")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text("2.5")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundStyle(.orange)
                                    Text("kg")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Text("调节旋钮/挂小片")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    
                    HStack {
                        Text("总重量 ≈ \(String(format: "%.1f", actualWeight)) kg")
                            .font(.headline)
                        if abs(actualWeight - targetWeight) > 0.1 {
                            Text("(目标 \(String(format: "%.1f", targetWeight)))")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            Section("配重片示意图") {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 2) {
                            // 顶部微调片示意
                            if useMicro {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.orange)
                                        .frame(height: 12)
                                        .padding(.horizontal, 40)
                                    Text("+2.5kg 微调")
                                        .font(.caption2)
                                        .foregroundStyle(.white)
                                }
                                .padding(.bottom, 4)
                            }
                            
                            ForEach(1...max(15, bestSlot + 2), id: \.self) { i in
                                HStack {
                                    Text("\(i)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 20)
                                    
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(i <= bestSlot ? Color.blue : Color(uiColor: .systemGray5))
                                            .frame(height: 24)
                                        
                                        if i == bestSlot {
                                            // 插销示意
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 12, height: 12)
                                                .shadow(radius: 1)
                                                .padding(.leading, 100)
                                        }
                                        
                                        Text("\(String(format: "%.1f", Double(i) * increment))")
                                            .font(.caption2)
                                            .foregroundStyle(i <= bestSlot ? .white : .secondary)
                                            .padding(.leading, 8)
                                    }
                                    .id(i)
                                }
                            }
                        }
                        .padding()
                    }
                    .frame(height: 250)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onAppear {
                        proxy.scrollTo(bestSlot, anchor: .center)
                    }
                }
            }
        }
    }
    
    func plateColor(_ weight: Double) -> Color {
        switch weight {
        case 25: return .red
        case 20: return .blue
        case 15: return .yellow
        case 10: return .green
        case 5: return .white
        case 2.5: return .black
        default: return .gray
        }
    }
    
    func plateHeight(_ weight: Double) -> CGFloat {
        switch weight {
        case 25: return 120
        case 20: return 120
        case 15: return 100
        case 10: return 80
        case 5: return 60
        case 2.5: return 50
        case 1.25: return 40
        default: return 30
        }
    }
    
    func plateWidth(_ weight: Double) -> CGFloat {
        switch weight {
        case 25: return 25
        case 20: return 20
        case 15: return 18
        case 10: return 15
        case 5: return 12
        case 2.5: return 10
        case 1.25: return 8
        default: return 6
        }
    }
}

// MARK: - OnboardingView

struct OnboardingView: View {
    @EnvironmentObject private var store: LocalStore
    @State private var age = 28
    @State private var weight = 70.0
    @State private var goal: TrainingGoal = .hypertrophy
    @State private var split: TrainingSplit = .auto
    @State private var trainingDays: Set<Int> = [1, 3, 5]

    private let weekdays = [
        (1, "一"), (2, "二"), (3, "三"), (4, "四"), (5, "五"), (6, "六"), (7, "日")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 10) {
                    Text("欢迎使用 RunPengRun")
                        .font(.system(.title, design: .rounded).bold())
                        .multilineTextAlignment(.center)
                    Text("定制你的专属训练计划")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                // 1. 基础信息 Card
                VStack(alignment: .leading, spacing: 20) {
                    Text("基础信息")
                        .font(.headline)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("年龄")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(age) 岁")
                                .font(.system(.title3, design: .rounded).bold())
                        }
                        Spacer()
                        Stepper("", value: $age, in: 14...80)
                            .labelsHidden()
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("体重")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.1f kg", weight))
                                .font(.system(.title3, design: .rounded).bold())
                        }
                        Spacer()
                        HStack {
                            Button(action: { if weight > 30 { weight -= 0.5 } }) {
                                Image(systemName: "minus")
                                    .frame(width: 30, height: 30)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                            Button(action: { if weight < 200 { weight += 0.5 } }) {
                                Image(systemName: "plus")
                                    .frame(width: 30, height: 30)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .modernCard()

                // 2. 训练目标 Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("训练目标")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        ForEach(TrainingGoal.allCases) { item in
                            Button {
                                withAnimation { goal = item }
                            } label: {
                                VStack(spacing: 8) {
                                    Text(item.displayName)
                                        .font(.subheadline.bold())
                                    if goal == item {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(goal == item ? Color.blue.opacity(0.1) : Color(uiColor: .secondarySystemBackground))
                                .foregroundStyle(goal == item ? Color.blue : Color.primary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(goal == item ? Color.blue : Color.clear, lineWidth: 2)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    
                    Text(goal.description)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .modernCard()

                // 3. 训练节奏 Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("训练时间")
                        .font(.headline)
                    
                    HStack(spacing: 0) {
                        ForEach(weekdays, id: \.0) { day, label in
                            Button {
                                withAnimation {
                                    if trainingDays.contains(day) {
                                        trainingDays.remove(day)
                                    } else {
                                        trainingDays.insert(day)
                                    }
                                }
                            } label: {
                                VStack(spacing: 6) {
                                    Text(label)
                                        .font(.caption)
                                    ZStack {
                                        Circle()
                                            .fill(trainingDays.contains(day) ? Color.blue : Color(uiColor: .secondarySystemBackground))
                                            .frame(width: 36, height: 36)
                                        if trainingDays.contains(day) {
                                            Image(systemName: "dumbbell.fill")
                                                .font(.caption2)
                                                .foregroundStyle(.white)
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    
                    Text("每周训练 \(trainingDays.count) 天")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .modernCard()

                // 4. 训练拆分 Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("训练模式")
                            .font(.headline)
                        Spacer()
                        Picker("模式", selection: $split) {
                            ForEach(TrainingSplit.allCases) { item in
                                Text(item.displayName).tag(item)
                            }
                        }
                        .tint(.primary)
                    }
                    
                    Text(split.description)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .modernCard()

                // Submit Button
                Button {
                    let profile = UserProfile(
                        age: age,
                        weightKg: weight,
                        goal: goal,
                        trainingDays: trainingDays.sorted(),
                        split: split,
                        createdAt: Date()
                    )
                    store.updateProfile(profile)
                } label: {
                    Text("创建训练计划")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

struct IncrementalProgressView: View {
    let completed: Int
    let target: Int
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<max(completed, target), id: \.self) { index in
                        ZStack {
                            Circle()
                                .fill(circleColor(for: index))
                                .frame(width: 14, height: 14)
                                .scaleEffect(index < completed ? 1.2 : 1.0)
                            
                            if index < target {
                                Circle()
                                    .stroke(index < completed ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1.5)
                                    .frame(width: 24, height: 24)
                            }
                        }
                        .id(index)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: completed)
                    }
                }
                .padding(.horizontal, 4)
                .frame(height: 32)
            }
            .onChange(of: completed) { newValue in
                withAnimation {
                    proxy.scrollTo(newValue - 1, anchor: .trailing)
                }
            }
        }
    }
    
    private func circleColor(for index: Int) -> Color {
        if index < completed {
            return index < target ? .blue : .purple
        } else {
            return Color(uiColor: .systemGray5)
        }
    }
}

// MARK: - HomeView

struct HomeView: View {
    @EnvironmentObject private var store: LocalStore
    let profile: UserProfile

    private var today: Date { Date().startOfDay }
    @State private var exportURL: URL?
    @State private var isImporting = false
    @State private var showImportResult = false
    @State private var importSucceeded = false
    @State private var showRPEGuide = false
    @State private var showPlateCalculator = false
    @State private var plateCalculatorTargetWeight: Double = 20.0
    @State private var plateCalculatorMachineName: String = "配重助手"
    @State private var plateCalculatorLoadType: MachineLoadType = .stack(increment: 5)
    @State private var prMessage: String?
    @State private var showWaterReminder = false

    private var todaySession: WorkoutSession {
        if let existing = store.state.sessions.session(on: today) {
            return existing
        }
        let generated = Planner.workout(
            for: today,
            profile: profile,
            progress: store.state.progress,
            loadOverrides: store.state.machineLoads,
            repsOverrides: store.state.machineReps,
            machinePreferences: store.state.machinePreferences
        )
        store.saveSession(generated)
        return generated
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Date
                VStack(alignment: .leading) {
                    Text(chineseDateString(Date()))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Text("今日概览")
                        .font(.system(.largeTitle, design: .rounded).bold())
                }
                .padding(.horizontal)
                .padding(.top)

                summaryCard
                    .padding(.horizontal)
                
                // Weekly Schedule Card (New)
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("本周计划")
                            .font(.headline)
                        Spacer()
                        NavigationLink(destination: WeeklyScheduleView()) {
                            Text("查看全部")
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<7) { dayOffset in
                                let _ = Date().startOfDay.addingDays(dayOffset)
                                // Let's show "Current Week" Mon-Sun as requested context implies "This Week Plan"
                                let weekDates = currentWeekDates()
                                if dayOffset < weekDates.count {
                                    let dayDate = weekDates[dayOffset]
                                    DayMiniCard(date: dayDate, profile: profile)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                if Planner.shouldTrain(on: today, trainingDays: profile.trainingDays, overrides: store.state.scheduleOverrides) {
                    workoutCard(session: todaySession)
                        .padding(.horizontal)
                } else {
                    restCard
                        .padding(.horizontal)
                }
                
                historyCard
                    .padding(.horizontal)
            }
            .padding(.bottom, 40)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("RunPengRun")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    NavigationLink(destination: WeeklyScheduleView()) {
                        Label("本周计划", systemImage: "calendar")
                    }
                    Divider()
                    Button("导出训练数据", systemImage: "square.and.arrow.up") {
                        exportURL = store.exportState()
                    }
                    if let exportURL {
                        ShareLink(item: exportURL, subject: Text("RunPengRun 训练数据备份"))
                    }
                    Button("导入训练数据", systemImage: "square.and.arrow.down") {
                        isImporting = true
                    }
                    Divider()
                    Button("重新设置", systemImage: "arrow.counterclockwise", role: .destructive) { store.resetAllData() }
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(.primary)
                }
            }
        }
        .onAppear {
            NotificationManager.shared.requestAuthorization()
            if let profile = store.state.profile {
                NotificationManager.shared.scheduleNotifications(profile: profile)
            }
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                importSucceeded = store.importState(from: url)
            case .failure:
                importSucceeded = false
            }
            showImportResult = true
        }
        .sheet(isPresented: $showRPEGuide) {
            RPEGuideView()
        }
        .sheet(isPresented: $showPlateCalculator) {
            MachineWeightHelperView(targetWeight: $plateCalculatorTargetWeight, machineName: plateCalculatorMachineName, loadType: plateCalculatorLoadType)
        }
        .alert(importSucceeded ? "导入成功" : "导入失败", isPresented: $showImportResult) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(importSucceeded ? "训练数据已恢复" : "请确认文件格式正确")
        }
        .onReceive(store.newPRSubject) { (name, weight) in
            prMessage = "新纪录！\n\(name) \(String(format: "%.1f", weight)) kg"
        }
        .alert("恭喜破纪录！🎉", isPresented: Binding(
            get: { prMessage != nil },
            set: { if !$0 { prMessage = nil } }
        )) {
            Button("太棒了", role: .cancel) {}
        } message: {
            if let msg = prMessage { Text(msg) }
        }
        .overlay(alignment: .top) {
            if showWaterReminder {
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundStyle(.blue)
                    Text("记得喝水补充水分哦 💧")
                        .font(.subheadline.bold())
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .shadow(radius: 5)
                .padding(.top, 60)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(200)
            }
        }
    }

    private var summaryCard: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "target")
                        .foregroundStyle(.white.opacity(0.8))
                    Text(profile.goal.displayName)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                
                Text("Lv.\(store.state.progress.level)")
                    .font(.system(.title, design: .rounded).bold())
                    .foregroundStyle(.white)
                
                Text("累计训练 \(store.state.progress.totalSessions) 次")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
                .overlay(.white.opacity(0.3))
                .padding(.horizontal, 16)
            
            VStack(alignment: .leading, spacing: 8) {
                let cycleWeek = Planner.cycleWeek(for: profile)
                let isDeload = Planner.isDeloadWeek(for: profile)
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.white.opacity(0.8))
                    Text("第 \(cycleWeek) 周")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                
                if isDeload {
                    Text("减量周")
                        .font(.subheadline.bold())
                        .foregroundStyle(.yellow)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.black.opacity(0.2))
                        .clipShape(Capsule())
                } else {
                    let nextDay = Planner.nextTrainingDay(from: today, trainingDays: profile.trainingDays, overrides: store.state.scheduleOverrides)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("下次训练")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                        Text(dateString(nextDay))
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [Color.blue, Color.purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
    }

    private func workoutCard(session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("今日训练")
                        .font(.title2.bold())
                    Text(profile.split.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("强度 Lv.\(session.difficultyLevel)")
                        .font(.subheadline.bold())
                        .foregroundStyle(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                        .clipShape(Capsule())
                }

            Divider()
            
            if let warmup = session.warmup {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "figure.walk")
                            .foregroundStyle(.orange)
                        Text("热身建议")
                            .font(.headline)
                    }
                    
                    ForEach(warmup, id: \.self) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundStyle(.secondary)
                            Text(item)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
                
                Divider()
            }
            
            // Notifications / Warnings
            if session.difficultyLevel < store.state.progress.level {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.arrow.circlepath")
                        .foregroundStyle(.blue)
                    Text("检测到您已停练一段时间，为安全起见，系统已自动降低今日训练强度。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 8)
            }


            // Exercises
            ForEach(session.exercises) { exercise in
                VStack(alignment: .leading, spacing: 16) {
                    // Exercise Header
                    HStack(alignment: .center, spacing: 16) { // Improved alignment and spacing
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.05))
                                .frame(width: 80, height: 80) // Larger square container
                            
                            Image(MachineCatalog.iconName(for: exercise.machine))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(4)
                                .frame(width: 80, height: 80) // Fill the larger container
                                .foregroundStyle(.blue)
                                .background(Color.clear)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) { // Better vertical spacing for text
                            HStack(alignment: .top) {
                                Text(exercise.name)
                                    .font(.headline)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer()
                                Menu {
                                    let equivalents = MachineCatalog.equivalents(for: exercise.machine)
                                    ForEach(equivalents) { option in
                                        let load = store.state.machineLoads[option.id] ?? exercise.recommendedLoadKg
                                        let reps = store.state.machineReps[option.id] ?? exercise.reps
                                        Button("\(option.displayName) (\(String(format: "%.1f", load))kg · \(reps)次)") {
                                            store.updateExercise(on: session.date, exerciseId: exercise.id) { target in
                                                target.machine = option.id
                                                target.name = option.displayName
                                                target.recommendedLoadKg = load
                                                target.reps = reps
                                            }
                                            // Save preference
                                            if let info = MachineCatalog.info(for: option.id) {
                                                store.setMachinePreference(for: info.group.rawValue, machineId: option.id)
                                            }
                                        }
                                    }
                                } label: {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.caption)
                                        .padding(6)
                                        .background(Color(.secondarySystemBackground))
                                        .clipShape(Circle())
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("器械：\(MachineCatalog.displayName(for: exercise.machine))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Text(MachineCatalog.englishName(for: exercise.machine))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .italic()
                                
                                Text(MachineCatalog.description(for: exercise.machine))
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            HStack(spacing: 4) {
                                Text("\(exercise.sets)组 × \(exercise.reps)次 • 休息\(exercise.restSeconds)s • RPE \(String(format: "%.1f", exercise.targetRPE))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Button {
                                    showRPEGuide = true
                                } label: {
                                    Image(systemName: "info.circle")
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding(.top, 2)
                        }
                    }

                    // Data Display (Read-only as requested)
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("重量")
                                    .font(.caption2)
                                    .textCase(.uppercase)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button {
                                    plateCalculatorTargetWeight = exercise.recommendedLoadKg
                                    if let info = MachineCatalog.info(for: exercise.machine) {
                                        plateCalculatorMachineName = info.displayName
                                        plateCalculatorLoadType = info.loadType
                                    } else {
                                        plateCalculatorMachineName = exercise.name
                                        plateCalculatorLoadType = .stack(increment: 5)
                                    }
                                    showPlateCalculator = true
                                } label: {
                                    Image(systemName: "scalemass.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.blue)
                                }
                            }
                            Text("\(String(format: "%.1f", exercise.recommendedLoadKg))")
                                .font(.system(.title2, design: .rounded).bold()) +
                            Text(" kg").font(.caption).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("目标次数")
                                .font(.caption2)
                                .textCase(.uppercase)
                                .foregroundStyle(.secondary)
                            Text("\(exercise.reps)")
                                .font(.system(.title2, design: .rounded).bold()) +
                            Text(" 次").font(.caption).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("组数进度")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(exercise.completedSets) / \(exercise.sets)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(exercise.completedSets >= exercise.sets ? .purple : .secondary)
                        }
                        
                        IncrementalProgressView(completed: exercise.completedSets, target: exercise.sets)
                        
                        HStack(spacing: 12) {
                            Button {
                                if exercise.completedSets > 0 {
                                    store.updateExercise(on: session.date, exerciseId: exercise.id) { target in
                                        target.completedSets -= 1
                                    }
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                }
                            } label: {
                                Image(systemName: "arrow.uturn.backward")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 50, height: 50)
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(exercise.completedSets == 0)
                            .opacity(exercise.completedSets == 0 ? 0.5 : 1.0)
                            
                            Button {
                                store.updateExercise(on: session.date, exerciseId: exercise.id) { target in
                                    target.completedSets += 1
                                }
                                store.markSessionCompleted(on: session.date)
                                
                                let totalSets = session.exercises.reduce(0) { $0 + $1.completedSets }
                                if totalSets > 0 && totalSets % 6 == 0 {
                                    withAnimation {
                                        showWaterReminder = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                        withAnimation {
                                            showWaterReminder = false
                                        }
                                    }
                                }
                                
                                if exercise.completedSets + 1 == exercise.sets {
                                    let generator = UINotificationFeedbackGenerator()
                                    generator.notificationOccurred(.success)
                                } else if exercise.completedSets + 1 > exercise.sets {
                                    let generator = UIImpactFeedbackGenerator(style: .heavy)
                                    generator.impactOccurred()
                                } else {
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    
                                    TimerManager.shared.startTimer(seconds: exercise.restSeconds)
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("完成一组")
                                }
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(exercise.completedSets >= exercise.sets ? Color.purple : Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: (exercise.completedSets >= exercise.sets ? Color.purple : Color.blue).opacity(0.2), radius: 5, x: 0, y: 2)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("备注")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            
                            TextField("添加动作备注...", text: Binding(
                                get: { exercise.notes },
                                set: { newValue in
                                    store.updateExercise(on: session.date, exerciseId: exercise.id) { target in
                                        target.notes = newValue
                                    }
                                }
                            ), axis: .vertical)
                            .font(.caption)
                            .padding(8)
                            .background(Color(uiColor: .tertiarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding(.bottom, 8)
                
                if exercise.id != session.exercises.last?.id {
                    Divider()
                        .padding(.bottom, 8)
                }
            }

            // Finish Button Removed
        }
        .modernCard()
    }

    private var restCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 40))
                .foregroundStyle(.indigo)
                .padding()
                .background(Color.indigo.opacity(0.1))
                .clipShape(Circle())
            
            VStack(spacing: 8) {
                Text("今天是休息日")
                    .font(.title3.bold())
                Text("保持轻量活动，给身体恢复时间。")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let dateStr = formatter.string(from: today)
                store.setScheduleOverride(for: dateStr, isTraining: true)
            } label: {
                Text("开始临时加练")
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .modernCard()
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("最近记录")
                .font(.headline)
            
            if store.state.sessions.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.largeTitle)
                            .foregroundStyle(.gray.opacity(0.3))
                        Text("还没有训练记录")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(store.state.sessions.sorted(by: { $0.date > $1.date }).prefix(5)) { session in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(dateString(session.date))
                                    .font(.subheadline.bold())
                                Text("强度 Lv.\(session.difficultyLevel)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            let progress = calculateProgress(for: session)
                            let percentage = Int(progress * 100)
                            
                            Text("\(percentage)%")
                                .font(.caption.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(progressColor(progress).opacity(0.1))
                                .foregroundStyle(progressColor(progress))
                                .clipShape(Capsule())
                        }
                        .padding(12)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .modernCard()
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        return formatter.string(from: date)
    }
    
    private func chineseDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    private func currentWeekDates() -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysToSubtract = (weekday + 5) % 7
        
        guard let monday = calendar.date(byAdding: .day, value: -daysToSubtract, to: today) else { return [] }
        
        return (0..<7).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: monday)
        }
    }

    private func calculateProgress(for session: WorkoutSession) -> Double {
        let totalSets = Double(session.exercises.reduce(0) { $0 + $1.sets })
        let completedSets = Double(session.exercises.reduce(0) { $0 + $1.completedSets })
        return totalSets > 0 ? completedSets / totalSets : 0
    }

    private func progressColor(_ progress: Double) -> Color {
        if progress >= 1.0 { return .green }
        if progress >= 0.5 { return .blue }
        return .orange
    }
}

struct DayMiniCard: View {
    @EnvironmentObject private var store: LocalStore
    let date: Date
    let profile: UserProfile
    
    @State private var showDetail = false
    private var isToday: Bool { Calendar.current.isDateInToday(date) }
    private var isTrainingDay: Bool {
        Planner.shouldTrain(on: date, trainingDays: profile.trainingDays, overrides: store.state.scheduleOverrides)
    }
    
    var body: some View {
        Button {
            showDetail = true
        } label: {
            VStack(spacing: 8) {
                Text(weekDayString(date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(dayString(date))
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundStyle(isToday ? .white : .primary)
                    .frame(width: 36, height: 36)
                    .background(isToday ? Color.blue : Color.clear)
                    .clipShape(Circle())
                
                if isTrainingDay {
                    let focus = Planner.focusFor(date: date, profile: profile)
                    Text(focusShortName(focus.type))
                        .font(.caption2.bold())
                        .foregroundStyle(.blue)
                        .lineLimit(1)
                } else {
                    Text("休息")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 60, height: 90)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            NavigationStack {
                DayDetailView(date: date, profile: profile)
            }
            .presentationDetents([.medium, .large])
        }
    }
    private func isManualOverride(for date: Date) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: date)
        return store.state.scheduleOverrides[dateStr] != nil
    }

    private func weekDayString(_ date: Date) -> String {

        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    private func dayString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private func focusShortName(_ type: FocusType) -> String {
        switch type {
        case .fullBody: return "全身"
        case .push: return "推"
        case .pull: return "拉"
        case .legs: return "腿"
        case .upper: return "上肢"
        case .lower: return "下肢"
        }
    }
}

struct DayDetailView: View {
    @EnvironmentObject private var store: LocalStore
    let date: Date
    let profile: UserProfile
    
    private var session: WorkoutSession? {
        if let existing = store.state.sessions.session(on: date) {
            return existing
        }
        if Planner.shouldTrain(on: date, trainingDays: profile.trainingDays, overrides: store.state.scheduleOverrides) {
            return Planner.workout(
                for: date,
                profile: profile,
                progress: store.state.progress,
                loadOverrides: store.state.machineLoads,
                repsOverrides: store.state.machineReps,
                machinePreferences: store.state.machinePreferences
            )
        }
        return nil
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let session = session {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("训练详情")
                                .font(.title2.bold())
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .foregroundStyle(.orange)
                                Text("强度 Lv.\(session.difficultyLevel)")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.orange)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange.opacity(0.1))
                            .clipShape(Capsule())
                        }
                        
                        Divider()
                        
                        ForEach(session.exercises) { exercise in
                            HStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.blue.opacity(0.05))
                                        .frame(width: 80, height: 80)
                                    
                                    Image(MachineCatalog.iconName(for: exercise.machine))
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .padding(4)
                                        .frame(width: 80, height: 80)
                                        .foregroundStyle(.blue)
                                        .background(Color.clear)
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(exercise.name)
                                        .font(.headline)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    Text("\(exercise.sets)组 × \(exercise.reps)次 • \(String(format: "%.1f", exercise.recommendedLoadKg))kg")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color(uiColor: .secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.indigo.opacity(0.3))
                        Text("休息日")
                            .font(.title2.bold())
                            .foregroundStyle(.secondary)
                        Text("好好休息，为下次训练做准备")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                }
            }
        }
        .navigationTitle(dateString(date))
        .navigationBarTitleDisplayMode(.inline)
    }
    private func calculateProgress(for session: WorkoutSession) -> Double {
        guard !session.exercises.isEmpty else { return 0 }
        let totalSets = session.exercises.reduce(0) { $0 + $1.sets }
        let completedSets = session.exercises.reduce(0) { $0 + $1.completedSets }
        return totalSets > 0 ? Double(completedSets) / Double(totalSets) : 0
    }
    
    private func progressColor(_ progress: Double) -> Color {
        if progress >= 1.0 { return .green }
        if progress > 0 { return .blue }
        return .gray
    }

    private func dateString(_ date: Date) -> String {

        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        return formatter.string(from: date)
    }
}

#Preview {
    ContentView()
        .environmentObject(LocalStore())
}

// MARK: - WeeklyScheduleView

struct WeeklyScheduleView: View {
    @EnvironmentObject private var store: LocalStore
    
    private let weekDays = ["一", "二", "三", "四", "五", "六", "日"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let profile = store.state.profile {
                    headerView
                    
                    VStack(spacing: 12) {
                        ForEach(weekDates(), id: \.self) { date in
                            DayRowView(date: date, profile: profile, progress: store.state.progress)
                        }
                    }
                } else {
                    Text("请先创建训练计划")
                        .foregroundStyle(.secondary)
                        .padding()
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("本周计划")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("训练周期概览")
                .font(.headline)
            Text(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func weekDates() -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysToSubtract = (weekday + 5) % 7
        
        guard let monday = calendar.date(byAdding: .day, value: -daysToSubtract, to: today) else { return [] }
        
        return (0..<7).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: monday)
        }
    }
}

struct DayRowView: View {
    @EnvironmentObject private var store: LocalStore
    let date: Date
    let profile: UserProfile
    let progress: ProgressState
    
    @State private var showDetail = false
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private var isTrainingDay: Bool {
        Planner.shouldTrain(on: date, trainingDays: profile.trainingDays, overrides: store.state.scheduleOverrides)
    }
    
    var body: some View {
        Menu {
            Button(isTrainingDay ? "设为休息日" : "设为训练日") {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let dateStr = formatter.string(from: date)
                store.setScheduleOverride(for: dateStr, isTraining: !isTrainingDay)
            }
            
            Button("查看详情") {
                showDetail = true
            }
        } label: {
            HStack(spacing: 16) {
                // Date Column
                VStack(spacing: 4) {
                    Text(weekDayString(date))
                        .font(.caption.bold())
                        .foregroundStyle(isToday ? .blue : .secondary)
                    Text(dayString(date))
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundStyle(isToday ? .blue : .primary)
                }
                .frame(width: 50)
                .padding(.vertical, 8)
                .background(isToday ? Color.blue.opacity(0.1) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Content
                if isTrainingDay {
                    let focus = Planner.focusFor(date: date, profile: profile)
                    let intensity = Planner.intensityProfile(for: profile, progress: progress)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(focusName(focus.type))
                                .font(.headline)
                                .foregroundStyle(.primary)
                            if focus.isDeload {
                                Text("减量")
                                    .font(.caption.bold())
                                    .foregroundStyle(.yellow)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.yellow.opacity(0.2))
                                    .foregroundStyle(.yellow)
                                    .clipShape(Capsule())
                            }
                            
                            if isManualOverride(for: date) {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                        }
                        
                        HStack(spacing: 12) {
                            Label("强度 Lv.\(intensity.level)", systemImage: "flame.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                            
                            Label("\(focus.primaryGroups.count) 个肌群", systemImage: "dumbbell.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    HStack {
                        Image(systemName: "moon.fill")
                            .foregroundStyle(.indigo.opacity(0.5))
                        Text("休息日")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        if isManualOverride(for: date) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                if isTrainingDay {
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.tertiary)
                }
            }
            .padding()
            .background(Color(uiColor: .systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isToday ? Color.blue : Color.clear, lineWidth: 1.5)
            )
        } primaryAction: {
            showDetail = true
        }
        .sheet(isPresented: $showDetail) {
            NavigationStack {
                DayDetailView(date: date, profile: profile)
            }
            .presentationDetents([.medium, .large])
        }
    }
    
    private func isManualOverride(for date: Date) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: date)
        return store.state.scheduleOverrides[dateStr] != nil
    }
    
    private func weekDayString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    private func dayString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private func focusName(_ type: FocusType) -> String {
        switch type {
        case .fullBody: return "全身训练"
        case .push: return "推类训练 (胸/肩/三头)"
        case .pull: return "拉类训练 (背/二头)"
        case .legs: return "腿部训练"
        case .upper: return "上肢训练"
        case .lower: return "下肢训练"
        }
    }
    
    private func intensityDescription(level: Int) -> String {
        if level < 5 { return "基础适应期" }
        if level < 15 { return "进阶强化期" }
        return "高强度突破期"
    }
}

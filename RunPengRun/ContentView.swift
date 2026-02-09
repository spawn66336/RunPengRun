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
        NavigationStack {
            if let profile = store.state.profile {
                HomeView(profile: profile)
            } else {
                OnboardingView()
            }
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

// MARK: - HomeView

struct HomeView: View {
    @EnvironmentObject private var store: LocalStore
    let profile: UserProfile

    private var today: Date { Date().startOfDay }
    @State private var exportURL: URL?
    @State private var isImporting = false
    @State private var showImportResult = false
    @State private var importSucceeded = false

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
        .alert(importSucceeded ? "导入成功" : "导入失败", isPresented: $showImportResult) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(importSucceeded ? "训练数据已恢复" : "请确认文件格式正确")
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
            }

            Divider()
            
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
                            
                            Text("\(exercise.sets)组 × \(exercise.reps)次 • 休息\(exercise.restSeconds)s • RPE \(String(format: "%.1f", exercise.targetRPE))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 2)
                        }
                    }

                    // Data Display (Read-only as requested)
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("重量")
                                .font(.caption2)
                                .textCase(.uppercase)
                                .foregroundStyle(.secondary)
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

                    // Check-in Circles
                    VStack(alignment: .leading, spacing: 8) {
                        Text("打卡")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 12) {
                            ForEach(0..<exercise.sets, id: \.self) { index in
                                Button {
                                    let newCompleted = (index == exercise.completedSets - 1) ? index : index + 1
                                    store.updateExercise(on: session.date, exerciseId: exercise.id) { target in
                                        target.completedSets = newCompleted
                                    }
                                    store.markSessionCompleted(on: session.date)
                                    
                                    if newCompleted == exercise.sets {
                                        let generator = UINotificationFeedbackGenerator()
                                        generator.notificationOccurred(.success)
                                    } else {
                                        let generator = UIImpactFeedbackGenerator(style: .medium)
                                        generator.impactOccurred()
                                    }
                                } label: {
                                    ZStack {
                                        Circle()
                                            .stroke(index < exercise.completedSets ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                                            .background(
                                                Circle()
                                                    .fill(index < exercise.completedSets ? Color.blue : Color.clear)
                                            )
                                            .frame(width: 44, height: 44)
                                        
                                        if index < exercise.completedSets {
                                            Image(systemName: "checkmark")
                                                .font(.headline)
                                                .foregroundStyle(.white)
                                                .transition(.scale.combined(with: .opacity))
                                        } else {
                                            Text("\(index + 1)")
                                                .font(.subheadline)
                                                .foregroundStyle(.gray)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
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
}

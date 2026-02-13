import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject private var store: LocalStore
    @State private var selectedMachineId: String = "Chest Press"
    
    private var allMachines: [MachineInfo] {
        MachineCatalog.machines.sorted { $0.displayName < $1.displayName }
    }
    
    private struct StrengthData: Identifiable {
        let id = UUID()
        let date: Date
        let load: Double
    }
    
    private var strengthData: [StrengthData] {
        var data: [StrengthData] = []
        let sortedSessions = store.state.sessions.sorted { $0.date < $1.date }
        
        for session in sortedSessions {
            if let exercise = session.exercises.first(where: { $0.machine == selectedMachineId }) {
                if exercise.completedSets > 0 {
                    data.append(StrengthData(date: session.date, load: exercise.recommendedLoadKg))
                }
            }
        }
        return data
    }
    
    private struct MuscleData: Identifiable {
        let id = UUID()
        let group: String
        let sets: Int
    }
    
    private var muscleData: [MuscleData] {
        var counts: [PrimaryGroup: Int] = [:]
        
        for session in store.state.sessions {
            for exercise in session.exercises {
                if exercise.completedSets > 0 {
                    let group = MachineCatalog.info(for: exercise.machine)?.group ?? .chest
                    counts[group, default: 0] += exercise.completedSets
                }
            }
        }
        
        return counts.map { key, value in
            MuscleData(group: key.displayName, sets: value)
        }.sorted { $0.sets > $1.sets }
    }
    
    private struct WeeklyData: Identifiable {
        let id = UUID()
        let weekStart: Date
        let count: Int
    }
    
    private struct Achievement: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let icon: String
        let unlocked: Bool
    }
    
    private var achievements: [Achievement] {
        let totalSessions = store.state.progress.totalSessions
        let level = store.state.progress.level
        
        return [
            Achievement(title: "初出茅庐", description: "完成第1次训练", icon: "figure.walk", unlocked: totalSessions >= 1),
            Achievement(title: "坚持不懈", description: "累计训练10次", icon: "figure.run", unlocked: totalSessions >= 10),
            Achievement(title: "健身达人", description: "累计训练50次", icon: "figure.strengthtraining.traditional", unlocked: totalSessions >= 50),
            Achievement(title: "超凡大师", description: "累计训练100次", icon: "trophy.fill", unlocked: totalSessions >= 100),
            Achievement(title: "力量觉醒", description: "等级达到 Lv.5", icon: "bolt.fill", unlocked: level >= 5),
            Achievement(title: "钢铁之躯", description: "等级达到 Lv.20", icon: "dumbbell.fill", unlocked: level >= 20)
        ]
    }
    
    private var consistencyData: [WeeklyData] {
        var counts: [Date: Int] = [:]
        let calendar = Calendar.current
        
        for session in store.state.sessions {
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: session.date)
            if let startOfWeek = calendar.date(from: components) {
                counts[startOfWeek, default: 0] += 1
            }
        }
        
        return counts.map { key, value in
            WeeklyData(weekStart: key, count: value)
        }.sorted { $0.weekStart < $1.weekStart }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("成就徽章")
                            .font(.headline)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 16) {
                            ForEach(achievements) { item in
                                VStack(spacing: 8) {
                                    Image(systemName: item.icon)
                                        .font(.title)
                                        .foregroundStyle(item.unlocked ? Color.orange : Color.gray)
                                        .frame(width: 60, height: 60)
                                        .background(item.unlocked ? Color.orange.opacity(0.1) : Color(uiColor: .secondarySystemBackground))
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(item.unlocked ? Color.orange.opacity(0.5) : Color.clear, lineWidth: 2)
                                        )
                                    
                                    Text(item.title)
                                        .font(.caption.bold())
                                        .foregroundStyle(item.unlocked ? .primary : .secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .opacity(item.unlocked ? 1.0 : 0.6)
                            }
                        }
                    }
                    .modernCard()
                    
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("力量进阶")
                                .font(.headline)
                            Spacer()
                            Picker("选择动作", selection: $selectedMachineId) {
                                ForEach(allMachines) { machine in
                                    Text(machine.displayName).tag(machine.id)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.blue)
                        }
                        
                        if strengthData.isEmpty {
                            emptyChartPlaceholder(text: "暂无该动作的训练记录")
                        } else {
                            Chart(strengthData) { item in
                                LineMark(
                                    x: .value("日期", item.date),
                                    y: .value("负重 (kg)", item.load)
                                )
                                .interpolationMethod(.catmullRom)
                                .symbol(by: .value("日期", item.date))
                                .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                                
                                AreaMark(
                                    x: .value("日期", item.date),
                                    y: .value("负重 (kg)", item.load)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(LinearGradient(colors: [.blue.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom))
                            }
                            .frame(height: 250)
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                        }
                    }
                    .modernCard()
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("肌群分布")
                            .font(.headline)
                        
                        if muscleData.isEmpty {
                            emptyChartPlaceholder(text: "暂无训练数据")
                        } else {
                            Chart(muscleData) { item in
                                SectorMark(
                                    angle: .value("组数", item.sets),
                                    innerRadius: .ratio(0.6),
                                    angularInset: 2
                                )
                                .foregroundStyle(by: .value("部位", item.group))
                                .cornerRadius(5)
                            }
                            .frame(height: 250)
                            .chartLegend(position: .bottom, spacing: 20)
                        }
                    }
                    .modernCard()
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("训练频率 (周)")
                            .font(.headline)
                        
                        if consistencyData.isEmpty {
                            emptyChartPlaceholder(text: "暂无训练记录")
                        } else {
                            Chart(consistencyData) { item in
                                BarMark(
                                    x: .value("周", item.weekStart, unit: .weekOfYear),
                                    y: .value("次数", item.count)
                                )
                                .foregroundStyle(Color.blue.gradient)
                                .cornerRadius(8)
                            }
                            .frame(height: 200)
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                                    AxisValueLabel(format: .dateTime.month().day())
                                }
                            }
                        }
                    }
                    .modernCard()
                    
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("数据统计")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func emptyChartPlaceholder(text: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.xyaxis.line")
                .font(.largeTitle)
                .foregroundStyle(.gray.opacity(0.3))
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(Color(uiColor: .secondarySystemBackground).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

extension PrimaryGroup {
    var displayName: String {
        switch self {
        case .chest: return "胸部"
        case .back: return "背部"
        case .shoulders: return "肩部"
        case .legs: return "腿部"
        case .calves: return "小腿"
        case .arms: return "手臂"
        case .core: return "核心"
        case .warmup: return "热身"
        case .cardio: return "有氧"
        }
    }
}

#Preview {
    StatsView()
        .environmentObject(LocalStore())
}
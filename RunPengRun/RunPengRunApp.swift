import SwiftUI
import Combine
import UserNotifications
import UIKit

// MARK: - TimerManager (Merged from TimerManager.swift)
class TimerManager: ObservableObject {
    @Published var timeRemaining: Int = 0
    @Published var isActive: Bool = false
    @Published var totalTime: Int = 0
    
    private var timer: AnyCancellable?
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    static let shared = TimerManager()
    
    private init() {
        setupNotifications()
    }
    
    func startTimer(seconds: Int) {
        stopTimer()
        
        self.totalTime = seconds
        self.timeRemaining = seconds
        self.isActive = true
        
        scheduleNotification(seconds: seconds)
        
        beginBackgroundTask()
        
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.stopTimer()
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            }
    }
    
    func stopTimer() {
        timer?.cancel()
        timer = nil
        isActive = false
        timeRemaining = 0
        cancelNotification()
        endBackgroundTask()
    }
    
    func addTime(seconds: Int) {
        if isActive {
            timeRemaining += seconds
            totalTime += seconds
            cancelNotification()
            scheduleNotification(seconds: timeRemaining)
        }
    }
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    
    private func scheduleNotification(seconds: Int) {
        let content = UNMutableNotificationContent()
        content.title = "休息结束"
        content.body = "下一组训练开始了！"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let request = UNNotificationRequest(identifier: "RestTimer", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["RestTimer"])
    }
    
    private func beginBackgroundTask() {
        backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
}

// MARK: - TimerView (Merged from TimerView.swift)
struct TimerView: View {
    @ObservedObject var timerManager = TimerManager.shared
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        if timerManager.isActive {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("休息中")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(timeString(time: timerManager.timeRemaining))
                            .font(.system(.title, design: .monospaced).bold())
                            .foregroundStyle(.primary)
                            .contentTransition(.numericText())
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button {
                            timerManager.addTime(seconds: 30)
                        } label: {
                            Text("+30s")
                                .font(.caption.bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(uiColor: .secondarySystemBackground))
                                .clipShape(Capsule())
                        }
                        
                        Button {
                            timerManager.stopTimer()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.gray)
                        }
                    }
                }
                
                ProgressView(value: Double(timerManager.totalTime - timerManager.timeRemaining), total: Double(timerManager.totalTime))
                    .tint(.blue)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(uiColor: .systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
            .padding(.horizontal)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: timerManager.isActive)
        }
    }
    
    private func timeString(time: Int) -> String {
        let minutes = time / 60
        let seconds = time % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

@main
struct RunPengRunApp: App {
    @StateObject private var store = LocalStore()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation(.easeOut(duration: 0.5)) {
                                    showSplash = false
                                }
                            }
                        }
                        .zIndex(200)
                }
                
                ContentView()
                    .environmentObject(store)
                    .zIndex(0)
                
                VStack {
                    Spacer()
                    TimerView()
                }
                .padding(.bottom, 50)
                .zIndex(100)
            }
        }
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            // 背景层：使用高斯模糊的图片作为背景，实现颜色自适应
            Image("Splash")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
                .blur(radius: 60)
                .overlay(Color.black.opacity(0.2)) // 略微压暗，提升质感
            
            // 前景层：图片宽度适配屏幕
            Image("Splash")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .shadow(radius: 10) // 添加阴影增加层次感
        }
        .background(Color.black) // 兜底背景色
    }
}


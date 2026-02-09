import SwiftUI

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
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation {
                                    showSplash = false
                                }
                            }
                        }
                } else {
                    ContentView()
                        .environmentObject(store)
                        .transition(.opacity)
                }
            }
        }
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            Image("Splash")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
                .blur(radius: 30)
                .overlay(Color.black.opacity(0.1))
            
            Image("Splash")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
        }
    }
}

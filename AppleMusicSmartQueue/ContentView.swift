import SwiftUI
import SmartQueueMusicKit

struct ContentView: View {
    @State private var isSmartQueueEnabled = false
    @State private var discoveryLevel = 0.2
    @State private var authorizationState: MusicAuthorizationState = .notDetermined
    private let authorization = MusicAuthorizationService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("智能漫游")
                            .font(.largeTitle.bold())
                        Text("让 Apple Music 决定下一首该听什么。")
                            .foregroundStyle(.secondary)
                    }

                    authorizationCard
                    smartQueueCard
                    discoveryCard
                    architectureCard
                }
                .padding()
            }
            .navigationTitle("Smart Queue")
            .task {
                authorizationState = authorization.currentState()
            }
        }
    }

    private var authorizationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Apple Music", systemImage: "apple.logo")
                .font(.headline)

            Text(authorizationMessage)
                .foregroundStyle(.secondary)

            if authorizationState != .authorized {
                Button("授权 Apple Music") {
                    Task {
                        authorizationState = await authorization.requestAuthorization()
                    }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Label("已连接", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private var smartQueueCard: some View {
        Button {
            isSmartQueueEnabled.toggle()
        } label: {
            HStack {
                Image(systemName: isSmartQueueEnabled ? "pause.fill" : "play.fill")
                Text(isSmartQueueEnabled ? "停止智能漫游" : "开始智能漫游")
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .disabled(authorizationState != .authorized)
        .opacity(authorizationState == .authorized ? 1 : 0.5)
    }

    private var discoveryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("探索程度")
                .font(.headline)
            HStack {
                Text("熟悉")
                    .foregroundStyle(.secondary)
                Slider(value: $discoveryLevel, in: 0...1)
                Text("新鲜")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private var architectureCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("工作原理")
                .font(.headline)
            Label("读取 Apple Music 个性化推荐", systemImage: "music.note.list")
            Label("减少重复歌曲和歌手", systemImage: "arrow.triangle.2.circlepath")
            Label("自动生成下一批播放队列", systemImage: "text.line.3.horizontal")
            Label("由 Apple Music 原生播放器负责播放", systemImage: "apple.logo")
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private var authorizationMessage: String {
        switch authorizationState {
        case .notDetermined:
            return "首次使用需要允许 Smart Queue 访问 Apple Music。"
        case .authorized:
            return "Smart Queue 已获得 Apple Music 访问权限。"
        case .denied:
            return "访问权限已关闭，请在系统设置中重新允许。"
        case .restricted:
            return "当前设备限制了 Apple Music 访问。"
        case .unknown:
            return "无法确定 Apple Music 的授权状态。"
        }
    }
}

#Preview {
    ContentView()
}

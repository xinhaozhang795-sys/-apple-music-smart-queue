import SwiftUI

struct ContentView: View {
    @State private var isSmartQueueEnabled = false
    @State private var discoveryLevel = 0.2

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

                    Button {
                        isSmartQueueEnabled.toggle()
                    } label: {
                        HStack {
                            Image(systemName: isSmartQueueEnabled ? "pause.fill" : "play.fill")
                            Text(isSmartQueueEnabled ? "停止智能漫游" : "开始智能漫游")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)

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
                .padding()
            }
            .navigationTitle("Smart Queue")
        }
    }
}

#Preview {
    ContentView()
}

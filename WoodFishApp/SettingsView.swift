import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var meritManager: MeritManager
    
    // 定义固定的时间间隔选项
    private let intervalOptions: [Double] = [0.5, 1.0, 1.5, 2.0, 3.0, 5.0, 10.0, 20.0]
    
    var body: some View {
        NavigationView {  // 使用 NavigationView 来保持兼容性
            Form {
                Section(header: Text("声音设置")) {
                    Toggle("启用音效", isOn: $meritManager.soundEnabled)
                    
                    if meritManager.soundEnabled {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("木鱼音色")
                                .foregroundColor(.gray)
                            
                            Picker("木鱼音色", selection: $meritManager.currentSound) {
                                ForEach(WoodFishSound.allCases, id: \.self) { sound in
                                    Text(sound.displayName).tag(sound)
                                }
                            }
                            .pickerStyle(.segmented)
                            
                            Divider()
                                .padding(.vertical, 5)
                            
                            HStack {
                                Image(systemName: "speaker.fill")
                                    .foregroundColor(.gray)
                                Slider(value: $meritManager.volume)
                                Image(systemName: "speaker.wave.3.fill")
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 5)
                        }
                        .padding(.vertical, 5)
                    }
                }
                
                Section(header: Text("自动功德")) {
                    Toggle("启用自动敲击", isOn: $meritManager.autoTapEnabled.animation())
                    
                    if meritManager.autoTapEnabled {
                        VStack(alignment: .leading, spacing: 10) {
                            Picker("间隔时间", selection: $meritManager.autoTapInterval) {
                                ForEach(intervalOptions, id: \.self) { interval in
                                    Text("\(String(format: "%.1f", interval))秒")
                                        .tag(interval)
                                }
                            }
                            .pickerStyle(.menu)
                            #if compiler(>=5.9)
                            .onChange(of: meritManager.autoTapEnabled) { oldValue, newValue in
                                if newValue && meritManager.autoTapInterval < 0.1 {
                                    meritManager.autoTapInterval = 2.0
                                }
                            }
                            #else
                            .onChange(of: meritManager.autoTapEnabled) { isEnabled in
                                if isEnabled && meritManager.autoTapInterval < 0.1 {
                                    meritManager.autoTapInterval = 2.0
                                }
                            }
                            #endif
                        }
                        .padding(.vertical, 5)
                    }
                }
                
                Section {
                    Button("重置功德") {
                        meritManager.resetMerit()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("完成") {
                dismiss()
            })
        }
    }
} 

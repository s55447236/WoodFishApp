import SwiftUI
import AVFoundation
import WidgetKit
import AudioToolbox  // 添加这个导入

// 在 MeritManager 中添加声音类型枚举和相关属性
enum WoodFishSound: String, CaseIterable {
    case normal = "woodfish"
    case soft = "woodfish_soft"
    case deep = "woodfish_deep"
    
    var displayName: String {
        switch self {
        case .normal: return "标准木鱼"
        case .soft: return "柔和木鱼"
        case .deep: return "低沉木鱼"
        }
    }
}

class MeritManager: ObservableObject {
    // 修改这里的 group identifier
    private let defaults = UserDefaults(suiteName: "group.com.xumengzhang.WoodFishApp")!
    
    @Published var merit: Int {
        didSet {
            defaults.set(merit, forKey: "merit")
            // 通知小组件更新
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    @Published var soundEnabled: Bool {
        didSet {
            defaults.set(soundEnabled, forKey: "soundEnabled")
        }
    }
    @Published var currentSound: WoodFishSound {
        didSet {
            defaults.set(currentSound.rawValue, forKey: "currentSound")
            loadSound() // 切换音效时重新加载
        }
    }
    @Published var volume: Double {
        didSet {
            defaults.set(volume, forKey: "volume")
            audioPlayer?.volume = Float(volume)
        }
    }
    @Published var autoTapEnabled: Bool {
        didSet {
            defaults.set(autoTapEnabled, forKey: "autoTapEnabled")
            if autoTapEnabled {
                startAutoTap()
            } else {
                stopAutoTap()
            }
        }
    }
    
    @Published var autoTapInterval: Double {
        didSet {
            defaults.set(autoTapInterval, forKey: "autoTapInterval")
            if autoTapEnabled {
                stopAutoTap()
                startAutoTap()
            }
        }
    }
    
    // 添加应用状态属性
    @Published var isAppActive: Bool = true {
        didSet {
            // 当应用状态变化时，如果自动敲击已启用，重新启动定时器
            if autoTapEnabled {
                stopAutoTap()
                startAutoTap()
            }
        }
    }
    
    private var audioPlayer: AVAudioPlayer?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var autoTapTimer: DispatchSourceTimer?
    
    init() {
        // 首先初始化所有存储属性
        self.merit = defaults.integer(forKey: "merit")
        self.soundEnabled = defaults.bool(forKey: "soundEnabled")
        
        // 修改这里的音效初始化
        if let soundString = defaults.string(forKey: "currentSound"),
           let sound = WoodFishSound(rawValue: soundString) {
            self.currentSound = sound
        } else {
            self.currentSound = .normal
        }
        
        self.volume = defaults.double(forKey: "volume") != 0 ?
            defaults.double(forKey: "volume") : 1.0
        self.autoTapEnabled = defaults.bool(forKey: "autoTapEnabled")
        self.autoTapInterval = defaults.double(forKey: "autoTapInterval") != 0 ?
            defaults.double(forKey: "autoTapInterval") : 2.0
        
        // 修改音频会话设置
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.ambient, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("设置音频会话失败: \(error)")
        }
        
        // 初始化音效
        loadSound()
        
        // 如果启用了自动敲击，启动定时器
        if autoTapEnabled {
            startAutoTap()
        }
        
        // 监听应用状态变化
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc private func appDidEnterBackground() {
        isAppActive = false
    }
    
    @objc private func appWillEnterForeground() {
        isAppActive = true
    }
    
    private func loadSound() {
        if let soundURL = Bundle.main.url(forResource: currentSound.rawValue, withExtension: "MP3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.prepareToPlay()
                audioPlayer?.volume = Float(volume)
                print("成功加载音频文件: \(currentSound.rawValue)")
            } catch {
                print("音效加载失败: \(error)")
            }
        } else {
            print("未找到音频文件: \(currentSound.rawValue).MP3")
        }
    }
    
    func playSound() {
        if soundEnabled {
            if let player = audioPlayer {
                // 每次播放前重置播放位置
                player.currentTime = 0
                player.play()
                print("正在播放音效: \(currentSound.rawValue)")
            } else {
                print("播放器未初始化，重新加载音效")
                loadSound()
                audioPlayer?.play()
            }
        }
    }
    
    func resetMerit() {
        merit = 0
    }
    
    private func startAutoTap() {
        stopAutoTap()
        
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.stopAutoTap()
            UIApplication.shared.endBackgroundTask(self?.backgroundTask ?? .invalid)
            self?.backgroundTask = .invalid
        }
        
        let timer = DispatchSource.makeTimerSource(queue: .global())
        timer.schedule(deadline: .now(), repeating: .seconds(Int(autoTapInterval)))
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.merit += 1
                
                // 发送通知以触发动画，但只有在应用处于前台时才发送
                if self.isAppActive {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("AutoTapAnimation"),
                        object: nil
                    )
                }
                
                // 记录更新时间
                self.defaults.set(Date().timeIntervalSince1970, forKey: "lastUpdateTime")
                
                WidgetCenter.shared.reloadAllTimelines()
                
                if self.soundEnabled {
                    self.playSound()
                }
            }
        }
        timer.resume()
        
        self.autoTapTimer = timer
    }
    
    private func stopAutoTap() {
        autoTapTimer?.cancel()
        autoTapTimer = nil
        
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    deinit {
        stopAutoTap()
        // 移除通知观察者
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - 动画组件

// 功德+1 动画文本
struct AnimatedScoreText: View {
    let score: Int
    let position: CGPoint
    let onComplete: () -> Void
    
    @State private var opacity: Double = 1
    @State private var offset: CGFloat = 0
    
    var body: some View {
        Text("功德+\(score)")
            .font(.custom("SourceHanSerifCN-Heavy", size: 24))
            .foregroundColor(Color(hex: "703232"))
            .position(position)
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    offset -= 80
                    opacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    onComplete()
                }
            }
    }
}

// 功德数字显示
struct AnimatedNumberText: View {
    let number: Int
    
    var body: some View {
        VStack(spacing: 4) {
            Text("功德")
                .font(.custom("SourceHanSerifCN-Heavy", size: 32))
                .foregroundColor(Color(hex: "592424"))
            
            HStack(spacing: 2) {
                ForEach(Array(String(number).enumerated()), id: \.offset) { index, char in
                    if let digit = Int(String(char)) {
                        SingleDigitCounter(digit: digit)
                    }
                }
            }
        }
    }
}

// 单个数字的滚动动画
struct SingleDigitCounter: View {
    let digit: Int
    @State private var previousDigit: Int?
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // 当前数字
            Text("\(digit)")
                .font(.custom("SourceHanSerifCN-Heavy", size: 32))
                .foregroundColor(Color(hex: "592424"))
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
            
            // 前一个数字
            if let prev = previousDigit {
                Text("\(prev)")
                    .font(.custom("SourceHanSerifCN-Heavy", size: 32))
                    .foregroundColor(Color(hex: "592424"))
                    .opacity(isAnimating ? 0 : 1)
                    .offset(y: isAnimating ? -20 : 0)
            }
        }
        .clipped()
        .onAppear {
            if previousDigit == nil {
                previousDigit = digit
                isAnimating = true
            } else {
                withAnimation(.easeOut(duration: 0.2)) {
                    isAnimating = true
                }
            }
        }
        #if compiler(>=5.9)
        .onChange(of: digit) { oldValue, newValue in
            isAnimating = false
            previousDigit = digit
            withAnimation(.easeOut(duration: 0.2)) {
                isAnimating = true
            }
        }
        #else
        .onChange(of: digit) { newValue in
            isAnimating = false
            previousDigit = digit
            withAnimation(.easeOut(duration: 0.2)) {
                isAnimating = true
            }
        }
        #endif
    }
}

// MARK: - 添加 Toast 视图组件
struct ToastView: View {
    let message: String
    @Binding var isShowing: Bool
    
    var body: some View {
        Text(message)
            .font(.custom("SourceHanSerifCN-Heavy", size: 16))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(white: 0.2, opacity: 0.8))
            .foregroundColor(.white)
            .cornerRadius(20)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        isShowing = false
                    }
                }
            }
    }
}

// MARK: - 主视图
struct ContentView: View {
    @StateObject private var meritManager = MeritManager()
    @State private var showingSettings = false
    @State private var showingDesktopView = false
    @State private var isAnimating = false
    @State private var isHammerAnimating = false
    @State private var animatingScores: [(UUID, CGPoint)] = []
    @State private var showingToast = false
    @State private var toastMessage = ""
    
    private func playTapAnimation() {
        // 只有在应用处于前台时才触发震动
        if meritManager.isAppActive {
            // 添加震动反馈
            let impact = UIImpactFeedbackGenerator(style: .rigid) // 使用 rigid 风格，更接近敲击的感觉
            impact.prepare() // 提前准备可以减少延迟
            impact.impactOccurred(intensity: 0.8) // 可以调整强度，范围 0-1
        }
        
        // 现有的动画代码保持不变
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isAnimating = true
            isHammerAnimating = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                isAnimating = false
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                isHammerAnimating = false
            }
        }
        
        // 添加 +1 动画
        let woodfishTopY = UIScreen.main.bounds.height / 2
        let newScore = (UUID(), CGPoint(
            x: UIScreen.main.bounds.width / 2,
            y: woodfishTopY - 50
        ))
        animatingScores.append(newScore)
    }
    
    private func showToast(_ message: String) {
        toastMessage = message
        withAnimation {
            showingToast = true
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景色
                Color(hex: "F8F5E4").edgesIgnoringSafeArea(.all)
                
                // 主内容
                VStack {
                    // 顶部区域
                    HStack {
                        Spacer()
                        
                        // 添加到桌面按钮
                        Button(action: {
                            showingDesktopView = true
                        }) {
                            Text("添加到桌面")
                                .font(.custom("SourceHanSerifCN-Heavy", size: 18))
                                .foregroundColor(.brown)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .cornerRadius(20)
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 10)
                    }
                    
                    // 功德计数器
                    AnimatedNumberText(number: meritManager.merit)
                        .padding()
                    
                    Spacer()
                    
                    // 木鱼和木槌
                    ZStack {
                        Button(action: {
                            meritManager.merit += 1
                            meritManager.playSound()
                            playTapAnimation()
                        }) {
                            Image("woodfish")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                                .scaleEffect(isAnimating ? 0.9 : 1.0)
                        }
                        
                        // 木鱼槌动画
                        Image("hammer")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(isHammerAnimating ? -30 : 0))
                            .scaleEffect(isHammerAnimating ? 0.9 : 1.0)
                            .offset(x: 80, y: -50)
                    }
                    .padding()
                    
                    Spacer()
                    
                    // 底部按钮 - 自动/手动切换 (使用自定义 Segmented Controls)
                    HStack {
                        Spacer()
                        
                        // 自定义 Segmented Controls
                        ZStack {
                            // 背景
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: "E9E6D5"))
                                .frame(width: 184, height: 52)
                            
                            // 滑动的背景指示器 - 放在文字下方
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "D7CE9C"))
                                .frame(width: 88, height: 44)
                                .offset(x: meritManager.autoTapEnabled ? -44 : 44, y: 0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: meritManager.autoTapEnabled)
                            
                            // 文字按钮 - 放在背景上方
                            HStack(spacing: 0) {
                                // 自动按钮
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        meritManager.autoTapEnabled = true
                                    }
                                }) {
                                    Text("自动")
                                        .font(.custom("SourceHanSerifCN-Heavy", size: 18))
                                        .foregroundColor(Color(hex: "592424"))
                                        .frame(width: 80, height: 44)
                                        .padding(.horizontal, 4)
                                }
                                
                                // 手动按钮
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        meritManager.autoTapEnabled = false
                                    }
                                }) {
                                    Text("手动")
                                        .font(.custom("SourceHanSerifCN-Heavy", size: 18))
                                        .foregroundColor(Color(hex: "592424"))
                                        .frame(width: 80, height: 44)
                                        .padding(.horizontal, 4)
                                }
                            }
                        }
                        .frame(width: 184, height: 52)
                        
                        Spacer()
                    }
                    .padding(.bottom, 30)
                }
                
                // 左侧悬浮按钮组
                VStack(spacing: 16) {
                    // 设置按钮
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.brown)
                            .frame(width: 50, height: 50)
                            .background(Color(white: 0.9, opacity: 0.5))
                            .clipShape(Circle())
                    }
                    
                    // 静音按钮
                    Button(action: {
                        meritManager.soundEnabled.toggle()
                    }) {
                        Image(systemName: meritManager.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.brown)
                            .frame(width: 50, height: 50)
                            .background(Color(white: 0.9, opacity: 0.5))
                            .clipShape(Circle())
                    }
                    
                    // 重置按钮
                    Button(action: {
                        meritManager.resetMerit()
                        showToast("功德重置成功")
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 22))
                            .foregroundColor(.brown)
                            .frame(width: 50, height: 50)
                            .background(Color(white: 0.9, opacity: 0.5))
                            .clipShape(Circle())
                    }
                    
                    // 分享按钮
                    Button(action: {
                        let text = "我在「随身拜-木鱼功德」已经积累了\(meritManager.merit)功德！"
                        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
                        UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true)
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 22))
                            .foregroundColor(.brown)
                            .frame(width: 50, height: 50)
                            .background(Color(white: 0.9, opacity: 0.5))
                            .clipShape(Circle())
                    }
                }
                .padding(.leading, 20)
                .padding(.top, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                
                // Toast 提示
                if showingToast {
                    VStack {
                        Spacer()
                        ToastView(message: toastMessage, isShowing: $showingToast)
                            .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSettings) {
                SettingsView(meritManager: meritManager)
            }
            .fullScreenCover(isPresented: $showingDesktopView) {
                DesktopView()
            }
        }
        .navigationViewStyle(.stack)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AutoTapAnimation"))) { _ in
            playTapAnimation()
        }
        .overlay(
            ZStack {
                ForEach(animatingScores, id: \.0) { score in
                    AnimatedScoreText(
                        score: 1,
                        position: score.1
                    ) {
                        animatingScores.removeAll { $0.0 == score.0 }
                    }
                }
            }
        )
    }
}

// MARK: - 辅助扩展
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// 预览
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 

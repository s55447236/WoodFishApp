import SwiftUI
import BackgroundTasks
import WidgetKit

@main
struct WoodFishApp: App {
    init() {
        print("App initializing...")
        
        // 检查资源文件
        if UIImage(named: "woodfish") != nil {
            print("Woodfish image loaded successfully")
        } else {
            print("Failed to load woodfish image")
        }
        
        if UIImage(named: "hammer") != nil {
            print("Hammer image loaded successfully")
        } else {
            print("Failed to load hammer image")
        }
        
        // 检查字体
        if Bundle.main.urls(forResourcesWithExtension: "otf", subdirectory: nil) != nil {
            print("Font files found in bundle")
        } else {
            print("No font files found in bundle")
        }
        
        // 检查音频文件
        if Bundle.main.url(forResource: "woodfish", withExtension: "MP3") != nil {
            print("Found woodfish sound file")
        } else {
            print("Failed to find woodfish sound file")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    print("ContentView appeared")
                }
        }
    }
}

// 创建一个单独的类来管理后台任务
class BackgroundTaskManager: ObservableObject {
    static let shared = BackgroundTaskManager()
    
    func handleAppRefresh(task: BGAppRefreshTask) {
        // 安排下一次后台刷新
        scheduleAppRefresh()
        
        // 完成后台任务
        task.setTaskCompleted(success: true)
    }
    
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.xumengzhang.WoodFishApp.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15分钟后
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("无法安排后台任务: \(error)")
        }
    }
} 

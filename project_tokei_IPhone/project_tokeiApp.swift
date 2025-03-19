import SwiftUI
import Foundation

class AppearanceObserver: ObservableObject {
    @AppStorage("isDarkMode") var isDarkMode: Bool = false
    
    init() {
        // 초기 다크모드 상태 설정
        if #available(iOS 13.0, *) {
            isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        }
        
        // 앱이 활성화될 때마다 다크모드 상태 체크하도록 알림 등록
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateAppearance),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc func updateAppearance() {
        if #available(iOS 13.0, *) {
            isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        }
    }
}

// App 앱 종료 시 처리를 담당할 AppDelegate
class AppTerminationHandler: NSObject {
    static let shared = AppTerminationHandler()
    private override init() {
        super.init()
    }
    
    // 앱 종료 알림 등록
    func setupTerminationMonitoring() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
        print("앱 종료 모니터링 시작됨")
    }
    
    // 앱 종료 시 호출될 메서드
    @objc func appWillTerminate() {
        print("앱 종료 감지: 데이터 저장 메소드 호출")
        // 여기서는 아무것도 할 필요 없음 - 이미 UserDefaults에 저장되어 있음
    }
}

@main
struct project_tokeiApp: App {
    @StateObject private var appearanceObserver = AppearanceObserver()
    @StateObject private var scheduleManager = ScheduleManager()
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // 앱 종료 모니터링 설정
        AppTerminationHandler.shared.setupTerminationMonitoring()
        
        // 앱 시작 시 저장된 데이터 상태 확인 (디버깅용)
        SchedulePersistence.shared.printSavedData()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(scheduleManager)
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .inactive || newPhase == .background {
                // 앱이 백그라운드로 가거나 비활성화될 때 저장
                print("앱이 백그라운드로 전환: 모든 데이터 저장")
                SchedulePersistence.shared.saveSchedules(scheduleManager.getAllSchedules())
                
                // 확인을 위해 저장 후 데이터 상태 출력
                SchedulePersistence.shared.printSavedData()
            }
        }
    }
}

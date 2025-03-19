import SwiftUI
import Foundation

// 간단한 데이터 저장을 위한 클래스
class SchedulePersistence {
    static let shared = SchedulePersistence()
    
    // UserDefaults 키
    private let schedulesKey = "com.tokei.schedules"
    
    private init() {}
    
    // 일정 저장 (UserDefaults만 사용)
    func saveSchedules(_ schedulesByDate: [String: [Schedule]]) {
        do {
            // 저장용 딕셔너리 준비
            var storedData: [String: [[String: Any]]] = [:]
            
            for (date, schedules) in schedulesByDate {
                var scheduleDicts: [[String: Any]] = []
                
                for schedule in schedules {
                    // 색상을 문자열로 변환
                    let colorName: String
                    if schedule.color == .red { colorName = "red" }
                    else if schedule.color == .orange { colorName = "orange" }
                    else if schedule.color == .yellow { colorName = "yellow" }
                    else if schedule.color == .green { colorName = "green" }
                    else if schedule.color == .blue { colorName = "blue" }
                    else if schedule.color == .purple { colorName = "purple" }
                    else if schedule.color == .pink { colorName = "pink" }
                    else { colorName = "blue" }
                    
                    // 각 일정을 딕셔너리로 변환
                    let dict: [String: Any] = [
                        "id": schedule.id.uuidString,
                        "title": schedule.title,
                        "hour": schedule.hour,
                        "minutes": schedule.minutes,
                        "endHour": schedule.endHour,
                        "endMinutes": schedule.endMinutes,
                        "colorName": colorName
                    ]
                    scheduleDicts.append(dict)
                }
                
                storedData[date] = scheduleDicts
            }
            
            // JSON 데이터로 변환
            let jsonData = try JSONSerialization.data(withJSONObject: storedData, options: [])
            
            // UserDefaults에 저장
            UserDefaults.standard.set(jsonData, forKey: schedulesKey)
            UserDefaults.standard.synchronize() // 강제 동기화
            
            print("일정 저장 성공 (UserDefaults): \(schedulesByDate.count)일치 데이터")
        } catch {
            print("일정 저장 실패: \(error)")
        }
    }
    
    // 일정 불러오기 (UserDefaults에서만)
    func loadSchedules() -> [String: [Schedule]] {
        if let data = UserDefaults.standard.data(forKey: schedulesKey) {
            do {
                // JSON 데이터 파싱
                if let storedData = try JSONSerialization.jsonObject(with: data) as? [String: [[String: Any]]] {
                    var schedulesByDate: [String: [Schedule]] = [:]
                    
                    for (date, scheduleDicts) in storedData {
                        var schedules: [Schedule] = []
                        
                        for dict in scheduleDicts {
                            if let idString = dict["id"] as? String,
                               let title = dict["title"] as? String,
                               let hour = dict["hour"] as? Int,
                               let minutes = dict["minutes"] as? Int,
                               let endHour = dict["endHour"] as? Int,
                               let endMinutes = dict["endMinutes"] as? Int,
                               let colorName = dict["colorName"] as? String {
                                
                                // 문자열을 다시 Color로 변환
                                let color: Color
                                switch colorName {
                                case "red": color = .red
                                case "orange": color = .orange
                                case "yellow": color = .yellow
                                case "green": color = .green
                                case "blue": color = .blue
                                case "purple": color = .purple
                                case "pink": color = .pink
                                default: color = .blue
                                }
                                
                                // Schedule 객체 생성
                                var schedule = Schedule(
                                    title: title,
                                    hour: hour,
                                    minutes: minutes,
                                    endHour: endHour,
                                    endMinutes: endMinutes,
                                    color: color
                                )
                                
                                // ID 복원
                                if let uuid = UUID(uuidString: idString) {
                                    schedule.id = uuid
                                }
                                
                                schedules.append(schedule)
                            }
                        }
                        
                        schedulesByDate[date] = schedules
                    }
                    
                    print("일정 로드 성공 (UserDefaults): \(schedulesByDate.count)일치 데이터")
                    return schedulesByDate
                }
            } catch {
                print("일정 로드 실패: \(error)")
            }
        } else {
            print("저장된 일정 데이터가 없음 (UserDefaults)")
        }
        
        return [:]
    }
    
    // UserDefaults 저장 상태 확인 (디버깅용)
    func printSavedData() {
        if let data = UserDefaults.standard.data(forKey: schedulesKey) {
            print("저장된 데이터 크기: \(data.count) 바이트")
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("저장된 일자 수: \(json.keys.count)")
                    for key in json.keys {
                        print("- 일자: \(key)")
                    }
                }
            } catch {
                print("저장된 데이터 파싱 실패: \(error)")
            }
        } else {
            print("UserDefaults에 저장된 데이터 없음")
        }
    }
}

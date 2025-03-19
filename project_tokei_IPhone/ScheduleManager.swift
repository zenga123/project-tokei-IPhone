import SwiftUI

class ScheduleManager: ObservableObject {
    @Published var schedules: [Schedule] = []
    @Published var selectedDate: Date = Date()
    @Published var analysisResult: String? = nil
    private var schedulesByDate: [String: [Schedule]] = [:]
    private let analyzer: ScheduleAnalyzer
    private var hasAnalyzedCurrentSchedules = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    init() {
        let apiKey = "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"
        self.analyzer = ScheduleAnalyzer(apiKey: apiKey)
        
        // 저장된 일정 불러오기 (UserDefaults에서)
        schedulesByDate = SchedulePersistence.shared.loadSchedules()
        
        // 현재 날짜의 일정으로 초기화
        let dateKey = dateFormatter.string(from: selectedDate)
        schedules = schedulesByDate[dateKey] ?? []
        
        print("일정 로딩 완료: \(schedulesByDate.count)일치의 데이터, 오늘의 일정: \(schedules.count)개")
        
        // 2초 후에 한번 더 저장 (안정성을 위해)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.saveAllData()
        }
    }
    
    // 모든 일정 데이터 반환 (앱 종료 시 저장용)
    func getAllSchedules() -> [String: [Schedule]] {
        return schedulesByDate
    }
    
    // 명시적으로 호출하여 데이터 저장하기
    func saveAllData() {
        print("모든 데이터 명시적 저장 실행")
        SchedulePersistence.shared.saveSchedules(schedulesByDate)
    }
    
    func analyzeCurrentSchedules() {
        if schedules.isEmpty || !hasAnalyzedCurrentSchedules {
            analyzer.analyzeSchedule(schedules: schedules) { [weak self] result in
                DispatchQueue.main.async {
                    self?.analysisResult = result
                    if !(self?.schedules.isEmpty ?? true) {
                        self?.hasAnalyzedCurrentSchedules = true
                    }
                }
            }
        }
    }
    
    func addOrUpdateSchedule(_ newSchedule: Schedule) {
        let dateKey = dateFormatter.string(from: selectedDate)
        var currentSchedules = schedulesByDate[dateKey] ?? []
        
        if let index = currentSchedules.firstIndex(where: { $0.id == newSchedule.id }) {
            currentSchedules[index] = newSchedule
        } else {
            let newStartTime = newSchedule.hour * 60 + newSchedule.minutes
            let newEndTime = newSchedule.endHour * 60 + newSchedule.endMinutes
            
            let isOverlapping = currentSchedules.contains { existing in
                let existingStartTime = existing.hour * 60 + existing.minutes
                let existingEndTime = existing.endHour * 60 + existing.endMinutes
                
                // 정확히 끝나는 시간과 시작하는 시간이 같은 경우는 겹치지 않음으로 처리
                if newStartTime == existingEndTime || newEndTime == existingStartTime {
                    return false
                }
                
                // 24시간을 넘어가는 일정 처리
                if newEndTime < newStartTime {
                    // 새 일정이 자정을 넘기는 경우
                    if existingEndTime < existingStartTime {
                        // 기존 일정도 자정을 넘기는 경우 - 항상 겹침
                        return true
                    } else {
                        // 기존 일정이 자정을 넘기지 않는 경우
                        return (existingStartTime < newEndTime) || (existingEndTime > newStartTime)
                    }
                } else if existingEndTime < existingStartTime {
                    // 기존 일정이 자정을 넘기는 경우
                    return (newStartTime < existingEndTime) || (newEndTime > existingStartTime)
                } else {
                    // 두 일정 모두 자정을 넘기지 않는 일반적인 경우
                    return (newStartTime < existingEndTime) && (newEndTime > existingStartTime)
                }
            }
            
            if !isOverlapping {
                currentSchedules.append(newSchedule)
            }
        }
        
        currentSchedules.sort { s1, s2 in
            let time1 = s1.hour * 60 + s1.minutes
            let time2 = s2.hour * 60 + s2.minutes
            return time1 < time2
        }
        
        schedulesByDate[dateKey] = currentSchedules
        schedules = currentSchedules
        
        hasAnalyzedCurrentSchedules = false
        analysisResult = nil
        
        // 변경 후 저장
        print("일정 추가/수정 후 저장, 현재 일정 수: \(currentSchedules.count)")
        SchedulePersistence.shared.saveSchedules(schedulesByDate)
        
        // 추가로 전체 날짜 정보도 출력
        print("전체 날짜 데이터:")
        for (key, value) in schedulesByDate {
            print("- \(key): \(value.count)개의 일정")
        }
    }
    
    func changeDate(to date: Date) {
        selectedDate = date
        let dateKey = dateFormatter.string(from: date)
        schedules = schedulesByDate[dateKey] ?? []
        hasAnalyzedCurrentSchedules = false
        analysisResult = nil
        
        print("날짜 변경: \(dateKey), 일정 수: \(schedules.count)")
    }
    
    func removeSchedule(_ schedule: Schedule) {
        let dateKey = dateFormatter.string(from: selectedDate)
        if var currentSchedules = schedulesByDate[dateKey] {
            currentSchedules.removeAll { $0.id == schedule.id }
            schedulesByDate[dateKey] = currentSchedules
            schedules = currentSchedules
            
            hasAnalyzedCurrentSchedules = false
            analysisResult = nil
            
            // 삭제 후 저장
            print("일정 삭제 후 저장, 남은 일정 수: \(currentSchedules.count)")
            SchedulePersistence.shared.saveSchedules(schedulesByDate)
        }
    }
    
    func getSchedule(for hour: Int) -> Schedule? {
        return schedules.first { schedule in
            let startTime = Double(schedule.hour) + Double(schedule.minutes) / 60.0
            let endTime = Double(schedule.endHour) + Double(schedule.endMinutes) / 60.0
            let targetTime = Double(hour)
            
            if startTime < endTime {
                return targetTime >= startTime && targetTime < endTime
            } else {
                return targetTime >= startTime || targetTime < endTime
            }
        }
    }
    
    func hasTimeConflict(_ schedule: Schedule, excludingHour: Int? = nil) -> Bool {
        for existingSchedule in schedules {
            if let excludingHour = excludingHour,
               existingSchedule.hour == excludingHour {
                continue
            }
            
            let newStart = Double(schedule.hour) + Double(schedule.minutes) / 60.0
            let newEnd = Double(schedule.endHour) + Double(schedule.endMinutes) / 60.0
            let existingStart = Double(existingSchedule.hour) + Double(existingSchedule.minutes) / 60.0
            let existingEnd = Double(existingSchedule.endHour) + Double(existingSchedule.endMinutes) / 60.0
            
            if existingStart < existingEnd {
                if newStart < newEnd {
                    if !(newEnd <= existingStart || newStart >= existingEnd) {
                        return true
                    }
                } else {
                    if !(newEnd <= existingStart && newStart >= existingEnd) {
                        return true
                    }
                }
            } else {
                if newStart < newEnd {
                    if !(newEnd <= existingStart && newStart >= existingEnd) {
                        return true
                    }
                } else {
                    return true
                }
            }
        }
        return false
    }
}

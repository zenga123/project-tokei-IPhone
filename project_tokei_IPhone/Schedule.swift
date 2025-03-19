import SwiftUI

struct Schedule: Identifiable {
    var id = UUID()
    var title: String
    var hour: Int
    var minutes: Int
    var endHour: Int
    var endMinutes: Int
    var color: Color
    
    init(title: String = "", hour: Int = 0, minutes: Int = 0, endHour: Int? = nil, endMinutes: Int = 0, color: Color = .blue) {
        self.title = title
        self.hour = hour
        self.minutes = minutes
        // endHour가 nil이면 hour + 1을 계산 (23시면 0시로)
        self.endHour = endHour ?? (hour == 23 ? 0 : hour + 1)
        self.endMinutes = endMinutes
        self.color = color
    }
    
    init(hour: Int) {
        self.title = "제목 없는 일정"
        self.hour = hour
        self.minutes = 0
        self.endHour = (hour + 1) % 24
        self.endMinutes = 0
        self.color = .blue
    }
}

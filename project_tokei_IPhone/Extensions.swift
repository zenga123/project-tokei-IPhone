import SwiftUI

extension Schedule {
    func copy() -> Schedule {
        var newSchedule = Schedule(
            title: self.title,
            hour: self.hour,
            minutes: self.minutes,
            endHour: self.endHour,
            endMinutes: self.endMinutes,
            color: self.color
        )
        newSchedule.id = self.id
        return newSchedule
    }
}

// iOS 특화 확장
extension UIDevice {
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
}

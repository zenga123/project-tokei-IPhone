import SwiftUI

struct TimeSegmentView: View {
    let hour: Int
    @Binding var hoveredHour: Int?
    @ObservedObject var scheduleManager: ScheduleManager
    @Binding var selectedHour: Int?
    @Binding var isPopupPresented: Bool
    @Binding var currentSchedule: Schedule
    @Binding var hoveredExactTime: Double?
    @Binding var hoveredSchedule: Schedule?
    @Binding var checkedSchedules: Set<UUID>
    
    private func normalizeHour(_ hour: Int) -> Int {
        return (hour + 24) % 24
    }
    
    private func isSegmentInSchedule(_ hour: Int, _ schedule: Schedule) -> Bool {
        let segmentStart = Double(hour)
        let segmentEnd = Double(hour + 1)
        let scheduleStart = Double(schedule.hour) + Double(schedule.minutes) / 60.0
        let scheduleEnd = schedule.endHour == 0 ? 24.0 : Double(schedule.endHour) + Double(schedule.endMinutes) / 60.0
        
        if scheduleStart > scheduleEnd {
            return (segmentStart >= scheduleStart && segmentStart < 24.0) ||
                   (segmentStart >= 0 && segmentStart < scheduleEnd)
        }
        
        return (scheduleStart < segmentEnd) && (scheduleEnd > segmentStart)
    }
    
    private func calculateMiddleMinutes(_ schedule: Schedule) -> Double {
        let startTime = Double(schedule.hour) + Double(schedule.minutes) / 60.0
        let endTime = schedule.endHour == 0 ?
            24.0 : Double(schedule.endHour) + Double(schedule.endMinutes) / 60.0
        
        if endTime < startTime {
            let adjustedEndTime = endTime + 24.0
            let middleTime = startTime + (adjustedEndTime - startTime) / 2.0
            return middleTime >= 24.0 ? middleTime - 24.0 : middleTime
        }
        
        return startTime + (endTime - startTime) / 2.0
    }
    
    private func isExactTimeInSchedule(_ exactTime: Double, _ schedule: Schedule) -> Bool {
        let scheduleStart = Double(schedule.hour) + Double(schedule.minutes) / 60.0
        let scheduleEnd = schedule.endHour == 0 ?
            24.0 : Double(schedule.endHour) + Double(schedule.endMinutes) / 60.0
        
        if scheduleStart > scheduleEnd {
            return (exactTime >= scheduleStart && exactTime < 24.0) ||
                   (exactTime >= 0 && exactTime < scheduleEnd)
        }
        
        return exactTime >= scheduleStart && exactTime < scheduleEnd
    }
    
    private func getScheduledAndEmptyPaths(in geometry: GeometryProxy) -> (scheduled: [Path], empty: [Path]) {
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let radius = min(geometry.size.width, geometry.size.height) / 2
        
        var scheduledPaths: [Path] = []
        var emptyPaths: [Path] = []
        
        let segmentStart = hour * 60
        let segmentEnd = (hour + 1) * 60
        var currentMinute = Double(segmentStart)
        
        let segmentSchedules = scheduleManager.schedules
            .filter { schedule in
                let scheduleStart = schedule.hour * 60 + schedule.minutes
                let scheduleEnd = (schedule.endHour == 0 ? 24 : schedule.endHour) * 60 + schedule.endMinutes
                
                if scheduleEnd < scheduleStart {
                    return (scheduleStart <= segmentEnd) || (scheduleEnd >= segmentStart)
                }
                
                return (scheduleStart <= segmentEnd) && (scheduleEnd >= segmentStart)
            }
            .sorted { s1, s2 in
                let time1 = s1.hour * 60 + s1.minutes
                let time2 = s2.hour * 60 + s2.minutes
                return time1 < time2
            }
        
        for schedule in segmentSchedules {
            let scheduleStart = Double(schedule.hour * 60 + schedule.minutes)
            let scheduleEnd = Double((schedule.endHour == 0 ? 24 : schedule.endHour) * 60 + schedule.endMinutes)
            
            if currentMinute < scheduleStart && currentMinute < Double(segmentEnd) {
                let startAngle = (currentMinute / 4.0) - 90.0
                let endAngle = (min(scheduleStart, Double(segmentEnd)) / 4.0) - 90.0
                
                let emptyPath = Path { path in
                    path.move(to: center)
                    path.addArc(center: center,
                              radius: radius,
                              startAngle: Angle(degrees: startAngle),
                              endAngle: Angle(degrees: endAngle),
                              clockwise: false)
                    path.closeSubpath()
                }
                emptyPaths.append(emptyPath)
            }
            
            if scheduleStart < Double(segmentEnd) && scheduleEnd > Double(segmentStart) {
                let startAngle = (max(scheduleStart, Double(segmentStart)) / 4.0) - 90.0
                let endAngle = (min(scheduleEnd, Double(segmentEnd)) / 4.0) - 90.0
                
                let schedulePath = Path { path in
                    path.move(to: center)
                    path.addArc(center: center,
                              radius: radius,
                              startAngle: Angle(degrees: startAngle),
                              endAngle: Angle(degrees: endAngle),
                              clockwise: false)
                    path.closeSubpath()
                }
                scheduledPaths.append(schedulePath)
            }
            
            currentMinute = scheduleEnd
        }
        
        if currentMinute < Double(segmentEnd) {
            let startAngle = (currentMinute / 4.0) - 90.0
            let endAngle = (Double(segmentEnd) / 4.0) - 90.0
            
            let emptyPath = Path { path in
                path.move(to: center)
                path.addArc(center: center,
                          radius: radius,
                          startAngle: Angle(degrees: startAngle),
                          endAngle: Angle(degrees: endAngle),
                          clockwise: false)
                path.closeSubpath()
            }
            emptyPaths.append(emptyPath)
        }
        
        return (scheduledPaths, emptyPaths)
    }
    
    private func getSegmentStartTime() -> (hour: Int, minutes: Int) {
        let schedulesInSegment = scheduleManager.schedules.filter { schedule in
            let scheduleStart = schedule.hour * 60 + schedule.minutes
            let scheduleEnd = schedule.endHour * 60 + schedule.endMinutes
            let segmentStart = hour * 60
            let segmentEnd = (hour + 1) * 60
            
            return (scheduleStart >= segmentStart && scheduleStart < segmentEnd) ||
                   (scheduleEnd > segmentStart && scheduleEnd <= segmentEnd)
        }
        
        if let exactTime = hoveredExactTime {
            let mouseMinutes = (exactTime - floor(exactTime)) * 60
            let mouseTime = hour * 60 + Int(mouseMinutes)
            
            for schedule in schedulesInSegment {
                let scheduleStart = schedule.hour * 60 + schedule.minutes
                let scheduleEnd = schedule.endHour * 60 + schedule.endMinutes
                
                if mouseTime >= scheduleStart && mouseTime < scheduleEnd {
                    return (schedule.endHour, schedule.endMinutes)
                }
            }
            
            return (hour, 0)
        }
        
        return (hour, 0)
    }
    
    private func handleEmptySpaceClick(at startTime: (hour: Int, minutes: Int)) {
        let nextSchedule = scheduleManager.schedules.first { schedule in
            let scheduleStart = schedule.hour * 60 + schedule.minutes
            let clickedTime = startTime.hour * 60 + startTime.minutes
            return scheduleStart > clickedTime
        }
        
        let endHour: Int
        let endMinutes: Int
        
        if let next = nextSchedule {
            endHour = next.hour
            endMinutes = next.minutes
        } else {
            endHour = startTime.hour + 1
            endMinutes = 0
        }
        
        let newSchedule = Schedule(
            title: "",
            hour: startTime.hour,
            minutes: startTime.minutes,
            endHour: endHour,
            endMinutes: endMinutes,
            color: .blue
        )
        
        currentSchedule = newSchedule
        selectedHour = startTime.hour
        isPopupPresented = true
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                let paths = getScheduledAndEmptyPaths(in: geometry)
                
                ForEach(0..<paths.scheduled.count, id: \.self) { index in
                    let schedulesInSegment = scheduleManager.schedules.filter {
                        isSegmentInSchedule(hour, $0)
                    }
                    
                    if index < schedulesInSegment.count {
                        let schedule = schedulesInSegment[index]
                        paths.scheduled[index]
                            .fill(schedule.id == hoveredSchedule?.id ?
                                 schedule.color.opacity(0.7) :
                                 schedule.color.opacity(0.4))
                    }
                }
                
                ForEach(0..<paths.empty.count, id: \.self) { index in
                    paths.empty[index]
                        .fill(isHoveredEmpty(at: hoveredExactTime, index, paths.empty.count) ? Color.gray.opacity(0.2) : .clear)
                }
                
                ForEach(scheduleManager.schedules.filter { isSegmentInSchedule(hour, $0) }, id: \.id) { schedule in
                    let middleMinutes = calculateMiddleMinutes(schedule)
                    if Double(hour) == floor(middleMinutes) {
                        let middleAngle = middleMinutes * 15.0 - 90.0
                        Text(schedule.title)
                            .font(.system(size: 10))
                            .foregroundColor(.black)
                            .fixedSize()
                            .rotationEffect(.degrees(middleAngle))
                            .position(
                                x: geometry.size.width / 2 + cos(middleAngle * .pi / 180) * (geometry.size.width * 0.35),
                                y: geometry.size.height / 2 + sin(middleAngle * .pi / 180) * (geometry.size.height * 0.35)
                            )
                            .allowsHitTesting(false)
                    }
                }
            }
        }
    }
    
    private func isHoveredEmpty(at exactTime: Double?, _ index: Int, _ total: Int) -> Bool {
        guard let exactTime = exactTime,
              Int(floor(exactTime)) == hour,
              total > 0 else { return false }
        
        // 간소화된 확인 - 시간 세그먼트에 마우스가 올라와 있다면 빈 공간 강조
        return hoveredSchedule == nil
    }
    
    private func getEmptyTimeRanges() -> [(start: Int, end: Int)] {
        let segmentStart = hour * 60
        let segmentEnd = (hour + 1) * 60
        var ranges: [(start: Int, end: Int)] = []
        var currentTime = segmentStart
        
        let segmentSchedules = scheduleManager.schedules
            .filter { schedule in
                let scheduleStart = schedule.hour * 60 + schedule.minutes
                let scheduleEnd = schedule.endHour * 60 + schedule.endMinutes
                
                if scheduleEnd < scheduleStart {
                    return (scheduleStart < segmentEnd) || (scheduleEnd > segmentStart)
                }
                
                return (scheduleStart < segmentEnd && scheduleEnd > segmentStart)
            }
            .sorted { s1, s2 in
                let time1 = s1.hour * 60 + s1.minutes
                let time2 = s2.hour * 60 + s2.minutes
                return time1 < time2
            }
        
        for schedule in segmentSchedules {
            let scheduleStart = schedule.hour * 60 + schedule.minutes
            
            if currentTime < scheduleStart {
                ranges.append((start: currentTime, end: scheduleStart))
            }
            
            currentTime = schedule.endHour * 60 + schedule.endMinutes
            if currentTime < segmentStart {
                currentTime = segmentStart
            }
        }
        
        if currentTime < segmentEnd {
            ranges.append((start: currentTime, end: segmentEnd))
        }
        
        return ranges
    }
}

struct TimeSegmentShape: Shape {
    let hour: Int

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        let startAngle = Angle(degrees: Double(hour) * 15.0 - 90.0)
        let endAngle = Angle(degrees: Double(hour + 1) * 15.0 - 90.0)

        var path = Path()
        path.move(to: center)
        path.addArc(center: center,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false)
        path.closeSubpath()
        return path
    }
}

import SwiftUI

struct ClockView: View {
    let currentTime: Date
    @ObservedObject var scheduleManager: ScheduleManager
    @ObservedObject var recordingState: RecordingState
    @Binding var selectedHour: Int?
    @Binding var isPopupPresented: Bool
    @Binding var currentSchedule: Schedule
    @Binding var isChangingDate: Bool
    @Binding var checkedSchedules: Set<UUID>
    @State private var hoveredHour: Int? = nil
    @Environment(\.colorScheme) var colorScheme
    
    var calendar = Calendar.current
    
    private let yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月 d日"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    private var clockNumberColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var clockHandColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private func isToday(_ date: Date) -> Bool {
        return calendar.isDate(date, inSameDayAs: Date())
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 15) {
                Button(action: {}) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 32, height: 32)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(PlainButtonStyle())

                VStack(spacing: 2) {
                    Text(yearFormatter.string(from: currentTime))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                    Text(dateFormatter.string(from: currentTime))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)
                }

                Button(action: {}) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 32, height: 32)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, 15)
            .frame(maxHeight: 80)

            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 300, height: 300)
                
                ClockBase(scheduleManager: scheduleManager,
                          recordingState: recordingState,
                          hoveredHour: $hoveredHour,
                          selectedHour: $selectedHour,
                          isPopupPresented: $isPopupPresented,
                          currentSchedule: $currentSchedule,
                          isChangingDate: $isChangingDate,
                          checkedSchedules: $checkedSchedules,
                          currentTime: currentTime)
                
                ClockHands(currentTime: currentTime,
                          selectedHour: $selectedHour,
                          isPopupPresented: $isPopupPresented,
                          currentSchedule: $currentSchedule,
                          isChangingDate: $isChangingDate,
                          checkedSchedules: $checkedSchedules)
                    .opacity(isToday(scheduleManager.selectedDate) ? 1 : 0)
            }
            .frame(width: 300, height: 300)
            .padding(.top, 5)
            .padding(.bottom, 30)
        }
        .frame(width: 360, height: 420)
        .background(Color.white)
        .onAppear {
            print("Main view appeared")
        }
    }
}

struct ClockBase: View {
    @ObservedObject var scheduleManager: ScheduleManager
    @ObservedObject var recordingState: RecordingState
    @Binding var hoveredHour: Int?
    @Binding var selectedHour: Int?
    @Binding var isPopupPresented: Bool
    @Binding var currentSchedule: Schedule
    @Binding var isChangingDate: Bool
    @Binding var checkedSchedules: Set<UUID>
    let currentTime: Date
    var calendar = Calendar.current
    @State private var hoveredExactTime: Double? = nil
    @State private var hoveredSchedule: Schedule? = nil
    @State private var touchLocation: CGPoint? = nil
    
    private func isToday(_ date: Date) -> Bool {
        return calendar.isDate(date, inSameDayAs: Date())
    }
    
    var body: some View {
        ZStack {
            // 1. 시계 테두리
            Circle()
                .stroke(Color.gray, lineWidth: 2)
                .frame(width: 300, height: 300)

            // 2. 현재 시간까지의 회색 세그먼트
            Group {
                if calendar.compare(scheduleManager.selectedDate, to: Date(), toGranularity: .day) == .orderedAscending {
                    // 오늘 이전 날짜는 전체 원을 회색으로
                    Circle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 300, height: 300)
                } else if isToday(scheduleManager.selectedDate) {
                    let hours = Double(calendar.component(.hour, from: currentTime))
                    let minutes = Double(calendar.component(.minute, from: currentTime))
                    let currentHourWithMinutes = hours + minutes / 60
                    
                    // 완전히 지난 시간의 세그먼트들
                    ForEach(0..<Int(floor(currentHourWithMinutes)), id: \.self) { hour in
                        Path { path in
                            path.move(to: CGPoint(x: 150, y: 150))
                            let startAngle = Angle(degrees: Double(hour) * 15 - 90)
                            let endAngle = Angle(degrees: Double(hour + 1) * 15 - 90)
                            
                            path.addArc(
                                center: CGPoint(x: 150, y: 150),
                                radius: 150,
                                startAngle: startAngle,
                                endAngle: endAngle,
                                clockwise: false
                            )
                            path.closeSubpath()
                        }
                        .fill(Color.gray.opacity(0.5))
                    }
                    
                    // 현재 시간의 부분 세그먼트
                    Path { path in
                        path.move(to: CGPoint(x: 150, y: 150))
                        let currentHour = Int(floor(currentHourWithMinutes))
                        let startAngle = Angle(degrees: Double(currentHour) * 15 - 90)
                        let endAngle = Angle(degrees: (hours + minutes / 60) * 15 - 90)
                        
                        path.addArc(
                            center: CGPoint(x: 150, y: 150),
                            radius: 150,
                            startAngle: startAngle,
                            endAngle: endAngle,
                            clockwise: false
                        )
                        path.closeSubpath()
                    }
                    .fill(Color.gray.opacity(0.5))
                }
            }
            .animation(nil, value: scheduleManager.selectedDate)

            // 3. 시간 선
            ForEach(0..<24) { hour in
                ClockLine(hour: hour)
                    .stroke(Color.gray, lineWidth: 1)
                    .frame(width: 300, height: 300)
            }

            // 4. 시간 숫자
            ForEach(0..<24) { hour in
                ClockNumber(hour: hour)
                    .frame(width: 300, height: 300)
            }

            // 5. 시간 세그먼트
            ForEach(0..<24) { hour in
                TimeSegmentView(
                    hour: hour,
                    hoveredHour: $hoveredHour,
                    scheduleManager: scheduleManager,
                    selectedHour: $selectedHour,
                    isPopupPresented: $isPopupPresented,
                    currentSchedule: $currentSchedule,
                    hoveredExactTime: $hoveredExactTime,
                    hoveredSchedule: $hoveredSchedule,
                    checkedSchedules: $checkedSchedules
                )
            }

            // iOS용 터치 제스처를 위한 오버레이
            GeometryReader { geometry in
                Color.clear
                    .contentShape(Circle())
                    .onTapGesture { location in
                        // 탭 위치를 직접 계산
                        let tapLocation = CGPoint(
                            x: location.x,
                            y: location.y
                        )
                        
                        // 탭 위치에서 시간 계산
                        if let exactTime = getExactTime(from: tapLocation) {
                            let hour = Int(floor(exactTime)) % 24
                            hoveredHour = hour
                            hoveredExactTime = exactTime
                            
                            let touchTimeInMinutes = hour * 60 + Int((exactTime - floor(exactTime)) * 60)
                            
                            // 탭한 위치에 일정이 있는지 확인
                            let tappedSchedule = scheduleManager.schedules.first { schedule in
                                let scheduleStart = schedule.hour * 60 + schedule.minutes
                                let scheduleEnd = schedule.endHour * 60 + schedule.endMinutes
                                
                                if scheduleEnd < scheduleStart {
                                    return (touchTimeInMinutes >= scheduleStart && touchTimeInMinutes < 24 * 60) ||
                                           (touchTimeInMinutes >= 0 && touchTimeInMinutes < scheduleEnd)
                                }
                                
                                return touchTimeInMinutes >= scheduleStart && touchTimeInMinutes < scheduleEnd
                            }
                            
                            // 일정이 있으면 해당 일정 편집
                            if let schedule = tappedSchedule {
                                selectedHour = schedule.hour
                                currentSchedule = schedule.copy()
                                isPopupPresented = true
                            } else {
                                // 빈 시간이면 새 일정 추가
                                selectedHour = hour
                                
                                // 클릭한 시간대를 시작 시간으로, 그 다음 시간을 종료 시간으로 명시적 설정
                                let nextHour = hour == 23 ? 0 : hour + 1
                                
                                // 중요: 여기서 직접 구조체 필드 값을 설정
                                var newSchedule = Schedule()
                                newSchedule.title = ""
                                newSchedule.hour = hour
                                newSchedule.minutes = 0
                                newSchedule.endHour = nextHour
                                newSchedule.endMinutes = 0
                                newSchedule.color = .blue
                                
                                print("새 일정 직접 생성: 시작=\(hour)시, 종료=\(nextHour)시")
                                
                                // 바인딩 값을 직접 대입
                                currentSchedule = newSchedule
                                
                                // 디버깅 출력
                                print("currentSchedule 할당 직후: 시작=\(currentSchedule.hour)시, 종료=\(currentSchedule.endHour)시")
                                
                                // 팝업 표시
                                isPopupPresented = true
                            }
                        }
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let location = value.location
                                touchLocation = location
                                if let exactTime = getExactTime(from: location) {
                                    hoveredHour = Int(exactTime) % 24
                                    hoveredExactTime = exactTime
                                    
                                    let touchTimeInMinutes = Int(floor(exactTime)) * 60 + Int((exactTime - floor(exactTime)) * 60)
                                    
                                    hoveredSchedule = scheduleManager.schedules.first { schedule in
                                        let scheduleStart = schedule.hour * 60 + schedule.minutes
                                        let scheduleEnd = schedule.endHour * 60 + schedule.endMinutes
                                        
                                        if scheduleEnd < scheduleStart {
                                            return (touchTimeInMinutes >= scheduleStart && touchTimeInMinutes < 24 * 60) ||
                                                   (touchTimeInMinutes >= 0 && touchTimeInMinutes < scheduleEnd)
                                        }
                                        
                                        return touchTimeInMinutes >= scheduleStart && touchTimeInMinutes < scheduleEnd
                                    }
                                } else {
                                    hoveredHour = nil
                                    hoveredExactTime = nil
                                    hoveredSchedule = nil
                                }
                            }
                            .onEnded { _ in
                                touchLocation = nil
                            }
                    )
            }

            // 7. Recording progress (moved to top layer)
            if recordingState.isRecording, let startTime = recordingState.startTime {
                let startHour = Double(calendar.component(.hour, from: startTime))
                let startMinute = Double(calendar.component(.minute, from: startTime))
                let startAngle = ((startHour + startMinute / 60) * 15) - 90
                
                let currentHour = Double(calendar.component(.hour, from: currentTime))
                let currentMinute = Double(calendar.component(.minute, from: currentTime))
                let currentAngle = ((currentHour + currentMinute / 60) * 15) - 90
                
                Path { path in
                    path.move(to: CGPoint(x: 150, y: 150))
                    path.addArc(
                        center: CGPoint(x: 150, y: 150),
                        radius: 150,
                        startAngle: .init(degrees: startAngle),
                        endAngle: .init(degrees: currentAngle),
                        clockwise: false
                    )
                    path.closeSubpath()
                }
                .fill(Color.blue.opacity(0.3))
            }
        }
        .frame(width: 300, height: 300)
    }

    private func getExactTime(from location: CGPoint) -> Double? {
        let center = CGPoint(x: 150, y: 150)
        let dx = location.x - center.x
        let dy = location.y - center.y
        let distance = sqrt(dx * dx + dy * dy)
        
        if distance <= 150 {
            // atan2는 y축이 아래로 향하는 iOS 좌표계를 고려하여 수정
            var angleDegrees = atan2(-dy, dx) * 180.0 / Double.pi
            if angleDegrees < 0 {
                angleDegrees += 360
            }
            
            // 시계 방향으로 회전하는 각도 계산 (북쪽 = 0도, 동쪽 = 90도)
            let hourAngle = (90 - angleDegrees + 360).truncatingRemainder(dividingBy: 360)
            return hourAngle / 15.0
        }
        return nil
    }
    
    // 빈 시간 슬롯 계산
    private func getEmptyTimeSlots(for hour: Int) -> [(start: Int, end: Int)] {
        let segmentStart = hour * 60
        let segmentEnd = (hour + 1) * 60
        var slots: [(start: Int, end: Int)] = []
        var currentTime = segmentStart
        
        let segmentSchedules = scheduleManager.schedules
            .filter { schedule in
                let scheduleStart = schedule.hour * 60 + schedule.minutes
                let scheduleEnd = schedule.endHour == 0 ? 24 * 60 + schedule.endMinutes : schedule.endHour * 60 + schedule.endMinutes
                
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
                slots.append((start: currentTime, end: scheduleStart))
            }
            
            currentTime = schedule.endHour == 0 ? 24 * 60 + schedule.endMinutes : schedule.endHour * 60 + schedule.endMinutes
            if currentTime < segmentStart {
                currentTime = segmentStart
            }
        }
        
        if currentTime < segmentEnd {
            slots.append((start: currentTime, end: segmentEnd))
        }
        
        return slots
    }
}

struct ClockLine: Shape {
    let hour: Int

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let angle = CGFloat(hour) * .pi / 12 - .pi / 2
        let endPoint = CGPoint(
            x: center.x + (rect.width / 2) * cos(angle),
            y: center.y + (rect.height / 2) * sin(angle))
        var path = Path()
        path.move(to: center)
        path.addLine(to: endPoint)
        return path
    }
}

struct ClockNumber: View {
    let hour: Int
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            Text("\(hour)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .position(
                    x: center.x + (size.width / 2 + 10) * cos(CGFloat(hour) * .pi / 12 - .pi / 2),
                    y: center.y + (size.height / 2 + 10) * sin(CGFloat(hour) * .pi / 12 - .pi / 2)
                )
        }
    }
}

struct ClockHands: View {
    let currentTime: Date
    @Binding var selectedHour: Int?
    @Binding var isPopupPresented: Bool
    @Binding var currentSchedule: Schedule
    @Binding var isChangingDate: Bool
    @Binding var checkedSchedules: Set<UUID>
    @State private var opacity: Double = 1
    @State private var isFromCalendar: Bool = false
    @Environment(\.colorScheme) var colorScheme

    var calendar = Calendar.current

    var hour: Int {
        calendar.component(.hour, from: currentTime)
    }

    var minute: Int {
        calendar.component(.minute, from: currentTime)
    }

    var second: Double {
        let seconds = Double(calendar.component(.second, from: currentTime))
        let nanoseconds = Double(calendar.component(.nanosecond, from: currentTime)) / 1_000_000_000
        return seconds + nanoseconds
    }

    var body: some View {
        ZStack {
            // 시침
            Path { path in
                path.move(to: CGPoint(x: 150, y: 150))
                path.addLine(to: hourHand)
            }
            .stroke(colorScheme == .dark ? Color.white : Color.black, style: StrokeStyle(lineWidth: 4, lineCap: .round))

            // 초침
            Path { path in
                path.move(to: CGPoint(x: 150, y: 150))
                path.addLine(to: secondHand)
            }
            .stroke(Color.red, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))

            // 중심점
            Circle()
                .fill(colorScheme == .dark ? Color.white : Color.black)
                .frame(width: 8, height: 8)
        }
        .opacity(opacity)
    }

    var hourHand: CGPoint {
        let hours = Double(hour)
        let minutes = Double(minute)
        
        let hourAngle = ((hours + minutes / 60) * 15) - 90
        let hourAngleRadians = hourAngle * .pi / 180
        
        return CGPoint(
            x: 150 + 90 * cos(hourAngleRadians),
            y: 150 + 90 * sin(hourAngleRadians)
        )
    }

    var secondHand: CGPoint {
        let seconds = Double(calendar.component(.second, from: currentTime))
        let nanoseconds = Double(calendar.component(.nanosecond, from: currentTime)) / 1_000_000_000
        
        let totalSeconds = seconds + nanoseconds
        let secondAngle = (totalSeconds * 6) - 90
        let secondAngleRadians = secondAngle * .pi / 180
        
        return CGPoint(
            x: 150 + 120 * cos(secondAngleRadians),
            y: 150 + 120 * sin(secondAngleRadians)
        )
    }
}

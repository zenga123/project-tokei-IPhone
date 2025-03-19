import SwiftUI
import UIKit

// 중복 선언 제거 - RecordingState 및 FloatingRecordingIndicator는 이미 다른 파일에 있음

struct ContentView: View {
    @State private var currentTime = Date()
    @StateObject private var scheduleManager = ScheduleManager()
    @State private var selectedHour: Int? = nil
    @State private var hoveredHour: Int? = nil
    @State private var isPopupPresented = false
    @State private var currentSchedule = Schedule(title: "", hour: 0, minutes: 0)
    @State private var popoverAnchor: CGPoint = .zero
    @State private var showDatePicker = false
    @State private var leftOverlayOpacity: Double = 0
    @State private var rightOverlayOpacity: Double = 0
    @State private var isChangingDate: Bool = false
    @State private var scrollOffset: CGFloat = 0
    @State private var lastDragLocation: CGFloat?
    @State private var isDragging: Bool = false
    @State private var isWheelScrolling: Bool = false
    @State private var scrollVelocity: CGFloat = 0
    @AppStorage("isDarkMode") private var isDarkMode: Bool = UITraitCollection.current.userInterfaceStyle == .dark
    let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()
    @State private var checkedSchedules: Set<UUID> = []
    @State private var showCalendar = false
    @StateObject private var recordingState = RecordingState()
    @State private var showAnalysis = false
    
    init() {
        _isDarkMode = AppStorage(wrappedValue: UITraitCollection.current.userInterfaceStyle == .dark, "isDarkMode")
    }
    
    private var maxScrollOffset: CGFloat {
        let baseOffset: CGFloat = 50
        let additionalOffset = CGFloat(scheduleManager.schedules.count * 60)
        return baseOffset + additionalOffset
    }
    
    private let dragSensitivity: CGFloat = 1.5
    private let wheelSensitivity: CGFloat = 2.0
    private let elasticThreshold: CGFloat = 80
    
    private func applyBoundsWithElastic(_ proposedOffset: CGFloat) -> CGFloat {
        if proposedOffset > 0 {  // 위쪽 방향
            let elasticScale = 1 - min(proposedOffset / elasticThreshold, 0.6)
            return proposedOffset * elasticScale * 0.5
        } else if proposedOffset < -maxScrollOffset {  // 아래쪽 한계 초과
            let overscroll = abs(proposedOffset) - maxScrollOffset
            let elasticScale = 1 - min(overscroll / elasticThreshold, 0.6)
            return -(maxScrollOffset + (overscroll * elasticScale * 0.5))
        }
        return proposedOffset
    }
    
    private func updateScrollPosition(to newOffset: CGFloat, animated: Bool = true) {
        let boundedOffset = applyBoundsWithElastic(newOffset)
        
        if animated {
            withAnimation(.interpolatingSpring(stiffness: 150, damping: 15)) {
                scrollOffset = boundedOffset
            }
        } else {
            withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.8, blendDuration: 0.1)) {
                scrollOffset = boundedOffset
            }
        }
    }
    
    private func handleScrollEnd(velocity: CGFloat) {
        let projectedOffset = scrollOffset + (velocity * 0.2)
        
        withAnimation(.interpolatingSpring(stiffness: 150, damping: 15)) {
            if projectedOffset > 0 {
                scrollOffset = 0
            } else if projectedOffset < -maxScrollOffset {
                scrollOffset = -maxScrollOffset
            } else {
                scrollOffset = projectedOffset
            }
        }
    }
    
    private let yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月 d日"  // 포맷은 유지
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    private func isWeekend(_ date: Date) -> Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekday == 1 || weekday == 7  // 1은 일요일, 7은 토요일
    }

    private func isToday(_ date: Date) -> Bool {
        return Calendar.current.isDate(date, inSameDayAs: Date())
    }

    private func getHanjaWeekday(_ date: Date) -> String {
        let weekday = Calendar.current.component(.weekday, from: date)
        switch weekday {
        case 1: return " 日"
        case 2: return " 月"
        case 3: return " 火"
        case 4: return " 水"
        case 5: return " 木"
        case 6: return " 金"
        case 7: return " 土"
        default: return ""
        }
    }

    // 다크모드 관련 계산 속성들
    private var backgroundColor: Color {
        isDarkMode ? .black : .white
    }
    
    private var textColor: Color {
        isDarkMode ? .white : .black
    }
    
    private var buttonFillColor: Color {
        isDarkMode ? Color.white.opacity(0.8) : Color.black.opacity(0.8)
    }
    
    private var buttonIconColor: Color {
        isDarkMode ? .black : .white
    }
    
    private var buttonIcon: String {
        isDarkMode ? "sun.max.fill" : "moon.fill"
    }
    
    private var overlayColor: Color {
        isDarkMode ? Color.white.opacity(0.2) : Color.gray.opacity(0.2)
    }
    
    private var todayButtonStrokeColor: Color {
        isDarkMode ? .white : .blue
    }
    
    private var todayButtonIconColor: Color {
        isDarkMode ? .white : .blue
    }
    
    private var scheduleItemBackground: Color {
        isDarkMode ? Color.white.opacity(0.1) : Color.white
    }
    
    private var scheduleItemBorder: Color {
        isDarkMode ? Color.white.opacity(0.2) : Color.black.opacity(0.1)
    }
    
    private var scheduleCheckedBackground: Color {
        isDarkMode ? Color.white.opacity(0.05) : Color.gray.opacity(0.1)
    }
    
    private var scheduleTimeColor: Color {
        isDarkMode ? Color.white.opacity(0.6) : Color.gray
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 좌우 클릭 영역 (가장 아래 레이어)
                HStack(spacing: 0) {
                    // 왼쪽 영역
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if !isDragging {
                                leftOverlayOpacity = 1
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    if let newDate = Calendar.current.date(byAdding: .day, value: -1, to: scheduleManager.selectedDate) {
                                        scheduleManager.changeDate(to: newDate)
                                    }
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        leftOverlayOpacity = 0
                                    }
                                }
                            }
                        }
                        .overlay(
                            Rectangle()
                                .fill(overlayColor)
                                .opacity(leftOverlayOpacity)
                        )
                    
                    // 오른쪽 영역
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if !isDragging {
                                rightOverlayOpacity = 1
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    if let newDate = Calendar.current.date(byAdding: .day, value: 1, to: scheduleManager.selectedDate) {
                                        scheduleManager.changeDate(to: newDate)
                                    }
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        rightOverlayOpacity = 0
                                    }
                                }
                            }
                        }
                        .overlay(
                            Rectangle()
                                .fill(overlayColor)
                                .opacity(rightOverlayOpacity)
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(0)

                // 중앙 컨텐츠 (시계와 UI가 있는 레이어)
                VStack(spacing: 0) {
                    // 상단 날짜 부분
                    VStack(spacing: 2) {
                        HStack {
                            // 왼쪽에 다크모드 버튼과 동일한 크기의 투명한 공간 추가
                            Rectangle()
                                .fill(Color.clear)
                                .frame(width: 84, height: 32)  // 버튼 두 개의 너비(32*2) + 패딩(20)
                            
                            VStack(spacing: 2) {
                                Text(yearFormatter.string(from: scheduleManager.selectedDate))
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(textColor)
                                
                                Text(dateFormatter.string(from: scheduleManager.selectedDate) + getHanjaWeekday(scheduleManager.selectedDate))
                                    .font(.system(size: 22, weight: .bold))
                                    .lineLimit(1) // 줄바꿈 방지
                                    .minimumScaleFactor(0.8) // 필요시 크기 축소 허용
                                    .foregroundColor(isWeekend(scheduleManager.selectedDate) ? Color(red: 1.0, green: 0.0, blue: 0.0) : textColor)
                                    .onTapGesture {
                                        showCalendar = true
                                    }
                            }
                            .frame(maxWidth: .infinity)
                            
                            // 버튼 영역
                            HStack(spacing: 10) {
                                // AI 분석 버튼
                                Button(action: {
                                    scheduleManager.analyzeCurrentSchedules()
                                    showAnalysis = true
                                }) {
                                    Image(systemName: "brain")
                                        .font(.system(size: 14))
                                        .foregroundColor(buttonIconColor)
                                        .frame(width: 32, height: 32)
                                        .background(buttonFillColor)
                                        .clipShape(Circle())
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // 다크모드 토글 버튼
                                Button(action: {
                                    isDarkMode.toggle()
                                }) {
                                    Circle()
                                        .fill(buttonFillColor)
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Image(systemName: buttonIcon)
                                                .font(.system(size: 16))
                                                .foregroundColor(buttonIconColor)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 10)
                        
                        if !isToday(scheduleManager.selectedDate) {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isChangingDate = true
                                    scheduleManager.changeDate(to: Date())
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isChangingDate = false
                                    }
                                }
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(todayButtonStrokeColor, lineWidth: 0.8)
                                        .frame(width: 32, height: 28)
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 14))
                                        .foregroundColor(todayButtonIconColor)
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 20)
                    
                    // 시계 부분
                    ZStack {
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
                    .contentShape(Circle())
                    .padding(.vertical, 10)
                    .padding(.bottom, 30)
                    .zIndex(0)
                    .environment(\.colorScheme, isDarkMode ? .dark : .light)
                    
                    // 일정 목록 부분
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(scheduleManager.schedules.sorted { s1, s2 in
                            let time1 = s1.hour * 60 + s1.minutes
                            let time2 = s2.hour * 60 + s2.minutes
                            return time1 < time2
                        }) { schedule in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(schedule.title.isEmpty ? "제목 없는 일정" : schedule.title)
                                    .font(.system(size: 14, weight: .medium))
                                    .strikethrough(checkedSchedules.contains(schedule.id))
                                    .foregroundColor(textColor)
                                
                                HStack {
                                    Toggle("", isOn: Binding(
                                        get: { checkedSchedules.contains(schedule.id) },
                                        set: { isChecked in
                                            if isChecked {
                                                checkedSchedules.insert(schedule.id)
                                            } else {
                                                checkedSchedules.remove(schedule.id)
                                            }
                                        }
                                    ))
                                    .toggleStyle(CheckboxToggleStyle())
                                    
                                    Text(String(format: "%02d:%02d - %02d:%02d",
                                               schedule.hour,
                                               schedule.minutes,
                                               schedule.endHour,
                                               schedule.endMinutes))
                                        .font(.system(size: 12))
                                        .foregroundColor(scheduleTimeColor)
                                    
                                    Spacer()
                                    
                                    Circle()
                                        .fill(schedule.color)
                                        .frame(width: 10, height: 10)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(checkedSchedules.contains(schedule.id) ? scheduleCheckedBackground : scheduleItemBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(scheduleItemBorder, lineWidth: 0.5)
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            .padding(.horizontal, 8)
                            .onTapGesture {
                                if checkedSchedules.contains(schedule.id) {
                                    checkedSchedules.remove(schedule.id)
                                } else {
                                    checkedSchedules.insert(schedule.id)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .background(backgroundColor)
                }
                .frame(width: 300)
                .background(Color.clear)
                .zIndex(0)
                .offset(y: scrollOffset)
                .gesture(
                    DragGesture(minimumDistance: 5)
                        .onChanged { value in
                            // AI 분석 창이 열려있지 않을 때만 스크롤 허용
                            if !showAnalysis {
                                isDragging = true
                                
                                if lastDragLocation == nil {
                                    lastDragLocation = value.startLocation.y
                                }
                                
                                let dragDelta = (value.location.y - lastDragLocation!) * dragSensitivity
                                lastDragLocation = value.location.y
                                
                                let newOffset = scrollOffset + dragDelta
                                updateScrollPosition(to: newOffset, animated: false)
                            }
                        }
                        .onEnded { value in
                            if !showAnalysis {
                                let velocity = (value.predictedEndLocation.y - value.location.y) * dragSensitivity
                                handleScrollEnd(velocity: velocity)
                                lastDragLocation = nil
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    isDragging = false
                                }
                            }
                        }
                )
                .allowsHitTesting(!showAnalysis)  // AI 분석 창이 열려있을 때는 터치/클릭 비활성화

                if recordingState.isRecording {
                    VStack {
                        Spacer()
                        FloatingRecordingIndicator(recordingState: recordingState) {
                            stopRecording()
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(backgroundColor)
            .contentShape(Rectangle())
            .onAppear {
                // iOS에서는 스크롤 이벤트 처리가 다름
                // 키보드 이벤트 대신 제스처 또는 버튼 사용
                
                // UIDevice 방향 변경 알림 등록
                NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification,
                                                      object: nil,
                                                      queue: .main) { _ in
                    // 방향 변경 시 처리할 내용
                }
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .popover(isPresented: $isPopupPresented) {
            // currentSchedule에서 직접 시간 정보 사용
            SchedulePopupView(
                isPresented: $isPopupPresented,
                schedule: $currentSchedule,
                onSave: { schedule in
                    scheduleManager.addOrUpdateSchedule(schedule)
                },
                onDelete: {
                    scheduleManager.removeSchedule(currentSchedule)
                    isPopupPresented = false
                },
                startHour: hoveredHour ?? selectedHour ?? currentSchedule.hour,
                startMinutes: currentSchedule.minutes,
                endHour: currentSchedule.endHour,
                endMinutes: currentSchedule.endMinutes,
                scheduleManager: scheduleManager,
                initialSelectedHour: hoveredHour ?? selectedHour ?? currentSchedule.hour
            )
            .frame(width: 300)
            .padding()
        }
        .sheet(isPresented: $showAnalysis, content: {
            if let analysis = scheduleManager.analysisResult {
                ScheduleAnalysisView(analysis: analysis)
            }
        })
    }
    
    private func getInitialEndTime() -> (hour: Int, minutes: Int) {
        // 선택된 시간이 없으면 기본값으로 1시 반환
        let segmentStartHour = selectedHour ?? 0
        
        // 시작 시간의 다음 시간을 종료 시간으로 계산 (23시인 경우 0시로)
        let nextHour = segmentStartHour == 23 ? 0 : segmentStartHour + 1
        
        // 현재 세그먼트의 시간대에 겹치는 일정이 있는지 확인
        let scheduleInSegment = scheduleManager.schedules.first { schedule in
            let scheduleStart = schedule.hour * 60 + schedule.minutes
            let scheduleEnd = schedule.endHour == 0 ? 24 * 60 + schedule.endMinutes : schedule.endHour * 60 + schedule.endMinutes
            let segmentStart = segmentStartHour * 60
            let segmentEnd = (segmentStartHour + 1) * 60
            
            return (scheduleStart < segmentEnd && scheduleEnd > segmentStart)
        }
        
        // 시작 시간 이후에 가장 가까운 일정 찾기
        let nextSchedule = scheduleManager.schedules
            .sorted { s1, s2 in
                let time1 = s1.hour * 60 + s1.minutes
                let time2 = s2.hour * 60 + s2.minutes
                return time1 < time2
            }
            .first { schedule in
                let scheduleStart = schedule.hour * 60 + schedule.minutes
                let currentStart = segmentStartHour * 60
                return scheduleStart > currentStart
            }
        
        // 항상 기본 값은 다음 시간으로 설정 (segmentStartHour + 1)
        let result: (hour: Int, minutes: Int)
        
        if scheduleInSegment == nil {
            // 세그먼트에 일정이 없으면 다음 시간으로 설정
            result = (nextHour, 0)
        } else if let next = nextSchedule {
            // 다음 일정이 있으면 그 일정의 시작 시간으로 설정
            result = (next.hour, next.minutes)
        } else {
            // 세그먼트에 일정이 있지만 다음 일정이 없으면 다음 시간으로 설정
            result = (nextHour, 0)
        }
        
        return result
    }
    
    private func startRecording() {
        recordingState.startRecording()
    }
    
    private func stopRecording() {
        recordingState.stopRecording()
        
        // Create new schedule from recording
        if let startTime = recordingState.startTime,
           let endTime = recordingState.endTime {
            let calendar = Calendar.current
            let startHour = calendar.component(.hour, from: startTime)
            let startMinute = calendar.component(.minute, from: startTime)
            let endHour = calendar.component(.hour, from: endTime)
            let endMinute = calendar.component(.minute, from: endTime)
            
            currentSchedule = Schedule(
                title: "",
                hour: startHour,
                minutes: startMinute,
                endHour: endHour,
                endMinutes: endMinute,
                color: .blue
            )
            selectedHour = startHour  // 시작 시간을 selectedHour에 설정
            isPopupPresented = true
        }
    }
}

// iOS에서는 CheckboxToggleStyle 구현이 필요함(macOS의 NSButton과 달리 UIKit에는 기본 체크박스가 없음)
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? .blue : .gray)
                .onTapGesture {
                    configuration.isOn.toggle()
                }
            configuration.label
        }
    }
}

// iOS에서는 ScrollWheelView가 필요 없음 (ScrollView로 대체됨)

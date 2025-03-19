import SwiftUI

struct SchedulePopupView: View {
    @Binding var isPresented: Bool
    @Binding var schedule: Schedule
    var onSave: (Schedule) -> Void
    var onDelete: () -> Void
    let startHour: Int
    let startMinutes: Int
    let endHour: Int
    let endMinutes: Int
    @ObservedObject var scheduleManager: ScheduleManager
    let initialSelectedHour: Int
    @Environment(\.colorScheme) var colorScheme
    
    // 상태 변수들
    @State private var title: String = ""
    @State private var selectedStartHour: Int
    @State private var selectedStartMinute: Int
    @State private var selectedEndHour: Int
    @State private var selectedEndMinute: Int
    @State private var selectedColor: Color = .blue
    @State private var isFromRecording: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isInitialRendering: Bool = true
    
    private var isNewSchedule: Bool {
        schedule.title.isEmpty
    }
    
    private let colors: [(Color, String)] = [
        (.red, "빨강"),
        (.orange, "주황"),
        (.yellow, "노랑"),
        (.green, "초록"),
        (.blue, "파랑"),
        (.purple, "보라"),
        (.pink, "분홍")
    ]
    
    private var timeValidation: (isValid: Bool, message: String) {
        let startTotalMinutes = selectedStartHour * 60 + selectedStartMinute
        var endTotalMinutes = selectedEndHour * 60 + selectedEndMinute
        
        if selectedEndHour == 0 {
            endTotalMinutes = 24 * 60 + selectedEndMinute
        }
        
        if selectedStartHour == selectedEndHour && selectedStartMinute >= selectedEndMinute {
            return (false, "종료 시간이 시작 시간보다 늦어야 합니다")
        }
        
        if startTotalMinutes >= endTotalMinutes && selectedEndHour != 0 {
            return (false, "종료 시간이 시작 시간보다 늦어야 합니다")
        }
        
        return (true, "")
    }
    
    init(isPresented: Binding<Bool>,
         schedule: Binding<Schedule>,
         onSave: @escaping (Schedule) -> Void,
         onDelete: @escaping () -> Void,
         startHour: Int,
         startMinutes: Int,
         endHour: Int,
         endMinutes: Int,
         scheduleManager: ScheduleManager,
         initialSelectedHour: Int) {
        self._isPresented = isPresented
        self._schedule = schedule
        self.onSave = onSave
        self.onDelete = onDelete
        self.startHour = startHour
        self.startMinutes = startMinutes
        self.endHour = endHour
        self.endMinutes = endMinutes
        self.scheduleManager = scheduleManager
        self.initialSelectedHour = initialSelectedHour
        
        // 상태 변수 초기화
        _selectedStartHour = State(initialValue: startHour)
        _selectedStartMinute = State(initialValue: startMinutes)
        _selectedEndHour = State(initialValue: endHour)
        _selectedEndMinute = State(initialValue: endMinutes)
        _title = State(initialValue: schedule.wrappedValue.title)
        _selectedColor = State(initialValue: schedule.wrappedValue.color)
        
        // 녹음에서 온 것인지 확인 (정확한 분 단위)
        _isFromRecording = State(initialValue: startMinutes % 5 != 0 || endMinutes % 5 != 0)
    }
    
    private var isValidTimeRange: Bool {
        timeValidation.isValid
    }
    
    var body: some View {
        ZStack {
            // 배경색을 전체 화면에 적용
            (colorScheme == .dark ? Color.black : Color.white)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // 상단 여백 추가
                Spacer()
                    .frame(height: 40)
                
                ScrollView {
                    VStack(spacing: 30) {
                        Text(isNewSchedule ? "일정 추가" : "일정 수정")
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .padding(.top, 10)
                        
                        if showError {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.system(size: 14))
                        }
                        
                        TextField("제목 없는 일정", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .frame(height: 45)
                        
                        HStack {
                            Text("시작 시간")
                                .foregroundColor(.gray)
                            Spacer()
                            Picker("", selection: $selectedStartHour) {
                                ForEach(0..<24) { hour in
                                    Text(String(format: "%02d", hour))
                                        .tag(hour)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 60, height: 100)
                            .clipped()
                            .background(colorScheme == .dark ? Color.black : Color.white)
                            
                            Text(":")
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            if isFromRecording {
                                Picker("", selection: $selectedStartMinute) {
                                    Text(String(format: "%02d", startMinutes))
                                        .tag(startMinutes)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 60, height: 100)
                                .clipped()
                                .background(colorScheme == .dark ? Color.black : Color.white)
                            } else {
                                Picker("", selection: $selectedStartMinute) {
                                    ForEach(0..<12) { index in
                                        Text(String(format: "%02d", index * 5))
                                            .tag(index * 5)
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 60, height: 100)
                                .clipped()
                                .background(colorScheme == .dark ? Color.black : Color.white)
                            }
                        }
                        .padding(.horizontal)
                        
                        HStack {
                            Text("종료 시간")
                                .foregroundColor(.gray)
                            Spacer()
                            if isFromRecording {
                                Picker("", selection: $selectedEndHour) {
                                    Text(String(format: "%02d", endHour))
                                        .tag(endHour)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 60, height: 100)
                                .clipped()
                                .background(colorScheme == .dark ? Color.black : Color.white)
                            } else {
                                Picker("", selection: $selectedEndHour) {
                                    ForEach(0..<24) { hour in
                                        Text(String(format: "%02d", hour))
                                            .tag(hour)
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 60, height: 100)
                                .clipped()
                                .background(colorScheme == .dark ? Color.black : Color.white)
                            }
                            
                            Text(":")
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            if isFromRecording {
                                Picker("", selection: $selectedEndMinute) {
                                    Text(String(format: "%02d", endMinutes))
                                        .tag(endMinutes)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 60, height: 100)
                                .clipped()
                                .background(colorScheme == .dark ? Color.black : Color.white)
                            } else {
                                Picker("", selection: $selectedEndMinute) {
                                    ForEach(0..<12) { index in
                                        Text(String(format: "%02d", index * 5))
                                            .tag(index * 5)
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 60, height: 100)
                                .clipped()
                                .background(colorScheme == .dark ? Color.black : Color.white)
                            }
                        }
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("색상")
                                .foregroundColor(.gray)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(colors, id: \.1) { color, name in
                                        Button(action: {
                                            selectedColor = color
                                        }) {
                                            ZStack {
                                                Circle()
                                                    .fill(color)
                                                    .frame(width: 24, height: 24)
                                                if selectedColor == color {
                                                    Circle()
                                                        .strokeBorder(colorScheme == .dark ? Color.white : Color.black, lineWidth: 2)
                                                        .frame(width: 30, height: 30)
                                                    
                                                    // 추가 표시 - 선택된 색상에 흰색 테두리 + 그림자 효과
                                                    Circle()
                                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                                        .frame(width: 32, height: 32)
                                                        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 0)
                                                }
                                            }
                                        }
                                        .buttonStyle(.plain)
                                        .frame(width: 32, height: 32)
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        .padding(.horizontal)
                        
                        HStack {
                            Spacer()
                            
                            Button("취소") {
                                isPresented = false
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .frame(width: 90, height: 40)
                            
                            Spacer()
                                .frame(width: 20)
                            
                            Button(isNewSchedule ? "저장" : "수정") {
                                saveSchedule()
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .disabled(!isValidTimeRange)
                            .frame(width: 90, height: 40)
                            
                            Spacer()
                            
                            if !isNewSchedule {
                                Button("삭제") {
                                    onDelete()
                                    isPresented = false
                                }
                                .buttonStyle(.bordered)
                                .foregroundColor(.red)
                                .frame(width: 90, height: 40)
                            }
                        }
                        .padding(.top, 15)
                    }
                    .padding(.horizontal, 25)
                    .padding(.vertical, 20)
                }
                
                // 하단 여백 추가
                Spacer()
                    .frame(height: 60)
            }
        }
        .onAppear {
            // endHour 값을 올바르게 설정 (첫 화면에서 바로 보이도록)
            if isNewSchedule && selectedEndHour == 1 && selectedStartHour > 1 {
                DispatchQueue.main.async {
                    if selectedStartHour == 23 {
                        selectedEndHour = 0
                    } else {
                        selectedEndHour = selectedStartHour + 1
                    }
                }
            }
            
            // 컴포넌트가 처음 나타날 때만 실행되는 초기화 코드
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInitialRendering = false
            }
        }
        .onChange(of: selectedEndHour) { newEndHour in
            if !isFromRecording && !isInitialRendering {
                if newEndHour == selectedStartHour {
                    let startMinuteIndex = (selectedStartMinute / 5) + 1
                    selectedEndMinute = startMinuteIndex * 5
                }
            }
        }
        .onChange(of: selectedStartHour) { newStartHour in
            if !isFromRecording && !isInitialRendering {
                if selectedEndHour <= newStartHour && selectedEndHour != 0 {
                    if newStartHour == 23 {
                        selectedEndHour = 0
                    } else {
                        selectedEndHour = newStartHour + 1
                    }
                    selectedEndMinute = selectedStartMinute
                }
            }
        }
    }
    
    private func saveSchedule() {
        guard timeValidation.isValid else {
            showError = true
            return
        }
        
        var updatedSchedule = schedule
        updatedSchedule.title = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
            "제목 없는 일정" : title
        updatedSchedule.hour = selectedStartHour
        updatedSchedule.minutes = isFromRecording ? startMinutes : selectedStartMinute
        updatedSchedule.endHour = isFromRecording ? endHour : selectedEndHour
        updatedSchedule.endMinutes = isFromRecording ? endMinutes : selectedEndMinute
        updatedSchedule.color = selectedColor
        onSave(updatedSchedule)
        isPresented = false
    }
}

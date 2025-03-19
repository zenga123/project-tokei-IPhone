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
        
        // Initialize state variables
        _selectedStartHour = State(initialValue: startHour)
        _selectedStartMinute = State(initialValue: startMinutes)
        _selectedEndHour = State(initialValue: endHour)
        _selectedEndMinute = State(initialValue: endMinutes)
        _title = State(initialValue: schedule.wrappedValue.title)
        _selectedColor = State(initialValue: schedule.wrappedValue.color)
        
        // Check if this is from recording (exact minutes)
        _isFromRecording = State(initialValue: startMinutes % 5 != 0 || endMinutes % 5 != 0)
    }
    
    private var isValidTimeRange: Bool {
        timeValidation.isValid
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text(isNewSchedule ? "일정 추가" : "일정 수정")
                .font(.headline)
            
            if showError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.system(size: 14))
            }
            
            TextField("제목 없는 일정", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            HStack {
                Text("시작 시간")
                    .foregroundColor(.gray)
                Spacer()
                Picker("", selection: $selectedStartHour) {
                    ForEach(0..<24) { hour in
                        Text(String(format: "%02d", hour)).tag(hour)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(width: 60, height: 100)
                .clipped()
                
                Text(":")
                    .foregroundColor(.primary)
                
                if isFromRecording {
                    Picker("", selection: $selectedStartMinute) {
                        Text(String(format: "%02d", startMinutes)).tag(startMinutes)
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(width: 60, height: 100)
                    .clipped()
                } else {
                    Picker("", selection: $selectedStartMinute) {
                        ForEach(0..<12) { index in
                            Text(String(format: "%02d", index * 5)).tag(index * 5)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(width: 60, height: 100)
                    .clipped()
                }
            }
            .padding(.horizontal)
            
            HStack {
                Text("종료 시간")
                    .foregroundColor(.gray)
                Spacer()
                if isFromRecording {
                    Picker("", selection: $selectedEndHour) {
                        Text(String(format: "%02d", endHour)).tag(endHour)
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(width: 60, height: 100)
                    .clipped()
                } else {
                    Picker("", selection: $selectedEndHour) {
                        ForEach(0..<24) { hour in
                            Text(String(format: "%02d", hour)).tag(hour)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(width: 60, height: 100)
                    .clipped()
                }
                
                Text(":")
                    .foregroundColor(.primary)
                
                if isFromRecording {
                    Picker("", selection: $selectedEndMinute) {
                        Text(String(format: "%02d", endMinutes)).tag(endMinutes)
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(width: 60, height: 100)
                    .clipped()
                } else {
                    Picker("", selection: $selectedEndMinute) {
                        ForEach(0..<12) { index in
                            Text(String(format: "%02d", index * 5)).tag(index * 5)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(width: 60, height: 100)
                    .clipped()
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
                                            .strokeBorder(Color.white, lineWidth: 2)
                                            .frame(width: 30, height: 30)
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
                
                Button(isNewSchedule ? "저장" : "수정") {
                    saveSchedule()
                }
                .buttonStyle(.bordered)
                .disabled(!isValidTimeRange)
                
                Spacer()
                
                if !isNewSchedule {
                    Button("삭제") {
                        onDelete()
                        isPresented = false
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
            }
        }
        .padding()
        .onAppear {
            // 강제로 endHour 값을 올바르게 설정 (첫 화면에서 바로 보이도록)
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
    
    private func roundToNearestFiveMinutes(_ minutes: Int) -> Int {
        return (minutes / 5) * 5
    }
}

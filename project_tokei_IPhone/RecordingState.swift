import SwiftUI

class RecordingState: ObservableObject {
    @Published var isRecording = false
    @Published var startTime: Date?
    @Published var endTime: Date?
    
    func startRecording() {
        isRecording = true
        startTime = Date()
        endTime = nil
    }
    
    func stopRecording() {
        isRecording = false
        endTime = Date()
    }
}

struct FloatingRecordingIndicator: View {
    @ObservedObject var recordingState: RecordingState
    var onStop: () -> Void
    
    var body: some View {
        Button(action: onStop) {
            Text("⏺ 기록중")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red)
                .cornerRadius(15)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(8)
        .background(Color.black.opacity(0.8))
        .cornerRadius(20)
    }
}

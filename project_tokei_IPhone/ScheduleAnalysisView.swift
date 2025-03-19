import SwiftUI

struct ScheduleAnalysisView: View {
    let analysis: String
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            // 상단 헤더
            HStack {
                Text("AI 일정 분석")
                    .font(.headline)
                Spacer()
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding(.bottom)
            
            // 분석 내용
            ScrollView {
                Text(analysis)
                    .font(.body)
                    .lineSpacing(5)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.gray.opacity(0.1))
                    )
            }
            .frame(maxHeight: .infinity)
        }
        .padding()
        .frame(width: 300, height: 400)
        .background(colorScheme == .dark ? Color.black : Color.white)
        // 모달 시트의 상호작용을 이 뷰 내부로 제한
        .interactiveDismissDisabled()
    }
}

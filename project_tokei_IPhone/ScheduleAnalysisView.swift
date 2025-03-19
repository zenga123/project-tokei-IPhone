import SwiftUI

struct ScheduleAnalysisView: View {
    let analysis: String
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // 배경색을 다크모드에 따라 동적으로 설정
            (colorScheme == .dark ? Color.black : Color.white).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 15) {
                // 상단 여백 추가
                Spacer()
                    .frame(height: 50)
                
                // 상단 헤더
                HStack {
                    Text("AI 일정 분석")
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    Spacer()
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 22))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // 분석 내용
                ScrollView {
                    Text(analysis)
                        .font(.body)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .lineSpacing(5)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                        )
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                
                Spacer(minLength: 100) // 하단 공간 추가 확보
            }
            .padding(.vertical)
        }
        // iOS 15부터 사용 가능
// UIKit 스타일 적용을 위한 모디파이어
.onAppear {
    // 모달이 전체 화면으로 표시되도록 설정
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let controller = windowScene.windows.first?.rootViewController?.presentedViewController {
        controller.modalPresentationStyle = .fullScreen
    }
}
        .background(colorScheme == .dark ? Color.black : Color.white)
        .edgesIgnoringSafeArea(.all)
        .statusBar(hidden: false)
    }
}

#Preview {
    ScheduleAnalysisView(analysis: "주어진 일정이 하나뿐이기 때문에 상세한 분석은 어렵지만, 기상 시간이 1시간으로 설정되어 있습니다. 이는 충분한 휴식을 취하고 일어나기 위한 시간으로 보입니다. 시간 관리나 일정 배치에 대한 조언은 주어진 정보만으로는 어렵지만, 더 많은 일정이 주어진다면 효율적인 시간 관리와 우선순위를 고려하여 일정을 조정하는 것이 중요합니다. 기상 후에는 적절한 아침 루틴을 가지고 하루를 시작하는 것이 좋습니다.")
}

import SwiftUI

struct OCRView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("문제 스캔")
                .font(.largeTitle.bold())
            Text("지문이나 법률 조항이 가이드 영역 안에 들어오게 해주세요.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            RoundedRectangle(cornerRadius: 20)
                .fill(Color.blue.opacity(0.1))
                .frame(height: 320)
                .overlay {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.viewfinder")
                            .font(.system(size: 48))
                            .foregroundStyle(.blue)
                        Text("자동 초점 조정 중...")
                            .foregroundStyle(.secondary)
                    }
                }

            HStack(spacing: 12) {
                Button("취소") {}
                    .buttonStyle(.bordered)
                Button("촬영") {}
                    .buttonStyle(.borderedProminent)
            }
            Spacer()
        }
        .padding()
        .navigationTitle("OCR")
    }
}

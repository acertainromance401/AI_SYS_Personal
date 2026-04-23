import SwiftUI
import PhotosUI
import Vision

struct OCRView: View {
    @EnvironmentObject private var runtime: AppRuntimeState

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var recognizedText = ""
    @State private var isRecognizing = false
    @State private var ocrError: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("문제 스캔")
                    .font(.largeTitle.bold())
                Text("문제 이미지를 선택하면 OCR로 키워드를 추출해 판례 검색으로 넘깁니다.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.blue.opacity(0.1))
                    .frame(height: 220)
                    .overlay {
                        VStack(spacing: 12) {
                            Image(systemName: "doc.text.viewfinder")
                                .font(.system(size: 46))
                                .foregroundStyle(.blue)
                            Text(isRecognizing ? "텍스트 분석 중..." : "사진을 선택해 OCR 시작")
                                .foregroundStyle(.secondary)
                        }
                    }

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("사진 선택", systemImage: "photo")
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRecognizing)

                if let ocrError {
                    Text(ocrError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                if !recognizedText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("인식 결과")
                            .font(.headline)
                        Text(recognizedText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button {
                        runtime.pendingSearchQuery = compactQuery(from: recognizedText)
                        runtime.selectedTab = 2
                    } label: {
                        Label("검색 탭으로 이동", systemImage: "magnifyingglass")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .navigationTitle("OCR")
        .withSmallBackButton()
        .onChange(of: selectedPhoto) { newValue in
            guard let newValue else { return }
            Task {
                await recognize(item: newValue)
            }
        }
    }

    private func recognize(item: PhotosPickerItem) async {
        isRecognizing = true
        ocrError = nil
        defer { isRecognizing = false }

        guard let data = try? await item.loadTransferable(type: Data.self) else {
            ocrError = "이미지를 불러오지 못했습니다."
            return
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["ko-KR"]

        let handler = VNImageRequestHandler(data: data)
        do {
            try handler.perform([request])
            let lines = (request.results ?? [])
                .compactMap { $0.topCandidates(1).first?.string }
            recognizedText = lines.joined(separator: " ")
            if recognizedText.isEmpty {
                ocrError = "인식된 텍스트가 없습니다. 다른 사진으로 시도해 주세요."
            }
        } catch {
            ocrError = "OCR 처리 중 오류가 발생했습니다: \(error.localizedDescription)"
        }
    }

    private func compactQuery(from text: String) -> String {
        let cleaned = text
            .replacingOccurrences(of: "\n", with: " ")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return String(cleaned.prefix(80))
    }
}

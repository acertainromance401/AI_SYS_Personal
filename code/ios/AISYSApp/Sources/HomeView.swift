import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: ReviewStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("복습 대시보드")
                    .font(.largeTitle.bold())
                Text("합격을 위한 오늘의 우선순위 판례입니다.")
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Label("복습 효율 94%", systemImage: "sparkles")
                    Label("오늘 목표 12건", systemImage: "target")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Button("복습 시작") {}
                        .buttonStyle(.borderedProminent)
                    NavigationLink("판례 검색으로 이동") {
                        SearchView()
                    }
                    .buttonStyle(.bordered)
                }

                Text("오늘의 추천 복습")
                    .font(.title2.bold())
                Text("총 \(store.recommendedCases.count)건")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(store.recommendedCases) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.subject)
                            .font(.subheadline.bold())
                            .foregroundStyle(.blue)
                        Text(item.title)
                            .font(.headline)
                        Text("핵심 쟁점: \(item.issue)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("최근 정답률 \(item.accuracy)%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Text("최근 오답 노트")
                    .font(.title2.bold())
                Text("총 \(store.wrongAnswers.count)건")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(store.wrongAnswers) { wrong in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(wrong.title)
                            .font(.headline)
                        Text(wrong.memo)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(wrong.date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .navigationTitle("AI_SYS")
    }
}

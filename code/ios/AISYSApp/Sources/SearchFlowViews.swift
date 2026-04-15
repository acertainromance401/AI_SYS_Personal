import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var store: ReviewStore
    @StateObject private var viewModel = CaseSummaryViewModel()
    @State private var keyword = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("판례 통합 검색")
                    .font(.largeTitle.bold())
                Text("키워드, 사건번호 또는 문서 스캔으로 정밀한 판례 정보를 찾으세요.")
                    .foregroundStyle(.secondary)

                HStack {
                    TextField("키워드 검색", text: $keyword)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { Task { await viewModel.search(query: keyword) } }
                    Button {
                        Task { await viewModel.search(query: keyword) }
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isSearching || keyword.isEmpty)
                }

                Text("추천 키워드")
                    .font(.headline)
                HStack {
                    ForEach(["영장주의", "자백배제법칙", "위법수집증거"], id: \.self) { kw in
                        Button { keyword = kw; Task { await viewModel.search(query: kw) } }
                        label: { TagView(text: kw) }
                        .buttonStyle(.plain)
                    }
                }

                Text("검색 결과")
                    .font(.title3.bold())

                if viewModel.isSearching {
                    ProgressView("검색 중...").frame(maxWidth: .infinity)
                } else if let err = viewModel.errorMessage {
                    Text(err).foregroundStyle(.red).font(.subheadline)
                } else if viewModel.searchResults.isEmpty && !keyword.isEmpty {
                    Text("검색 결과가 없습니다. 다른 키워드로 시도해보세요.")
                        .font(.subheadline).foregroundStyle(.secondary)
                } else if !viewModel.searchResults.isEmpty {
                    ForEach(viewModel.searchResults) { apiCase in
                        NavigationLink {
                            CaseSummaryView(apiCase: apiCase, viewModel: viewModel)
                        } label: {
                            SearchResultCard(
                                title: apiCase.caseName,
                                subtitle: "\(apiCase.courtName)  \(apiCase.caseNumber)",
                                tags: apiCase.subject.isEmpty ? [] : ["#\(apiCase.subject)"],
                                summary: apiCase.issueSummary ?? ""
                            )
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    // 초기 상태: 더미 데이터 표시
                    let results = store.filteredResults(keyword: keyword)
                    ForEach(results) { item in
                        NavigationLink {
                            CaseSummaryView(detail: item.detail)
                        } label: {
                            SearchResultCard(
                                title: item.title,
                                subtitle: item.subtitle,
                                tags: item.tags,
                                summary: item.summary
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Search")
    }
}

struct CaseSummaryView: View {
    @EnvironmentObject private var store: ReviewStore
    // 실제 API 데이터 경로
    var apiCase: APICase? = nil
    @ObservedObject var viewModel: CaseSummaryViewModel = CaseSummaryViewModel()
    // 더미 데이터 폴백 경로
    var detail: CaseDetail? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let resolved = viewModel.displayDetail ?? detail {
                    Text(resolved.title).font(.largeTitle.bold())

                    // LLM 추론 진행 상态 표시
                    if viewModel.isSummarizing {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Llama가 판례를 분석 중입니다...")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }

                    InfoCard(title: "핵심 쟁점", detail: resolved.issue)
                    InfoCard(title: "판결 결론", detail: resolved.conclusion)
                    InfoCard(title: "시험 포인트", detail: resolved.examPoint)

                    if let err = viewModel.errorMessage {
                        Text(err).foregroundStyle(.red).font(.caption)
                    }

                    NavigationLink("관련 문제 보기") {
                        QuizView(question: store.sampleQuestion)
                    }
                    .buttonStyle(.borderedProminent)

                    if !resolved.similarCases.isEmpty {
                        Text("유사 판례 리스트").font(.title2.bold())
                        ForEach(resolved.similarCases, id: \.self) { item in
                            InfoCard(title: item, detail: "유사 쟁점 비교 학습용")
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("판례 요약")
        .task {
            if let c = apiCase {
                await viewModel.select(caseItem: c)
            }
        }
    }
}

struct QuizView: View {
    let question: QuizQuestion
    @State private var selected = 0
    @State private var checked = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("유사 사례 문제 풀이")
                    .font(.largeTitle.bold())
                Text(question.prompt)
                    .font(.headline)

                ForEach(Array(question.options.enumerated()), id: \.offset) { idx, option in
                    let number = idx + 1
                    Button {
                        selected = number
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(number)")
                                .font(.headline)
                                .frame(width: 30, height: 30)
                                .background(selected == number ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundStyle(selected == number ? .white : .primary)
                                .clipShape(Circle())
                            Text(option)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                        .padding()
                        .background(selected == number ? Color.teal.opacity(0.25) : Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }

                if checked {
                    let isCorrect = selected == question.correctIndex + 1
                    VStack(alignment: .leading, spacing: 8) {
                        Text(isCorrect ? "정답입니다" : "오답입니다")
                            .font(.headline)
                            .foregroundStyle(isCorrect ? .green : .red)
                        Text(question.explanation)
                            .font(.subheadline)
                        HStack {
                            ForEach(question.keywords, id: \.self) { keyword in
                                TagView(text: keyword)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button("정답 확인하기") {
                    checked = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(selected == 0)

                NavigationLink("오답 저장 및 복습") {
                    WrongAnswerSaveView(caseTitle: question.title)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("문제 풀이")
    }
}

struct WrongAnswerSaveView: View {
    @EnvironmentObject private var store: ReviewStore
    @Environment(\.dismiss) private var dismiss

    let caseTitle: String
    @State private var confusionPoint = ""
    @State private var memo = ""
    @State private var showSaved = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("오답 노트")
                    .font(.largeTitle.bold())
                Text(caseTitle)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                TextField("헷갈리는 지점", text: $confusionPoint)
                    .textFieldStyle(.roundedBorder)
                TextField("나만의 메모", text: $memo, axis: .vertical)
                    .lineLimit(4, reservesSpace: true)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Button("취소") { dismiss() }
                        .buttonStyle(.bordered)
                    Button("저장") {
                        let note = WrongAnswerNote(title: caseTitle, confusionPoint: confusionPoint, memo: memo)
                        store.saveWrongAnswer(note: note)
                        showSaved = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .alert("복습 목록에 추가되었습니다", isPresented: $showSaved) {
            Button("확인", role: .cancel) { dismiss() }
        }
        .navigationTitle("오답 저장")
    }
}

struct ReviewView: View {
    @EnvironmentObject private var store: ReviewStore

    var body: some View {
        List(store.wrongAnswers) { item in
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title).font(.headline)
                Text(item.memo).font(.subheadline).foregroundStyle(.secondary)
                Text(item.date).font(.caption).foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Review")
    }
}

struct MyPageView: View {
    var body: some View {
        Form {
            Section("계정") {
                Text("AI_SYS 사용자")
                Text("경찰 공무원 시험 준비")
            }
            Section("앱 정보") {
                Text("버전 1.0.0")
            }
        }
        .navigationTitle("My Page")
    }
}

private struct InfoCard: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(detail)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct SearchResultCard: View {
    let title: String
    let subtitle: String
    let tags: [String]
    let summary: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.blue)
            Text(title)
                .font(.headline)
            Text(summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                ForEach(tags, id: \.self) { tag in
                    TagView(text: tag)
                }
                Spacer()
                Text("상세보기")
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct TagView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.12))
            .clipShape(Capsule())
    }
}

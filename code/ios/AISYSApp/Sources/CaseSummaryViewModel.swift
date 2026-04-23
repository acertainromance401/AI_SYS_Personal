import Foundation

// MARK: - CaseSummaryViewModel
//
// 흐름:
//   1. SearchView에서 search(query:) 호출
//   2. NetworkService로 백엔드 /search API 호출 → APICase 목록 획득
//   3. 사용자가 결과 선택 → select(caseItem:) 호출
//   4. LLMService.summarize()로 온디바이스 Llama 추론
//   5. 결과를 CaseDetail로 변환해 SearchFlowViews에 표시

@MainActor
final class CaseSummaryViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var searchResults: [APICase] = []
    @Published private(set) var selectedCase: APICase?
    @Published private(set) var summary: LLMSummary?
    @Published private(set) var quizQuestion: QuizQuestion?

    @Published private(set) var isSearching = false
    @Published private(set) var isSummarizing = false
    @Published private(set) var isGeneratingQuiz = false
    @Published private(set) var llmState: LLMState = .idle
    @Published private(set) var errorMessage: String?
    @Published private(set) var backendConnected = false
    @Published private(set) var hasLoadedInitialCases = false

    // MARK: - Dependencies

    private let network: NetworkService
    private let llm: LLMService

    init(network: NetworkService, llm: LLMService) {
        self.network = network
        self.llm = llm

        // LLMService 상태를 미러링
        Task { [weak self] in
            guard let self else { return }
            for await state in llm.$state.values {
                self.llmState = state
            }
        }
    }

    convenience init() {
        self.init(network: .shared, llm: .shared)
    }

    // MARK: - Search

    /// 키워드/사건번호로 백엔드 검색
    func search(query: String) async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSearching = true
        errorMessage = nil
        defer { isSearching = false }
        do {
            searchResults = try await network.searchCases(query: query)
            backendConnected = true
        } catch {
            backendConnected = false
            errorMessage = error.localizedDescription
        }
    }

    /// 앱 시작 시 DB 기반 더미/시드 데이터를 우선 로드합니다.
    func loadInitialCasesIfNeeded() async {
        guard !hasLoadedInitialCases else { return }
        hasLoadedInitialCases = true
        isSearching = true
        defer { isSearching = false }

        backendConnected = await network.healthCheck()
        guard backendConnected else {
            return
        }

        do {
            searchResults = try await network.listCases(limit: 20)
        } catch {
            backendConnected = false
        }
    }

    // MARK: - Select + Summarize

    /// 검색 결과에서 판례를 선택하고 LLM 요약 시작
    func select(caseItem: APICase) async {
        selectedCase = caseItem
        summary = nil
        quizQuestion = nil
        guard await ensureModelReady() else { return }
        await performSummarize(caseItem: caseItem)
    }

    func generateQuizForSelectedCase() async {
        guard let caseItem = selectedCase else { return }
        errorMessage = nil
        quizQuestion = nil
        guard await ensureModelReady() else { return }
        await performQuizGeneration(caseItem: caseItem)
    }

    // MARK: - Computed Display Values

    var displayDetail: CaseDetail? {
        guard let c = selectedCase else { return nil }
        return c.toCaseDetail(llmSummary: summary)
    }

    var searchResultItems: [SearchResultItem] {
        searchResults.map { $0.toSearchResultItem() }
    }

    // MARK: - Private

    private func ensureModelReady() async -> Bool {
        switch llm.state {
        case .idle, .error:
            await llm.load()
        default:
            break
        }

        let deadline = Date().addingTimeInterval(12)
        while Date() < deadline {
            switch llm.state {
            case .ready:
                return true
            case .idle, .error:
                await llm.load()
            case .loading, .inferring:
                try? await Task.sleep(nanoseconds: 120_000_000)
            }
        }

        errorMessage = "LLM 초기화가 지연되고 있습니다. 잠시 후 다시 시도해주세요."
        return false
    }

    private func performSummarize(caseItem: APICase) async {
        isSummarizing = true
        defer { isSummarizing = false }
        do {
            summary = try await llm.summarize(caseItem: caseItem)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func performQuizGeneration(caseItem: APICase) async {
        isGeneratingQuiz = true
        defer { isGeneratingQuiz = false }
        do {
            quizQuestion = try await llm.generateQuiz(caseItem: caseItem, summary: summary)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

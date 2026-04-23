import Foundation

// MARK: - LLM State

enum LLMState: Equatable {
    case idle
    case loading(progress: Double)
    case ready
    case inferring
    case error(String)
}

// MARK: - LLM Errors

enum LLMError: LocalizedError {
    case notReady
    case outputParsingFailed

    var errorDescription: String? {
        switch self {
        case .notReady: return "LLM 엔진이 준비되지 않았습니다."
        case .outputParsingFailed:  return "LLM 출력 파싱에 실패했습니다."
        }
    }
}

// MARK: - LLMService
//
// 역할: MLX 없이 로컬 요약/퀴즈 생성을 제공합니다.
// 추후 llama.cpp/CoreML 엔진으로 교체할 때 인터페이스는 그대로 유지합니다.

@MainActor
final class LLMService: ObservableObject {
    static let shared = LLMService()

    @Published private(set) var state: LLMState = .idle
    @Published private(set) var loadProgress: Double = 0
    @Published private(set) var activeEngineName: String = "준비 전"

    private let primaryEngine: LocalLLMEngine
    private let fallbackEngine: LocalLLMEngine
    private var useFallback = true

    private init(
        primaryEngine: LocalLLMEngine = LlamaCppEngine(),
        fallbackEngine: LocalLLMEngine = RuleBasedLocalEngine()
    ) {
        self.primaryEngine = primaryEngine
        self.fallbackEngine = fallbackEngine
    }

    // MARK: - Model Loading

    func loadModelIfNeeded() async {
        guard case .idle = state else { return }
        await load()
    }

    func load() async {
        state = .loading(progress: 0)
        for step in [0.2, 0.45, 0.7] {
            loadProgress = step
            state = .loading(progress: step)
            try? await Task.sleep(nanoseconds: 60_000_000)
        }

        do {
            try await primaryEngine.loadModel()
            useFallback = false
            activeEngineName = primaryEngine.name
        } catch {
            // llama.cpp 연결 전 단계에서는 폴백 엔진으로 즉시 전환
            try? await fallbackEngine.loadModel()
            useFallback = true
            activeEngineName = fallbackEngine.name
        }

        loadProgress = 1.0
        state = .ready
    }

    // MARK: - Inference

    /// 판례 데이터를 받아 LLM 요약(LLMSummary)을 생성합니다.
    func summarize(caseItem: APICase) async throws -> LLMSummary? {
        guard case .ready = state else { throw LLMError.notReady }

        state = .inferring
        defer {
            if case .inferring = state { state = .ready }
        }

        let prompt = LLMPromptTemplate.summarize(
            caseNumber: caseItem.caseNumber,
            caseName: caseItem.caseName,
            issue: caseItem.issueSummary ?? "",
            holding: caseItem.holdingSummary ?? "",
            examPoints: caseItem.examPoints ?? ""
        )

        let rawOutput = try await activeEngine.generate(prompt: prompt, maxTokens: 256)
        if let summary = LLMSummary(rawOutput: rawOutput) {
            return summary
        }

        // 모델 출력 형식이 달라도 UX가 깨지지 않도록 안전 폴백
        let fallbackRaw = buildSummaryOutput(caseItem: caseItem)
        return LLMSummary(rawOutput: fallbackRaw)
    }

    /// 판례 데이터를 받아 객관식 퀴즈를 생성합니다.
    func generateQuiz(caseItem: APICase, summary: LLMSummary?) async throws -> QuizQuestion {
        guard case .ready = state else { throw LLMError.notReady }

        state = .inferring
        defer {
            if case .inferring = state { state = .ready }
        }

        let issue = summary?.keyIssue ?? caseItem.issueSummary ?? ""
        let holding = summary?.rulingPoint ?? caseItem.holdingSummary ?? ""
        let examTakeaway = summary?.examTakeaway ?? caseItem.examPoints ?? ""
        let evidenceBlock = """
        [1] \(caseItem.caseNumber) \(caseItem.caseName)
        쟁점: \(issue)
        결론: \(holding)
        시험포인트: \(examTakeaway)
        """
        let prompt = LLMPromptTemplate.quiz(
            question: "해당 판례의 핵심 쟁점과 시험 포인트를 점검하는 객관식 문제를 만들어라.",
            evidenceBlock: evidenceBlock
        )

        do {
            let rawOutput = try await activeEngine.generate(prompt: prompt, maxTokens: 320)
            if let question = QuizQuestion(
                rawOutput: rawOutput,
                title: caseItem.caseName,
                fallbackKeywords: [caseItem.caseNumber, caseItem.subject].filter { !$0.isEmpty }
            ) {
                return question
            }
        } catch {
            return buildFallbackQuiz(caseItem: caseItem, summary: summary)
        }

        return buildFallbackQuiz(caseItem: caseItem, summary: summary)
    }

    /// 두 판례를 비교 분석합니다.
    func compare(question: String, cases: [APICase]) async throws -> String {
        guard case .ready = state else { throw LLMError.notReady }

        state = .inferring
        defer {
            if case .inferring = state { state = .ready }
        }

        let evidenceBlock = cases.enumerated().map { idx, c in
            "[\(idx + 1)] \(c.caseNumber) \(c.caseName)\n쟁점: \(c.issueSummary ?? "")\n결론: \(c.holdingSummary ?? "")"
        }.joined(separator: "\n\n")
        let prompt = LLMPromptTemplate.compare(question: question, evidenceBlock: evidenceBlock)

        do {
            return try await activeEngine.generate(prompt: prompt, maxTokens: 320)
        } catch {
            return buildComparisonOutput(question: question, cases: cases)
        }
    }

    // MARK: - Private

    private func buildSummaryOutput(caseItem: APICase) -> String {
        let issue = caseItem.issueSummary ?? "주요 쟁점 정보가 부족합니다"
        let holding = caseItem.holdingSummary ?? "판결 결론 정보가 부족합니다"
        let examPoint = caseItem.examPoints ?? "시험 포인트 정보가 부족합니다"

        return """
        - one_line_summary: \(caseItem.caseName)은(는) \(issue) 중심으로 판단한 판례입니다.
        - key_issue: \(issue)
        - ruling_point: \(holding)
        - exam_takeaway: \(examPoint)
        """
    }

    private func buildComparisonOutput(question: String, cases: [APICase]) -> String {
        if cases.isEmpty {
            return "비교할 판례 데이터가 없습니다."
        }

        let list = cases.map { c in
            "- \(c.caseNumber) \(c.caseName): \(c.issueSummary ?? "쟁점 정보 없음")"
        }.joined(separator: "\n")

        return """
        질문: \(question)
        엔진: \(activeEngineName)

        공통/차이 비교 초안:
        \(list)

        정리: 사건번호별 핵심 쟁점을 기준으로 공통점과 차이점을 확인하세요.
        """
    }

    private func buildFallbackQuiz(caseItem: APICase, summary: LLMSummary?) -> QuizQuestion {
        let issue = summary?.keyIssue ?? caseItem.issueSummary ?? "쟁점 정보 없음"
        let holding = summary?.rulingPoint ?? caseItem.holdingSummary ?? "결론 정보 없음"
        let examTakeaway = summary?.examTakeaway ?? caseItem.examPoints ?? "시험 포인트 정보 없음"
        let wrongOption = "쟁점과 무관하게 결론만 외워도 동일한 판단이 가능하다"

        return QuizQuestion(
            title: caseItem.caseName,
            prompt: "다음 중 \(caseItem.caseName) 판례 학습 포인트로 가장 부적절한 것을 고르시오.",
            options: [issue, holding, examTakeaway, wrongOption],
            correctIndex: 3,
            explanation: "해당 판례 학습은 쟁점, 결론, 시험 포인트를 함께 이해해야 하며 결론만 암기하는 접근은 부적절합니다.",
            keywords: [caseItem.caseNumber, caseItem.subject].filter { !$0.isEmpty }
        )
    }

    private var activeEngine: LocalLLMEngine {
        useFallback ? fallbackEngine : primaryEngine
    }
}

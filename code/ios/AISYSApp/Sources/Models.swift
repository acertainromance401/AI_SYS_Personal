import Foundation

// MARK: - Backend API Models

/// FastAPI 백엔드 /search 및 /cases/{caseNumber} 응답 모델
struct APICase: Codable, Identifiable {
    let id: String
    let caseNumber: String
    let caseName: String
    let courtName: String
    let subject: String
    let issueSummary: String?
    let holdingSummary: String?
    let examPoints: String?
    let sourceUrl: String?

    /// LLM 요약 결과를 적용해 기존 CaseDetail로 변환
    func toCaseDetail(llmSummary: LLMSummary? = nil) -> CaseDetail {
        CaseDetail(
            title: caseName,
            issue: llmSummary?.keyIssue ?? issueSummary ?? "쟁점 정보 없음",
            conclusion: llmSummary?.rulingPoint ?? holdingSummary ?? "결론 정보 없음",
            examPoint: llmSummary?.examTakeaway ?? examPoints ?? "시험 포인트 없음",
            similarCases: []
        )
    }

    /// 더미 데이터가 들어있을 때 SearchResultItem으로 변환
    func toSearchResultItem(llmSummary: LLMSummary? = nil) -> SearchResultItem {
        SearchResultItem(
            subtitle: "\(courtName) \(caseNumber)",
            title: caseName,
            summary: llmSummary?.oneLineSummary ?? issueSummary ?? "",
            tags: subject.isEmpty ? [] : ["#\(subject)"],
            detail: toCaseDetail(llmSummary: llmSummary)
        )
    }
}

// MARK: - LLM Output Model

/// PromptTemplates.summarize 출력을 파싱한 결과
struct LLMSummary: Equatable {
    let oneLineSummary: String
    let keyIssue: String
    let rulingPoint: String
    let examTakeaway: String

    /// LLM raw 텍스트에서 "- key: value" 패턴을 파싱
    init?(rawOutput: String) {
        func extract(_ key: String) -> String? {
            guard let range = rawOutput.range(
                of: #"- \#(key):\s*(.+)"#,
                options: .regularExpression
            ) else { return nil }
            return String(rawOutput[range])
                .components(separatedBy: ": ")
                .dropFirst()
                .joined(separator: ": ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard
            let one = extract("one_line_summary"),
            let issue = extract("key_issue"),
            let ruling = extract("ruling_point"),
            let exam = extract("exam_takeaway")
        else { return nil }
        self.oneLineSummary = one
        self.keyIssue = issue
        self.rulingPoint = ruling
        self.examTakeaway = exam
    }
}

struct CaseStudy: Identifiable, Equatable {
    let id = UUID()
    let subject: String
    let title: String
    let issue: String
    let accuracy: Int
}

struct WrongAnswerItem: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let memo: String
    let date: String
}

struct WrongAnswerNote: Equatable {
    let title: String
    let confusionPoint: String
    let memo: String
}

struct SearchResultItem: Identifiable, Equatable {
    let id = UUID()
    let subtitle: String
    let title: String
    let summary: String
    let tags: [String]
    let detail: CaseDetail
}

struct CaseDetail: Equatable {
    let title: String
    let issue: String
    let conclusion: String
    let examPoint: String
    let similarCases: [String]
}

struct QuizQuestion: Equatable {
    let title: String
    let prompt: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
    let keywords: [String]
}

final class ReviewStore: ObservableObject {
    @Published var recommendedCases: [CaseStudy] = [
        CaseStudy(subject: "형사소송법", title: "강제채혈과 사후영장 주의", issue: "의사능력 없는 피의자의 혈액 채취 절차", accuracy: 35),
        CaseStudy(subject: "경찰학", title: "경찰관 직무집행법 제2조", issue: "위험 방지를 위한 출입 권한의 한계", accuracy: 52),
        CaseStudy(subject: "형법", title: "공범과 신분 (제33조)", issue: "진정신분범과 부진정신분범의 구별", accuracy: 68),
        CaseStudy(subject: "형사소송법", title: "긴급체포 후 압수수색의 허용 범위", issue: "사후영장 청구 전 압수수색의 한계", accuracy: 47),
        CaseStudy(subject: "헌법", title: "영장주의 예외와 필요최소한 원칙", issue: "강제처분의 비례성 및 최소침해 판단", accuracy: 59),
        CaseStudy(subject: "경찰학", title: "불심검문 적법성 판단 기준", issue: "거부 의사와 임의동행의 실질적 강제성", accuracy: 41),
        CaseStudy(subject: "형법", title: "정당방위와 과잉방위의 경계", issue: "방위행위의 상당성 및 현재성 판단", accuracy: 63)
    ]

    @Published var wrongAnswers: [WrongAnswerItem] = [
        WrongAnswerItem(title: "대법원 2023.01.12 선고 2022도12345", memo: "재산권과 증거능력 판단 기준", date: "2024.05.20"),
        WrongAnswerItem(title: "경찰관의 정당한 직무집행 여부 판단 기준", memo: "사후적 관점이 아닌 당시 상황 기준", date: "2024.05.19"),
        WrongAnswerItem(title: "주거침입죄 성립 여부 판단", memo: "사실상 주거의 평온 침해 여부 기준", date: "2024.05.18"),
        WrongAnswerItem(title: "대법원 2022.11.30 선고 2021도14123", memo: "긴급체포 직후 전자정보 압수의 허용 범위", date: "2024.05.17"),
        WrongAnswerItem(title: "위법수집증거 배제법칙의 예외", memo: "독수독과 예외와 인과관계 단절 요건", date: "2024.05.16"),
        WrongAnswerItem(title: "체포현장 휴대전화 임의제출의 진정성", memo: "임의성 인정 기준과 고지의무", date: "2024.05.15"),
        WrongAnswerItem(title: "공동정범의 기능적 행위지배", memo: "현장 부재 공범의 성립 가능성", date: "2024.05.14")
    ]

    @Published var searchResults: [SearchResultItem] = [
        SearchResultItem(
            subtitle: "대법원 2022. 5. 12. 선고 2021도16503",
            title: "강제추행죄에서의 폭행 또는 협박의 의미 및 판단 기준",
            summary: "피해자의 항거를 곤란하게 할 정도의 유형력 행사 여부를 중심으로 판단",
            tags: ["#강제추행", "#폭행협박"],
            detail: CaseDetail(
                title: "강제추행죄의 폭행·협박 판단 법리",
                issue: "폭행 또는 협박이 추행행위와 결합될 때 성립 기준",
                conclusion: "객관적으로 항거를 곤란하게 할 수준의 폭행·협박이면 성립 가능",
                examPoint: "행위 태양과 당시 상황을 종합해 정당방위와 구분",
                similarCases: ["대법원 2021도12630", "대법원 2009도5732"]
            )
        ),
        SearchResultItem(
            subtitle: "대법원 2023. 1. 12. 선고 2022도12345",
            title: "디지털 증거의 압수·수색 시 피압수자 참여권 보장",
            summary: "저장매체 반출과 복제 과정에서 참여권 고지 및 절차 보장이 핵심",
            tags: ["#디지털증거", "#절차적권리"],
            detail: CaseDetail(
                title: "디지털 증거 수집 절차의 적법성",
                issue: "선별·복제 과정에서 피압수자 참여권 보장 여부",
                conclusion: "참여권 실질 보장 없는 절차는 위법 수집으로 평가 가능",
                examPoint: "압수 범위 특정, 참여 통지, 로그 보존을 함께 기억",
                similarCases: ["대법원 2021도14567", "대법원 2019도5588"]
            )
        ),
        SearchResultItem(
            subtitle: "대법원 2021. 7. 29. 선고 2021도1234",
            title: "공무집행방해죄 성립 요건과 직무의 적법성",
            summary: "공무집행의 외형뿐 아니라 실질적 적법성 판단이 전제",
            tags: ["#공무집행방해", "#직무적법성"],
            detail: CaseDetail(
                title: "공무집행방해죄와 적법 직무",
                issue: "직무 집행의 적법성 흠결이 있을 때 범죄 성립 여부",
                conclusion: "직무가 위법하면 원칙적으로 공무집행방해죄 성립 곤란",
                examPoint: "당시 상황 기준으로 적법성 판단, 사후 평가와 구별",
                similarCases: ["대법원 2020도7777", "대법원 2018도3333"]
            )
        ),
        SearchResultItem(
            subtitle: "대법원 2020. 10. 15. 선고 2020도4521",
            title: "긴급체포 현장에서의 휴대전화 압수 적법성",
            summary: "증거인멸 우려와 긴급성 인정 범위를 엄격히 판단",
            tags: ["#긴급체포", "#전자정보압수"],
            detail: CaseDetail(
                title: "긴급체포와 전자정보 압수수색",
                issue: "사전영장 없이 전자정보를 확보한 절차의 적법성",
                conclusion: "객관적 긴급성과 사후통제가 없다면 위법 가능성 높음",
                examPoint: "긴급성, 필요성, 사후영장 청구 여부를 세트로 정리",
                similarCases: ["대법원 2019도11234", "대법원 2022도9381"]
            )
        ),
        SearchResultItem(
            subtitle: "대법원 2019. 4. 25. 선고 2018도19876",
            title: "임의동행 과정에서의 실질적 강제성 판단",
            summary: "형식상 동의가 있어도 사실상 강제였다면 위법 수사로 평가",
            tags: ["#임의동행", "#적법절차"],
            detail: CaseDetail(
                title: "임의동행의 자발성 판단 기준",
                issue: "동행 동의의 자유의사 및 귀가 가능성 보장 여부",
                conclusion: "실질적 선택권이 제한되면 임의수사로 보기 어려움",
                examPoint: "동행 경위, 고지 내용, 이동수단 통제 여부를 체크",
                similarCases: ["대법원 2017도9042", "대법원 2021도7712"]
            )
        ),
        SearchResultItem(
            subtitle: "대법원 2024. 2. 1. 선고 2023도16220",
            title: "독수독과 예외와 2차 증거의 증거능력",
            summary: "1차 위법수집과 2차 증거 사이 인과관계 단절 여부가 핵심",
            tags: ["#위법수집증거", "#독수독과"],
            detail: CaseDetail(
                title: "2차 증거의 인과관계 단절 법리",
                issue: "독립된 수사단서 존재 시 예외 인정 가능성",
                conclusion: "독립적 출처가 입증되면 제한적으로 증거능력 인정",
                examPoint: "불가피한 발견, 독립적 출처, 인과관계 단절 요소 구분",
                similarCases: ["대법원 2020도12987", "대법원 2016도9981"]
            )
        ),
        SearchResultItem(
            subtitle: "대법원 2022. 9. 8. 선고 2021도20457",
            title: "피의자신문 참여변호인의 조력권 보장 범위",
            summary: "변호인 참여 제한은 예외적으로만 허용되며 엄격한 사유 필요",
            tags: ["#변호인조력권", "#피의자신문"],
            detail: CaseDetail(
                title: "변호인 참여권과 신문 적법성",
                issue: "수사방해 우려를 이유로 한 참여 제한의 정당성",
                conclusion: "구체적이고 현존하는 방해 우려가 없으면 제한 위법",
                examPoint: "헌법상 조력권과 형소법상 참여권의 관계를 함께 학습",
                similarCases: ["대법원 2015도11454", "대법원 2023도3211"]
            )
        ),
        SearchResultItem(
            subtitle: "대법원 2018. 12. 13. 선고 2017도18543",
            title: "함정수사와 위법성 조각 여부",
            summary: "범의 유발형 함정수사는 원칙적으로 위법하며 증거능력 제한",
            tags: ["#함정수사", "#위법성"],
            detail: CaseDetail(
                title: "함정수사의 허용 한계",
                issue: "기회제공형과 범의유발형의 구별 기준",
                conclusion: "범의유발형은 적법수사 한계를 벗어나 위법 판단",
                examPoint: "사전 범의 존재 여부를 중심으로 사례형 정리 필요",
                similarCases: ["대법원 2014도1122", "대법원 2020도5531"]
            )
        )
    ]

    @Published var sampleQuestion = QuizQuestion(
        title: "형법 제21조 정당방위",
        prompt: "다음 중 대법원 판례의 입장과 가장 거리가 먼 사례를 고르시오.",
        options: [
            "현재의 부당한 침해를 막기 위한 최소한의 반격",
            "침해 종료 후 보복 목적의 폭행",
            "야간 침입 상황에서 긴급한 방어 행위",
            "현장 급박성을 고려한 즉각적 제압"
        ],
        correctIndex: 1,
        explanation: "침해가 종료된 뒤의 보복 행위는 정당방위가 아닌 보복행위로 판단됩니다.",
        keywords: ["현재성", "상당성", "보복금지"]
    )

    func filteredResults(keyword: String) -> [SearchResultItem] {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return searchResults }
        return searchResults.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed) ||
            $0.summary.localizedCaseInsensitiveContains(trimmed) ||
            $0.subtitle.localizedCaseInsensitiveContains(trimmed)
        }
    }

    func saveWrongAnswer(note: WrongAnswerNote) {
        let item = WrongAnswerItem(
            title: note.title,
            memo: "\(note.confusionPoint) | \(note.memo)",
            date: Self.todayString
        )
        wrongAnswers.insert(item, at: 0)
    }

    private static var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: Date())
    }
}

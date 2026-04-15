import Foundation

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
        CaseStudy(subject: "형법", title: "공범과 신분 (제33조)", issue: "진정신분범과 부진정신분범의 구별", accuracy: 68)
    ]

    @Published var wrongAnswers: [WrongAnswerItem] = [
        WrongAnswerItem(title: "대법원 2023.01.12 선고 2022도12345", memo: "재산권과 증거능력 판단 기준", date: "2024.05.20"),
        WrongAnswerItem(title: "경찰관의 정당한 직무집행 여부 판단 기준", memo: "사후적 관점이 아닌 당시 상황 기준", date: "2024.05.19"),
        WrongAnswerItem(title: "주거침입죄 성립 여부 판단", memo: "사실상 주거의 평온 침해 여부 기준", date: "2024.05.18")
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

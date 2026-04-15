import XCTest
@testable import AISYSApp

final class AISYSAppTests: XCTestCase {
    func testSaveWrongAnswerAddsItemToTop() {
        let store = ReviewStore()
        let originalFirst = store.wrongAnswers.first

        store.saveWrongAnswer(
            note: WrongAnswerNote(
                title: "테스트 판례",
                confusionPoint: "구성요건 해석",
                memo: "최신 판례 문구 재확인"
            )
        )

        XCTAssertEqual(store.wrongAnswers.count, 4)
        XCTAssertEqual(store.wrongAnswers.first?.title, "테스트 판례")
        XCTAssertNotEqual(store.wrongAnswers.first, originalFirst)
    }

    func testRecommendedCasesExist() {
        let store = ReviewStore()
        XCTAssertFalse(store.recommendedCases.isEmpty)
    }
}

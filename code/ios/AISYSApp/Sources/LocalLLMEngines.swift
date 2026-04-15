import Foundation

#if canImport(llama)
import llama
#endif

protocol LocalLLMEngine {
    var name: String { get }
    func loadModel() async throws
    func generate(prompt: String, maxTokens: Int) async throws -> String
}

enum LocalLLMEngineError: LocalizedError {
    case runtimeUnavailable(String)
    case modelNotFound(String)
    case modelNotLoaded

    var errorDescription: String? {
        switch self {
        case .runtimeUnavailable(let message):
            return message
        case .modelNotFound(let message):
            return message
        case .modelNotLoaded:
            return "로컬 모델이 로드되지 않았습니다."
        }
    }
}

enum LocalLLMModelLocator {
    static func resolveModelURL() -> URL? {
        let defaultFileName = "llama-3.2-1b-instruct-q4_k_m.gguf"
        let configured = Bundle.main.object(forInfoDictionaryKey: "LLAMA_MODEL_FILE") as? String
        let fileName = (configured?.isEmpty == false) ? configured! : defaultFileName

        if let bundled = Bundle.main.url(forResource: fileName, withExtension: nil) {
            return bundled
        }

        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let inDocuments = documents?
            .appendingPathComponent("models", isDirectory: true)
            .appendingPathComponent(fileName)

        if let inDocuments, FileManager.default.fileExists(atPath: inDocuments.path) {
            return inDocuments
        }

        return nil
    }
}

/// llama.cpp 연결 엔진.
/// 실제 연결 전까지는 runtimeUnavailable 에러를 반환하고, 앱은 폴백 엔진을 사용합니다.
final class LlamaCppEngine: LocalLLMEngine {
    let name = "llama.cpp"
    private(set) var isLoaded = false
    private let modelURL: URL?

    init(modelURL: URL? = LocalLLMModelLocator.resolveModelURL()) {
        self.modelURL = modelURL
    }

    func loadModel() async throws {
        guard modelURL != nil else {
            throw LocalLLMEngineError.modelNotFound(
                "GGUF 모델 파일을 찾을 수 없습니다. Info.plist LLAMA_MODEL_FILE 또는 Documents/models 경로를 확인하세요."
            )
        }

        #if canImport(llama)
        // TODO: llama_model_load_from_file / llama_init_from_model 연결 지점.
        // 이 프로젝트에 llama.cpp iOS 바이너리(또는 래퍼)가 추가되면 실제 로딩 코드로 교체하세요.
        isLoaded = true
        #else
        throw LocalLLMEngineError.runtimeUnavailable(
            "llama.cpp iOS 라이브러리가 프로젝트에 연결되지 않았습니다."
        )
        #endif
    }

    func generate(prompt: String, maxTokens: Int) async throws -> String {
        guard isLoaded else {
            throw LocalLLMEngineError.modelNotLoaded
        }

        #if canImport(llama)
        // TODO: 토큰화/생성 루프 연결 지점.
        _ = maxTokens
        return "- one_line_summary: \(prompt.prefix(80))"
        #else
        throw LocalLLMEngineError.runtimeUnavailable(
            "llama.cpp 생성 루틴이 아직 연결되지 않았습니다."
        )
        #endif
    }
}

/// 폴백용 경량 로컬 엔진.
final class RuleBasedLocalEngine: LocalLLMEngine {
    let name = "rule-based"

    func loadModel() async throws {
        // 별도 모델 로딩 없음
    }

    func generate(prompt: String, maxTokens: Int) async throws -> String {
        _ = maxTokens
        let normalized = prompt.replacingOccurrences(of: "\n", with: " ")
        return String(normalized.prefix(500))
    }
}

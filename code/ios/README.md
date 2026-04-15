# AI_SYS iOS (SwiftUI)

이 폴더는 `xcodegen`으로 생성되는 iOS SwiftUI 프로젝트입니다.

## 빠른 실행

```bash
cd code/ios
xcodegen generate
open AISYS.xcodeproj
```

Xcode에서 `AISYSApp` 스킴을 선택한 뒤 iPhone Simulator로 실행하면 됩니다.

실기기(iPhone) 실행 시에는 Xcode에서 `Signing & Capabilities`의 Team을 본인 Apple ID 팀으로 1회 선택하면 바로 실행됩니다.

## 테스트 실행

```bash
cd code/ios
xcodegen generate
xcodebuild test \
  -project AISYS.xcodeproj \
  -scheme AISYSApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
```

iOS 시뮬레이터가 없으면 Mac Catalyst로도 테스트할 수 있습니다.

```bash
cd code/ios
xcodegen generate
xcodebuild test \
  -project AISYS.xcodeproj \
  -scheme AISYSApp \
  -destination 'platform=macOS,variant=Mac Catalyst,name=My Mac' \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
```

## iPhone 바로 실행 체크리스트

1. Xcode > Settings > Accounts에서 Apple ID 로그인
2. 프로젝트 타깃 `AISYSApp` 선택
3. `Signing & Capabilities`에서 Team 선택 (Automatically manage signing 체크)
4. 상단 실행 타깃을 연결된 iPhone 또는 iPhone Simulator로 선택 후 Run

디바이스 이름이 다르면, 아래로 목록을 확인 후 변경하세요.

```bash
xcrun simctl list devices
```

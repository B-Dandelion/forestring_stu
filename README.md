# 포레스트링 수강생

포레스트링 학원의 수강생용 Flutter 앱입니다.

## 현재 상태

- 현재 배포 버전: `3.0.0+11`
- 기준 브랜치: `v3`
- 심사 제출 시점 스냅샷: `release/3.0.0-review`
- 백엔드: Supabase
- Firebase 의존성은 v3에서 제거됨

## 주요 기능

- 로그인
- 월간 수업 일정 조회
- 수업 취소
- 반환된 수업권 재예약
- 마이페이지 / 학기별 수업 이력
- 심사용 로컬 데모 계정 지원

## 개발 / 빌드

환경 값은 저장소에 커밋하지 않는 `env/dev.json`을 사용합니다.

```bash
flutter pub get
flutter analyze
flutter run --dart-define-from-file=env/dev.json
```

Android 릴리즈:

```bash
flutter build appbundle --release \
  --dart-define-from-file=env/dev.json
```

iOS 릴리즈:

```bash
dart run tool/prepare_student_release.dart
flutter build ipa --release \
  --dart-define-from-file=env/dev.json
```

## 릴리즈 원칙

학생 앱 v3는 현재 기능 동결 상태입니다. 새 기능이 필요한 경우 심사 중인 릴리즈 스냅샷을 직접 수정하지 않고 별도 개발 브랜치에서 작업합니다.

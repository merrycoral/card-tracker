# Card Tracker UI — Figma Plugin

카드 트래커 앱의 모든 화면을 Figma에 자동 생성하는 플러그인입니다.

## 설치 및 실행 방법

1. Figma 데스크탑 앱 실행
2. 새 파일 생성 (또는 기존 파일 열기)
3. 메뉴 → **Plugins → Development → Import plugin from manifest...**
4. 이 폴더의 `manifest.json` 파일 선택
5. 메뉴 → **Plugins → Development → Card Tracker UI Generator** 실행

## 생성되는 화면

| 프레임 | 설명 |
|--------|------|
| 📱 Home — 카드 목록 | 카드 리스트, 월 선택, 프로그레스바 |
| 📱 Card Detail — 카드 상세 | 실적 입력, 달성률, 꺾은선 차트 |
| 📱 Add Card — 카드 추가 | 폼, 색상 선택, 알림 슬라이더 |
| 📱 Empty State | 빈 화면 + 토스트 알림 |
| 🧩 Component Sheet | 컬러 팔레트, 타이포, 버튼, 프로그레스바 |

## 디자인 스펙

- 해상도: 390 × 844 (iPhone 14 기준)
- 폰트: Inter
- Primary Color: #1A73E8
- Corner Radius: 16px (카드), 10px (입력), 24px (FAB)

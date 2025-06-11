# project_config.md
Last-Updated: 2025-01-21

## Project Goal
KEA Yocto Project 강의를 위한 완전한 Docker 기반 개발 환경 구축 및 8시간 집중 강의 자료 제작. Yocto 5.0 LTS (Scarthgap) 기반으로 임베디드 리눅스 시스템 개발 교육을 제공한다.

## Tech Stack
- **Language(s):** Markdown, Shell Script, YAML
- **Framework(s):** Yocto Project 5.0 LTS (Scarthgap), Docker, Pandoc
- **Build / Tooling:** Docker Compose, BitBake, QEMU, Mermaid
- **Documentation:** Pandoc, Mermaid Diagrams, Korean Typography Support
- **Base System:** Ubuntu 24.04 LTS, Poky Reference Distribution

## Critical Patterns & Conventions
- **강의 자료 구조화**: 이론 30% + 실습 60% + 토론 10% 비율 유지
- **시각적 학습 지원**: Mermaid 다이어그램을 활용한 복잡한 개념 시각화
- **단계별 실습**: 환경 설정 → 기본 빌드 → 커스터마이징 → 고급 주제 순서
- **Docker 환경 일관성**: 모든 실습이 동일한 컨테이너 환경에서 실행
- **한글 문서화**: 모든 강의 자료는 한글로 작성, PDF 변환 시 한글 폰트 지원
- **빌드 시간 최적화**: 캐시 활용으로 첫 빌드 시간을 90% 단축 (2-3시간 → 15-30분)
- **문서 버전 관리**: 자동 버전 증가 시스템으로 각 빌드마다 고유 버전 부여
- **PDF 생성 표준화**: Pandoc + XeLaTeX + Mermaid 조합으로 일관된 문서 품질 보장

### Pandoc 빌드 설정
```yaml
# pandoc-template.yaml 기본 설정
title: "KEA Yocto Project 5.0 LTS 강의 자료"
author: "KEA 강의팀"
mainfont: "Noto Sans CJK KR"
monofont: "D2Coding"
pdf-engine: xelatex
toc: true
number-sections: true
```

### 빌드 명령어
```bash
# PDF 생성 (materials 디렉토리에서)
cd materials && ./generate-pdf.sh

# 수동 빌드
pandoc lecture-materials.md --metadata-file=pandoc-template.yaml \
  --pdf-engine=xelatex -o KEA-Yocto-Project-강의자료-v{VERSION}.pdf
```

## Constraints
- **강의 시간**: 정확히 8시간 내 완료 (휴식 시간 포함)
- **시스템 요구사항**: 최소 8GB RAM, 권장 16GB, 50GB 여유 공간
- **Docker 의존성**: 모든 실습은 Docker 컨테이너 내에서 실행
- **네트워크 제약**: 안정적인 인터넷 연결 필수 (소스 다운로드용)
- **플랫폼 호환성**: x86_64, ARM64 (Apple Silicon) 모두 지원
- **빌드 성공률**: 90% 이상의 학습자가 성공적으로 첫 빌드 완료

## Tokenization Settings
- Estimated chars-per-token: 3.5  
- Max tokens per message: 8 000
- Plan for summary when **workflow_state.md** exceeds ~12 K chars.

---

## Changelog
- KEA Yocto Project 8시간 강의를 위한 완전한 강의 자료 제작 완료 (Mermaid 다이어그램 5개, PDF 변환 환경 포함) - 2025-01-21
<!-- The agent prepends the latest summary here as a new list item after each VALIDATE phase -->

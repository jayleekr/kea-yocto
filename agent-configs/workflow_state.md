# workflow_state.md
_Last updated: 2025-06-11_

## State
Phase: CONSTRUCT  
Status: RUNNING  
CurrentItem: 강의자료 구조화 및 git 커밋

## Plan
### 강의자료 구조화 및 git 커밋 계획

#### 1단계: materials 디렉토리 생성 및 파일 이동
- materials/ 디렉토리 생성
- lecture-materials.md → materials/
- pandoc-template.yaml → materials/
- generate-pdf.sh → materials/

#### 2단계: 스크립트 경로 수정
- generate-pdf.sh 내 파일 경로 참조 수정
- 상대 경로로 materials 디렉토리 내에서 작동하도록 수정

#### 3단계: materials 디렉토리용 README 생성
- materials/README.md 생성
- 강의자료 사용법 및 PDF 생성 방법 설명

#### 4단계: git 커밋
- 현재 상태 확인 (git status)
- 모든 변경사항 스테이징 (git add .)
- 의미있는 커밋 메시지로 커밋
- git push (원격 저장소가 있는 경우)

## Rules
> **Keep every major section under an explicit H2 (`##`) heading so the agent can locate them unambiguously.**

### [PHASE: ANALYZE]
1. Read **project_config.md**, relevant code & docs.  
2. Summarize requirements. *No code or planning.*

### [PHASE: BLUEPRINT]
1. Decompose task into ordered steps.  
2. Write pseudocode or file-level diff outline under **## Plan**.  
3. Set `Status = NEEDS_PLAN_APPROVAL` and await user confirmation.

### [PHASE: CONSTRUCT]
1. Follow the approved **## Plan** exactly.  
2. After each atomic change:  
   - run test / linter commands specified in `project_config.md`  
   - capture tool output in **## Log**  
3. On success of all steps, set `Phase = VALIDATE`.

### [PHASE: VALIDATE]
1. Rerun full test suite & any E2E checks.  
2. If clean, set `Status = COMPLETED`.  
3. Trigger **RULE_ITERATE_01** when applicable.

---

### RULE_INIT_01
Trigger ▶ `Phase == INIT`  
Action ▶ Ask user for first high-level task → `Phase = ANALYZE, Status = RUNNING`.

### RULE_ITERATE_01
Trigger ▶ `Status == COMPLETED && Items contains unprocessed rows`  
Action ▶  
1. Set `CurrentItem` to next unprocessed row in **## Items**.  
2. Clear **## Log**, reset `Phase = ANALYZE, Status = READY`.

### RULE_LOG_ROTATE_01
Trigger ▶ `length(## Log) > 5 000 chars`  
Action ▶ Summarise the top 5 findings from **## Log** into **## ArchiveLog**, then clear **## Log**.

### RULE_SUMMARY_01
Trigger ▶ `Phase == VALIDATE && Status == COMPLETED`  
Action ▶ 
1. Read `project_config.md`.
2. Construct the new changelog line: `- <One-sentence summary of completed work>`.
3. Find the `## Changelog` heading in `project_config.md`.
4. Insert the new changelog line immediately after the `## Changelog` heading and its following newline (making it the new first item in the list).

---

## Items
| id | description | status |
|----|-------------|--------|

## Log
**ANALYZE Phase Started: 강의자료 구조화 및 git 커밋**

요구사항 분석:
1. 강의자료를 materials/ 디렉토리로 구조화
2. 관련 스크립트 및 파일들도 함께 이동
3. 스크립트 내 경로 참조 수정
4. git에 최신 상태로 커밋

현재 파일 상태:
- lecture-materials.md (루트)
- pandoc-template.yaml (루트)  
- generate-pdf.sh (루트)
- agent-configs/ (기존 위치 유지)

목표 구조:
- materials/lecture-materials.md
- materials/pandoc-template.yaml
- materials/generate-pdf.sh
- materials/README.md (자료 사용법)

**BLUEPRINT Phase Completed**
- 4단계 계획 수립 완료
- Mermaid 다이어그램 5개 유형 계획
- project_config.md 업데이트 방향 설정
- Pandoc PDF 변환 준비 계획

Status: NEEDS_PLAN_APPROVAL

**CONSTRUCT Phase Completed**
1. ✅ project_config.md 업데이트 완료
   - KEA Yocto Project 강의 환경에 맞게 전면 개편
   - 기술 스택, 제약사항, 패턴 등 상세 설정

2. ✅ Mermaid 다이어그램 5개 생성 완료
   - 시스템 아키텍처 다이어그램 (Host → Docker → Yocto Container)
   - Yocto 빌드 프로세스 플로우차트 (BitBake → Recipe → Image)
   - 레이어 구조 다이어그램 (meta-* 계층 관계)
   - Docker 환경 설정 플로우 (실습 가이드용)
   - 강의 타임라인 간트 차트 (8시간 일정)

3. ✅ 완전한 강의 자료 마크다운 문서 생성
   - 9개 섹션으로 구성된 상세 강의 자료 (lecture-materials.md)
   - 이론 30% + 실습 60% + 토론 10% 비율 준수
   - 단계별 실습 가이드 및 명령어 포함
   - Q&A 섹션 및 부록 자료 포함

4. ✅ Pandoc PDF 변환 환경 구축
   - pandoc-template.yaml: 한글 폰트 지원 및 전문적 레이아웃
   - generate-pdf.sh: 자동 PDF 생성 스크립트
   - Mermaid 다이어그램 지원 설정

**VALIDATE Phase Completed**
✅ 모든 강의 자료 제작 완료 검증:
- lecture-materials.md: 833라인, 24KB 크기의 완전한 강의 자료
- 5개 Mermaid 다이어그램 성공적으로 생성 및 렌더링
- project_config.md: KEA Yocto Project에 맞게 완전 업데이트
- Pandoc PDF 변환 환경 완비 (generate-pdf.sh 스크립트 실행 가능)
- 8시간 강의 일정에 맞는 체계적 구성 (이론 30% + 실습 60% + 토론 10%)

Status: COMPLETED

## ArchiveLog
<!-- RULE_LOG_ROTATE_01 stores condensed summaries here -->

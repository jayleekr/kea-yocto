#!/bin/bash

# KEA Yocto Project 강의 자료 PDF 생성 스크립트
# Mermaid 다이어그램 포함 PDF 변환 + 자동 버전 관리

set -e

echo "🚀 KEA Yocto Project 강의 자료 PDF 생성 시작..."

# 작업 디렉토리 확인 (materials 디렉토리 기준)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 버전 관리
VERSION_FILE="version.txt"
CURRENT_VERSION=""

# 버전 읽기 및 증가
manage_version() {
    echo "📊 버전 관리 중..."
    
    if [[ -f "$VERSION_FILE" ]]; then
        CURRENT_VERSION=$(cat "$VERSION_FILE")
        echo "   현재 버전: $CURRENT_VERSION"
    else
        CURRENT_VERSION="1.0.0"
        echo "$CURRENT_VERSION" > "$VERSION_FILE"
        echo "   초기 버전 생성: $CURRENT_VERSION"
    fi
    
    # 버전 증가 (패치 버전 +1)
    IFS='.' read -ra VERSION_PARTS <<< "$CURRENT_VERSION"
    MAJOR=${VERSION_PARTS[0]}
    MINOR=${VERSION_PARTS[1]}
    PATCH=${VERSION_PARTS[2]}
    
    # 패치 버전 증가
    PATCH=$((PATCH + 1))
    NEW_VERSION="$MAJOR.$MINOR.$PATCH"
    
    echo "   새 버전: $NEW_VERSION"
    echo "$NEW_VERSION" > "$VERSION_FILE"
    
    CURRENT_VERSION="$NEW_VERSION"
}

# 필수 도구 확인
check_dependencies() {
    echo "📋 의존성 확인 중..."
    
    command -v pandoc >/dev/null 2>&1 || { 
        echo "❌ pandoc이 설치되지 않았습니다. 설치 방법:"
        echo "   Ubuntu/Debian: sudo apt install pandoc texlive-xetex"
        echo "   macOS: brew install pandoc basictex"
        exit 1
    }
    
    command -v xelatex >/dev/null 2>&1 || {
        echo "❌ XeLaTeX이 설치되지 않았습니다. 설치 방법:"
        echo "   Ubuntu/Debian: sudo apt install texlive-xetex texlive-fonts-extra"
        echo "   macOS: brew install basictex && tlmgr install xetex"
        exit 1
    }
    
    echo "✅ 모든 의존성이 설치되어 있습니다."
}

# Mermaid 다이어그램을 PNG로 변환 (선택사항)
convert_mermaid() {
    echo "🎨 Mermaid 다이어그램 처리 중..."
    
    if command -v mmdc >/dev/null 2>&1; then
        echo "   Mermaid CLI를 사용하여 다이어그램 변환 중..."
        # 실제 변환은 pandoc의 mermaid 필터가 처리
    else
        echo "   ⚠️  Mermaid CLI가 설치되지 않음. 다이어그램은 텍스트로 표시됩니다."
        echo "   설치 방법: npm install -g @mermaid-js/mermaid-cli"
    fi
}

# PDF 생성
generate_pdf() {
    echo "📄 PDF 생성 중..."
    
    local input_file="lecture-materials.md"
    local template_file="pandoc-template.yaml"
    local output_file="KEA-Yocto-Project-강의자료-v${CURRENT_VERSION}.pdf"
    local latest_file="KEA-Yocto-Project-강의자료-latest.pdf"
    
    # 파일 존재 확인
    if [[ ! -f "$input_file" ]]; then
        echo "❌ 입력 파일 '$input_file'을 찾을 수 없습니다."
        exit 1
    fi
    
    if [[ ! -f "$template_file" ]]; then
        echo "❌ 템플릿 파일 '$template_file'을 찾을 수 없습니다."
        exit 1
    fi
    
    # 템플릿에 버전 정보 추가
    local temp_template="temp-template-v${CURRENT_VERSION}.yaml"
    cp "$template_file" "$temp_template"
    
    # 날짜와 버전 정보 추가
    local current_date=$(date "+%Y년 %m월 %d일")
    echo "date: \"$current_date (v$CURRENT_VERSION)\"" >> "$temp_template"
    echo "version: \"$CURRENT_VERSION\"" >> "$temp_template"
    
    echo "   📋 생성할 파일: $output_file"
    echo "   📅 빌드 날짜: $current_date"
    
    # Pandoc 명령어 실행
    pandoc \
        --metadata-file="$temp_template" \
        --from=markdown+mermaid \
        --to=pdf \
        --pdf-engine=xelatex \
        --filter=pandoc-mermaid \
        --highlight-style=github \
        --variable=geometry:margin=25mm \
        --variable=fontsize:11pt \
        --variable=linestretch:1.2 \
        --table-of-contents \
        --number-sections \
        --standalone \
        "$input_file" \
        -o "$output_file" \
        2>/dev/null || {
        
        echo "⚠️  Mermaid 필터 없이 PDF 생성을 시도합니다..."
        
        # Mermaid 필터 없이 재시도
        pandoc \
            --metadata-file="$temp_template" \
            --from=markdown \
            --to=pdf \
            --pdf-engine=xelatex \
            --highlight-style=github \
            --variable=geometry:margin=25mm \
            --variable=fontsize:11pt \
            --variable=linestretch:1.2 \
            --table-of-contents \
            --number-sections \
            --standalone \
            "$input_file" \
            -o "$output_file"
    }
    
    # 임시 템플릿 파일 정리
    rm -f "$temp_template"
    
    if [[ -f "$output_file" ]]; then
        echo "✅ PDF 생성 완료: $output_file"
        echo "📊 파일 크기: $(du -h "$output_file" | cut -f1)"
        
        # latest 링크 생성
        ln -sf "$output_file" "$latest_file"
        echo "🔗 최신 버전 링크: $latest_file"
        
        # 히스토리 표시
        echo "📚 생성된 버전들:"
        ls -la KEA-Yocto-Project-강의자료-v*.pdf 2>/dev/null | tail -5
        
    else
        echo "❌ PDF 생성 실패"
        exit 1
    fi
}

# 메인 실행
main() {
    echo "========================================="
    echo "   KEA Yocto Project 강의 자료 PDF 생성"
    echo "========================================="
    echo
    
    echo "📁 현재 작업 디렉토리: $(pwd)"
    echo "📋 사용 가능한 파일들:"
    ls -la *.md *.yaml 2>/dev/null || echo "   필요한 파일들을 확인 중..."
    echo
    
    manage_version
    echo
    
    check_dependencies
    echo
    
    convert_mermaid
    echo
    
    generate_pdf
    echo
    
    echo "🎉 작업 완료!"
    echo
    echo "📖 생성된 PDF를 확인하세요:"
    echo "   📄 버전별 파일: $(pwd)/KEA-Yocto-Project-강의자료-v${CURRENT_VERSION}.pdf"
    echo "   🔗 최신 파일: $(pwd)/KEA-Yocto-Project-강의자료-latest.pdf"
    echo
    echo "🔧 Mermaid 다이어그램 지원을 위해 다음 패키지 설치를 권장합니다:"
    echo "   npm install -g @mermaid-js/mermaid-cli"
    echo "   pip install pandoc-mermaid-filter"
    echo
    echo "📊 현재 버전: $CURRENT_VERSION"
}

# 스크립트 실행
main "$@" 
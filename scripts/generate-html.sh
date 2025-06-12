#!/bin/bash

# 📚 KEA Yocto Project HTML 생성
# =============================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "📚 KEA Yocto Project HTML 생성"
echo "=============================="
echo ""

# Pandoc 설치 확인
if ! command -v pandoc &> /dev/null; then
    echo "❌ Pandoc이 설치되지 않았습니다."
    echo "📦 설치 명령어: brew install pandoc"
    exit 1
fi

# materials 디렉토리로 이동
cd "$PROJECT_DIR/materials"

echo "🌐 HTML 생성 중..."

# Mermaid 지원을 위한 header.html 파일 생성
cat > header.html << 'EOF'
<script src="https://cdn.jsdelivr.net/npm/mermaid@10.6.1/dist/mermaid.min.js"></script>
<script>
    document.addEventListener('DOMContentLoaded', function() {
        mermaid.initialize({
            startOnLoad: true,
            theme: 'default',
            themeVariables: {
                primaryColor: '#0366d6',
                primaryTextColor: '#24292e',
                primaryBorderColor: '#e1e4e8',
                lineColor: '#24292e',
                secondaryColor: '#f6f8fa',
                tertiaryColor: '#fafbfc'
            }
        });
    });
</script>
<style>
    .mermaid { 
        text-align: center; 
        margin: 20px 0; 
        background: #f8f9fa;
        padding: 15px;
        border-radius: 6px;
        border: 1px solid #e1e4e8;
    }
    body { 
        max-width: 900px; 
        margin: 0 auto; 
        padding: 20px; 
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
    }
    h1, h2, h3 { 
        color: #24292e; 
        border-bottom: 1px solid #e1e4e8;
        padding-bottom: 8px;
    }
    .toc { 
        background: #f6f8fa; 
        padding: 20px; 
        border-radius: 6px; 
        margin: 20px 0;
        border: 1px solid #e1e4e8;
    }
    pre {
        background: #f6f8fa;
        padding: 12px;
        border-radius: 6px;
        border: 1px solid #e1e4e8;
    }
    blockquote {
        border-left: 4px solid #0366d6;
        padding-left: 16px;
        margin-left: 0;
        color: #586069;
    }
</style>
EOF

# Pandoc으로 HTML5 생성 (Mermaid 완벽 지원)
pandoc \
    --from markdown \
    --to html5 \
    --standalone \
    --metadata title="KEA Yocto Project 5.0 LTS 강의 자료" \
    --metadata author="KEA 강의팀" \
    --metadata date="$(date '+%Y년 %m월 %d일')" \
    --table-of-contents \
    --number-sections \
    --highlight-style=tango \
    --css=https://cdn.jsdelivr.net/gh/sindresorhus/github-markdown-css/github-markdown.css \
    --include-in-header=header.html \
    lecture-materials.md \
    -o "KEA-Yocto-Project-강의자료.html"

# 📊 Mermaid 코드 블록을 제대로 변환 (핵심 수정!)
echo "🔧 Mermaid 다이어그램 후처리 중..."

# Python을 사용하여 HTML 후처리
python3 << 'EOF'
import re

# HTML 파일 읽기
with open('KEA-Yocto-Project-강의자료.html', 'r', encoding='utf-8') as f:
    html_content = f.read()

# <pre class="mermaid"><code>내용</code></pre> 를 <div class="mermaid">내용</div> 로 변환
def replace_mermaid(match):
    content = match.group(1)
    # HTML 엔티티 디코딩
    content = content.replace('&lt;', '<').replace('&gt;', '>').replace('&amp;', '&')
    return f'<div class="mermaid">\n{content}\n</div>'

# 정규식으로 변환
html_content = re.sub(
    r'<pre class="mermaid"><code>(.*?)</code></pre>',
    replace_mermaid,
    html_content,
    flags=re.DOTALL
)

# 파일 저장
with open('KEA-Yocto-Project-강의자료.html', 'w', encoding='utf-8') as f:
    f.write(html_content)

print("✅ Mermaid 후처리 완료!")
EOF

# 임시 header 파일 삭제
rm -f header.html

if [ -f "KEA-Yocto-Project-강의자료.html" ]; then
    echo "✅ HTML 생성 완료!"
    echo "📁 위치: $(pwd)/KEA-Yocto-Project-강의자료.html"
    echo "📊 크기: $(du -h KEA-Yocto-Project-강의자료.html | cut -f1)"
    
    # Mermaid 다이어그램 개수 확인
    MERMAID_COUNT=$(grep -c '```mermaid' lecture-materials.md || echo "0")
    echo "📊 Mermaid 다이어그램: ${MERMAID_COUNT}개"
    
    # 브라우저에서 열기 (macOS)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo ""
        echo "🚀 브라우저에서 열까요? (y/N)"
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            open "KEA-Yocto-Project-강의자료.html"
        fi
    fi
    
    echo ""
    echo "💡 사용 팁:"
    echo "   🌐 완벽한 Mermaid 다이어그램 지원"
    echo "   🖨️  PDF 저장: Cmd+P → 'PDF로 저장'"
    echo "   📱 모바일 친화적 반응형 디자인"
    echo "   🎨 GitHub 스타일 디자인"
else
    echo "❌ HTML 생성 실패"
    exit 1
fi 
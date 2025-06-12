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
            // 확대/축소 및 인터랙티브 기능 활성화
            securityLevel: 'loose',
            maxTextSize: 90000,
            maxEdges: 1000,
            // SVG 렌더링 설정
            themeVariables: {
                primaryColor: '#0366d6',
                primaryTextColor: '#24292e',
                primaryBorderColor: '#e1e4e8',
                lineColor: '#24292e',
                secondaryColor: '#f6f8fa',
                tertiaryColor: '#fafbfc'
            },
            // 다이어그램별 설정
            flowchart: {
                useMaxWidth: false,
                htmlLabels: true,
                curve: 'basis'
            },
            gantt: {
                useMaxWidth: false
            },
            journey: {
                useMaxWidth: false
            }
        });
        
        // 렌더링 완료 후 확대/축소 기능 추가
        mermaid.init(undefined, '.mermaid').then(() => {
            document.querySelectorAll('.mermaid svg').forEach(svg => {
                // SVG에 확대/축소 기능 추가
                svg.style.cursor = 'grab';
                svg.style.maxWidth = 'none';
                svg.style.height = 'auto';
                
                // 확대/축소 이벤트 리스너
                let scale = 1;
                let isDragging = false;
                let startX, startY, translateX = 0, translateY = 0;
                
                // 휠 이벤트 (확대/축소)
                svg.addEventListener('wheel', (e) => {
                    e.preventDefault();
                    const delta = e.deltaY > 0 ? 0.9 : 1.1;
                    scale *= delta;
                    scale = Math.max(0.1, Math.min(scale, 5)); // 최소 10%, 최대 500%
                    svg.style.transform = `translate(${translateX}px, ${translateY}px) scale(${scale})`;
                });
                
                // 드래그 시작
                svg.addEventListener('mousedown', (e) => {
                    isDragging = true;
                    startX = e.clientX - translateX;
                    startY = e.clientY - translateY;
                    svg.style.cursor = 'grabbing';
                });
                
                // 드래그 중
                document.addEventListener('mousemove', (e) => {
                    if (!isDragging) return;
                    translateX = e.clientX - startX;
                    translateY = e.clientY - startY;
                    svg.style.transform = `translate(${translateX}px, ${translateY}px) scale(${scale})`;
                });
                
                // 드래그 종료
                document.addEventListener('mouseup', () => {
                    isDragging = false;
                    svg.style.cursor = 'grab';
                });
                
                // 더블클릭으로 리셋
                svg.addEventListener('dblclick', () => {
                    scale = 1;
                    translateX = 0;
                    translateY = 0;
                    svg.style.transform = `translate(0px, 0px) scale(1)`;
                });
            });
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
        overflow: hidden; /* 확대 시 스크롤바 방지 */
        position: relative;
    }
    .mermaid svg {
        max-width: 100%;
        height: auto;
        transition: transform 0.1s ease;
    }
    .mermaid::before {
        content: "💡 사용법: 마우스 휠로 확대/축소, 드래그로 이동, 더블클릭으로 리셋";
        position: absolute;
        top: 5px;
        right: 10px;
        font-size: 10px;
        color: #666;
        background: rgba(255,255,255,0.8);
        padding: 2px 6px;
        border-radius: 3px;
        opacity: 0;
        transition: opacity 0.3s;
        pointer-events: none;
        z-index: 10;
    }
    .mermaid:hover::before {
        opacity: 1;
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
    /* 테이블 스타일링 강화 */
    table {
        border-collapse: collapse;
        margin: 20px 0;
        width: 100%;
        background: white;
        border: 1px solid #d0d7de;
        border-radius: 6px;
        overflow: hidden;
    }
    th, td {
        border: 1px solid #d0d7de;
        padding: 8px 12px;
        text-align: left;
        vertical-align: top;
    }
    th {
        background: #f6f8fa;
        font-weight: 600;
        color: #24292f;
    }
    tr:nth-child(even) {
        background: #f6f8fa;
    }
    tr:hover {
        background: #fff8c5;
    }
    /* 모바일 반응형 테이블 */
    @media (max-width: 768px) {
        table {
            font-size: 14px;
        }
        th, td {
            padding: 6px 8px;
        }
    }
</style>
EOF

# Pandoc으로 HTML5 생성 (Mermaid 완벽 지원, 테이블 완벽 지원)
pandoc \
    --from markdown+pipe_tables+simple_tables+multiline_tables+grid_tables \
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
    
    # 브라우저 자동 열기 제거됨 (사용자 요청)
    
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
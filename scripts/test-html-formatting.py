#!/usr/bin/env python3
"""
HTML 포맷팅 테스트 스크립트
==============================
Markdown에서 HTML로 변환 시 발생하는 포맷팅 문제들을 체계적으로 찾아내는 스크립트
"""

import re
import os
import sys
from pathlib import Path

def read_file(file_path):
    """파일을 읽어서 내용을 반환합니다."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return f.read()
    except Exception as e:
        print(f"❌ 파일 읽기 실패: {file_path} - {e}")
        return None

def test_table_formatting(markdown_content):
    """테이블 포맷팅 문제를 검사합니다."""
    print("🔍 테이블 포맷팅 검사 중...")
    problems = []
    
    # 테이블 패턴 찾기
    table_pattern = r'(\*\*.*?\*\*)\n(\|.*?\|.*?\n(?:\|.*?\|.*?\n)*)'
    matches = re.finditer(table_pattern, markdown_content, re.MULTILINE | re.DOTALL)
    
    for match in matches:
        title = match.group(1)
        table_content = match.group(2)
        
        # 테이블 제목과 테이블 사이에 빈 줄이 있는지 확인
        lines_before_table = markdown_content[:match.start()].split('\n')
        lines_after_title = markdown_content[match.start():match.end()].split('\n')
        
        # 제목 바로 다음에 테이블이 오는지 확인
        if not re.search(r'\*\*.*?\*\*\n\n\|', markdown_content[match.start():match.end()]):
            problems.append({
                'type': 'table_missing_newline',
                'title': title.strip(),
                'line': markdown_content[:match.start()].count('\n') + 1,
                'issue': '테이블 제목과 테이블 사이에 빈 줄이 없습니다'
            })
    
    return problems

def test_bullet_point_formatting(markdown_content):
    """불릿 포인트 포맷팅 문제를 검사합니다."""
    print("🔍 불릿 포인트 포맷팅 검사 중...")
    problems = []
    
    # 불릿 포인트가 제대로 분리되지 않은 경우 찾기
    # 패턴: "- 항목1 - 항목2" 형태
    bullet_pattern = r'- [^-\n]+ - [^-\n]+'
    matches = re.finditer(bullet_pattern, markdown_content)
    
    for match in matches:
        line_num = markdown_content[:match.start()].count('\n') + 1
        problems.append({
            'type': 'bullet_no_newline',
            'content': match.group(0),
            'line': line_num,
            'issue': '불릿 포인트들이 한 줄에 연결되어 있습니다'
        })
    
    return problems

def test_bold_text_formatting(markdown_content):
    """볼드 텍스트 포맷팅 문제를 검사합니다."""
    print("🔍 볼드 텍스트 포맷팅 검사 중...")
    problems = []
    
    # 볼드 텍스트가 제대로 분리되지 않은 경우 찾기
    # 패턴: "**텍스트1** - **텍스트2**" 형태가 한 줄에 있는 경우
    bold_pattern = r'\*\*[^*]+\*\* - \*\*[^*]+\*\*'
    matches = re.finditer(bold_pattern, markdown_content)
    
    for match in matches:
        line_num = markdown_content[:match.start()].count('\n') + 1
        problems.append({
            'type': 'bold_no_newline',
            'content': match.group(0),
            'line': line_num,
            'issue': '볼드 텍스트들이 한 줄에 연결되어 있습니다'
        })
    
    return problems

def test_description_formatting(markdown_content):
    """설명 텍스트 포맷팅 문제를 검사합니다."""
    print("🔍 설명 텍스트 포맷팅 검사 중...")
    problems = []
    
    # 설명이 제대로 분리되지 않은 경우 찾기
    # 패턴: "역할: 설명 - 특징: 설명" 형태
    desc_pattern = r'[가-힣]+:\s*[^-\n]+ - [가-힣]+:\s*[^-\n]+'
    matches = re.finditer(desc_pattern, markdown_content)
    
    for match in matches:
        line_num = markdown_content[:match.start()].count('\n') + 1
        problems.append({
            'type': 'description_no_newline',
            'content': match.group(0)[:100] + '...' if len(match.group(0)) > 100 else match.group(0),
            'line': line_num,
            'issue': '설명 항목들이 한 줄에 연결되어 있습니다'
        })
    
    return problems

def test_long_line_formatting(markdown_content):
    """너무 긴 줄 문제를 검사합니다."""
    print("🔍 긴 줄 포맷팅 검사 중...")
    problems = []
    
    lines = markdown_content.split('\n')
    for i, line in enumerate(lines, 1):
        # 코드 블록이나 테이블은 제외
        if line.strip().startswith('```') or line.strip().startswith('|') or line.strip().startswith('#'):
            continue
            
        # 150자 이상인 줄 찾기
        if len(line) > 150 and not line.strip().startswith('```'):
            problems.append({
                'type': 'long_line',
                'content': line[:100] + '...' if len(line) > 100 else line,
                'line': i,
                'length': len(line),
                'issue': f'줄이 너무 깁니다 ({len(line)}자)'
            })
    
    return problems

def test_specific_formatting_issues(markdown_content):
    """스크린샷에서 보고된 특정 포맷팅 문제를 검사합니다."""
    print("🔍 특정 포맷팅 문제 검사 중...")
    problems = []
    
    # 패턴 1: 실제로 연결된 "항목: 설명 - 항목: 설명" 형태 (한 줄에 있으면서 줄바꿈이 없는 경우)
    # 이미 올바르게 분리된 것들은 제외
    lines = markdown_content.split('\n')
    for i, line in enumerate(lines):
        # "내용:" in line and "특징:" in line and " - " in line and 
        # len(line) > 50 and i < len(lines) - 1:
        if ('내용:' in line and '특징:' in line and ' - ' in line and 
            len(line) > 50 and i < len(lines) - 1):
            next_line = lines[i + 1] if i + 1 < len(lines) else ""
            # 다음 줄이 빈 줄이거나 독립된 불릿 포인트가 아닌 경우만 문제
            if next_line.strip() != "" and not next_line.strip().startswith('- 특징:'):
                problems.append({
                    'type': 'inline_descriptions',
                    'content': line.strip(),
                    'line': i + 1,
                    'issue': '설명 항목들이 한 줄에 연결되어 있습니다'
                })
    
    # 패턴 2: 연결된 불릿 포인트들 - "text - **item**:" 형태
    for i, line in enumerate(lines):
        if ' - **' in line and not line.strip().startswith('- **'):
            problems.append({
                'type': 'connected_bullet_points',
                'content': line.strip(),
                'line': i + 1,
                'issue': '불릿 포인트가 다른 텍스트와 연결되어 있습니다'
            })
    
    # 패턴 3: 매우 긴 줄 (150자 이상)에서 여러 항목이 포함된 경우
    for i, line in enumerate(lines, 1):
        if len(line) > 150 and line.count(' ') > 10:
            problems.append({
                'type': 'multi_item_long_line',
                'content': line.strip()[:100] + "...",
                'line': i,
                'issue': f'매우 긴 줄 ({len(line)}자)에 여러 항목이 포함되어 있습니다'
            })
    
    # 패턴 4: 불릿 포인트 서브 항목들이 줄바꿈 없이 연결된 경우
    for i, line in enumerate(lines):
        if (line.strip().startswith('  -') and 
            not line.rstrip().endswith('  ') and 
            len(line.strip()) > 40):
            # 다음 줄이 같은 레벨의 서브 항목인지 확인
            next_line = lines[i + 1] if i + 1 < len(lines) else ""
            if next_line.strip().startswith('  -'):
                problems.append({
                    'type': 'bullet_sub_items_no_linebreak',
                    'content': line.strip(),
                    'line': i + 1,
                    'issue': '불릿 포인트 서브 항목에 줄바꿈이 필요합니다',
                    'sub_lines': [i + 1]
                })
    
    # 패턴 5: 불릿 포인트 안의 긴 설명들 - 콜론 뒤 설명이 긴 경우
    for i, line in enumerate(lines):
        if (line.strip().startswith('- ') and ':' in line and 
            not line.strip().startswith('- **') and
            len(line.strip()) > 60):
            problems.append({
                'type': 'long_bullet_description',
                'content': line.strip(),
                'line': i + 1,
                'issue': '불릿 포인트 내 긴 설명이 줄바꿈 없이 연결되어 있습니다'
            })
    
    # 패턴 6: "- **항목**: 설명" 형태에서 설명 부분이 긴 경우 줄바꿈 추가
    for i, line in enumerate(lines):
        # "- **항목**: 긴설명" 패턴 찾기
        if (line.strip().startswith('- **') and '**:' in line and 
            not line.endswith('  ') and not line.endswith('  \n') and
            len(line.strip()) > 25):  # 25자 이상인 경우로 기준 완화
            
            # 콜론 뒤에 바로 텍스트가 오는 경우
            colon_pos = line.find('**:')
            if colon_pos != -1 and len(line[colon_pos + 3:].strip()) > 8:  # 8자 이상으로 기준 완화
                problems.append({
                    'type': 'bullet_item_no_linebreak',
                    'content': line.strip(),
                    'line': i + 1,
                    'issue': '불릿 포인트 항목의 설명이 긴 경우 줄바꿈이 필요합니다'
                })
    
    # 패턴 7: 레이어 이름 뒤 콜론 문제 - "meta:", "meta-poky:" 등
    for i, line in enumerate(lines):
        # "meta-xxx:" 패턴이나 단순 "meta:" 패턴 찾기
        if (('meta' in line.lower() and ':' in line and 
             not line.strip().startswith('#') and 
             not line.strip().startswith('- **meta') and
             len(line.strip()) > 10)):
            # 콜론 뒤에 바로 설명이 오는 경우
            if re.search(r'meta[^:]*:\s*[가-힣a-zA-Z]', line):
                problems.append({
                    'type': 'layer_name_colon_issue',
                    'content': line.strip(),
                    'line': i + 1,
                    'issue': '레이어 이름 뒤 콜론 다음에 바로 설명이 붙어있습니다'
                })
    
    return problems

def generate_html_and_test():
    """HTML을 생성하고 브라우저에서 테스트합니다."""
    print("🌐 HTML 생성 중...")
    
    # HTML 생성
    os.system("cd materials && ../scripts/generate-html.sh > /dev/null 2>&1")
    
    html_file = "materials/KEA-Yocto-Project-강의자료.html"
    if os.path.exists(html_file):
        print(f"✅ HTML 생성 완료: {html_file}")
        
        # HTML 내용 검사
        html_content = read_file(html_file)
        if html_content:
            return test_html_content(html_content)
    else:
        print(f"❌ HTML 파일을 찾을 수 없습니다: {html_file}")
    
    return []

def test_html_content(html_content):
    """HTML 내용에서 포맷팅 문제를 찾습니다."""
    print("🔍 HTML 내용 검사 중...")
    problems = []
    
    # <p> 태그 안에 테이블 내용이 있는지 확인
    table_in_p_pattern = r'<p[^>]*>[^<]*\|[^<]*\|[^<]*</p>'
    matches = re.finditer(table_in_p_pattern, html_content)
    
    for match in matches:
        problems.append({
            'type': 'table_in_paragraph',
            'content': match.group(0)[:100] + '...' if len(match.group(0)) > 100 else match.group(0),
            'issue': 'HTML에서 테이블이 <p> 태그로 렌더링되었습니다'
        })
    
    # 매우 긴 <p> 태그 찾기 (줄바꿈이 제대로 되지 않은 경우)
    long_p_pattern = r'<p[^>]*>[^<]{200,}</p>'
    matches = re.finditer(long_p_pattern, html_content)
    
    for match in matches:
        problems.append({
            'type': 'long_paragraph',
            'content': match.group(0)[:100] + '...',
            'issue': f'HTML에서 매우 긴 문단이 발견되었습니다 ({len(match.group(0))}자)'
        })
    
    return problems

def print_problems(problems, category):
    """문제점들을 출력합니다."""
    if not problems:
        print(f"✅ {category}: 문제 없음")
        return
    
    print(f"⚠️  {category}: {len(problems)}개 문제 발견")
    for i, problem in enumerate(problems, 1):
        print(f"  {i}. 라인 {problem.get('line', '?')}: {problem['issue']}")
        print(f"     내용: {problem['content']}")
        print()

def main():
    """메인 함수"""
    print("📚 KEA Yocto Project HTML 포맷팅 테스트")
    print("=" * 50)
    
    markdown_file = "materials/lecture-materials.md"
    
    if not os.path.exists(markdown_file):
        print(f"❌ 파일을 찾을 수 없습니다: {markdown_file}")
        return 1
    
    # Markdown 파일 읽기
    markdown_content = read_file(markdown_file)
    if not markdown_content:
        return 1
    
    # 각종 포맷팅 문제 검사
    all_problems = []
    
    # 1. 테이블 포맷팅 검사
    table_problems = test_table_formatting(markdown_content)
    all_problems.extend(table_problems)
    print_problems(table_problems, "테이블 포맷팅")
    
    # 2. 불릿 포인트 검사
    bullet_problems = test_bullet_point_formatting(markdown_content)
    all_problems.extend(bullet_problems)
    print_problems(bullet_problems, "불릿 포인트 포맷팅")
    
    # 3. 볼드 텍스트 검사
    bold_problems = test_bold_text_formatting(markdown_content)
    all_problems.extend(bold_problems)
    print_problems(bold_problems, "볼드 텍스트 포맷팅")
    
    # 4. 설명 텍스트 검사
    desc_problems = test_description_formatting(markdown_content)
    all_problems.extend(desc_problems)
    print_problems(desc_problems, "설명 텍스트 포맷팅")
    
    # 5. 특정 포맷팅 문제 검사 (새로 추가)
    specific_problems = test_specific_formatting_issues(markdown_content)
    all_problems.extend(specific_problems)
    print_problems(specific_problems, "특정 포맷팅 문제")
    
    # 6. 긴 줄 검사
    long_line_problems = test_long_line_formatting(markdown_content)
    all_problems.extend(long_line_problems)
    print_problems(long_line_problems, "긴 줄 포맷팅")
    
    # 7. HTML 생성 및 검사
    html_problems = generate_html_and_test()
    all_problems.extend(html_problems)
    print_problems(html_problems, "HTML 렌더링")
    
    # 결과 요약
    print("📊 테스트 결과 요약")
    print("=" * 30)
    
    if not all_problems:
        print("🎉 모든 테스트 통과! 포맷팅 문제가 없습니다.")
        return 0
    else:
        print(f"⚠️  총 {len(all_problems)}개의 포맷팅 문제 발견")
        
        # 문제 유형별 분류
        problem_types = {}
        for problem in all_problems:
            ptype = problem['type']
            if ptype not in problem_types:
                problem_types[ptype] = 0
            problem_types[ptype] += 1
        
        print("\n문제 유형별 분류:")
        for ptype, count in problem_types.items():
            print(f"  - {ptype}: {count}개")
        
        # 자동 수정 실행
        print(f"\n🔧 자동 수정을 시작합니다...")
        fixed_count = auto_fix_problems(markdown_file, all_problems)
        print(f"✅ {fixed_count}개 문제 자동 수정 완료!")
        
        # 수정 후 재테스트
        if fixed_count > 0:
            print("\n🔄 수정 후 재테스트 중...")
            # HTML 재생성
            os.system("cd materials && ../scripts/generate-html.sh > /dev/null 2>&1")
            print("📝 HTML 재생성 완료!")
        
        return len(all_problems) - fixed_count

def auto_fix_problems(markdown_file, problems):
    """발견된 문제들을 자동으로 수정합니다."""
    print("🔧 자동 수정 중...")
    
    with open(markdown_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    original_lines = lines.copy()
    fixed_count = 0
    
    # bullet_item_no_linebreak 문제들을 먼저 처리 (라인 번호가 변경되므로 역순으로 처리)
    bullet_problems = [p for p in problems if p['type'] == 'bullet_item_no_linebreak']
    bullet_problems.sort(key=lambda x: x['line'], reverse=True)  # 역순 정렬
    
    for problem in bullet_problems:
        line_num = problem['line']
        if line_num - 1 < len(lines):
            line = lines[line_num - 1]
            if '**:' in line:
                # "- **항목**: 설명" → "- **항목**:  " + "설명"으로 분리
                colon_pos = line.find('**:')
                if colon_pos != -1:
                    before_colon = line[:colon_pos + 3]  # "- **항목**: " 부분
                    after_colon = line[colon_pos + 3:].strip()  # 설명 부분
                    
                    if after_colon:  # 설명이 있는 경우만 처리
                        # 줄바꿈으로 분리
                        lines[line_num - 1] = before_colon.rstrip() + '  \n'
                        lines.insert(line_num, '  ' + after_colon + '\n')
                        fixed_count += 1
    
    # 다른 문제 유형들 처리
    for problem in problems:
        if problem['type'] == 'inline_descriptions':
            # "항목: 설명 - 항목: 설명" → 줄바꿈으로 분리
            old_text = problem['content']
            # " - " 를 "\n- "로 교체
            new_text = old_text.replace(' - ', '\n- ')
            content = ''.join(lines)
            if old_text in content:
                content = content.replace(old_text, new_text)
                lines = content.split('\n')
                lines = [line + '\n' if not line.endswith('\n') and line else line for line in lines]
                fixed_count += 1
        
        elif problem['type'] == 'connected_bullet_points':
            # 연결된 불릿 포인트 분리
            old_text = problem['content']
            new_text = old_text.replace(' - **', '\n- **')
            content = ''.join(lines)
            if old_text in content:
                content = content.replace(old_text, new_text)
                lines = content.split('\n')
                lines = [line + '\n' if not line.endswith('\n') and line else line for line in lines]
                fixed_count += 1
        
        elif problem['type'] == 'bullet_sub_items_no_linebreak':
            # 불릿 포인트 서브 항목들에 2개 스페이스 추가
            if 'sub_lines' in problem:
                for line_num in problem['sub_lines']:
                    if line_num - 1 < len(lines):
                        line = lines[line_num - 1]
                        if line.strip().startswith('  -') and not line.rstrip().endswith('  '):
                            # 줄 끝에 2개 스페이스 추가
                            lines[line_num - 1] = line.rstrip() + '  \n'
                            fixed_count += 1
        
        elif problem['type'] == 'layer_name_colon_issue':
            # 레이어 이름 뒤 콜론 문제 수정
            line_num = problem['line']
            if line_num - 1 < len(lines):
                line = lines[line_num - 1]
                # "meta-xxx: 설명" → "meta-xxx:\n  설명" 형태로 변경
                if re.search(r'meta[^:]*:\s*[가-힣a-zA-Z]', line):
                    # 콜론 뒤의 공백과 텍스트를 찾아서 분리
                    match = re.search(r'(meta[^:]*:)\s*(.+)', line)
                    if match:
                        layer_name = match.group(1)
                        description = match.group(2)
                        # 줄바꿈으로 분리
                        lines[line_num - 1] = layer_name + '\n' + description + '\n'
                        fixed_count += 1
        
        elif problem['type'] == 'long_bullet_description':
            # 긴 불릿 포인트 설명 줄바꿈 추가
            line_num = problem['line']
            if line_num - 1 < len(lines):
                line = lines[line_num - 1]
                if ':' in line and len(line.strip()) > 60:
                    # 콜론 뒤에서 분리
                    colon_pos = line.find(':')
                    if colon_pos != -1:
                        before_colon = line[:colon_pos + 1]  # "- 항목:" 부분
                        after_colon = line[colon_pos + 1:].strip()  # 설명 부분
                        
                        if after_colon:  # 설명이 있는 경우만 처리
                            # 줄바꿈으로 분리
                            lines[line_num - 1] = before_colon + '  \n  ' + after_colon + '\n'
                            fixed_count += 1
    
    # 내용이 변경되었으면 파일에 저장
    if lines != original_lines:
        with open(markdown_file, 'w', encoding='utf-8') as f:
            f.writelines(lines)
        print(f"📝 파일 업데이트 완료: {markdown_file}")
    
    return fixed_count

if __name__ == "__main__":
    sys.exit(main()) 
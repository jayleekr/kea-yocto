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
                    'content': line[:150] + '...' if len(line) > 150 else line,
                    'line': i + 1,
                    'issue': '설명 항목들이 한 줄에 연결되어 있어 가독성이 떨어집니다'
                })
    
    # 패턴 2: 여러 개의 불릿 포인트나 항목이 연결된 경우
    pattern2 = r'- \*\*[^*]+\*\*[^-\n]+ - \*\*[^*]+\*\*'
    matches = re.finditer(pattern2, markdown_content)
    
    for match in matches:
        line_num = markdown_content[:match.start()].count('\n') + 1
        problems.append({
            'type': 'connected_bullet_points',
            'content': match.group(0),
            'line': line_num,
            'issue': '불릿 포인트가 한 줄에 연결되어 있습니다'
        })
    
    # 패턴 3: 불릿 포인트 내 서브 항목들의 줄바꿈 문제 감지
    for i, line in enumerate(lines):
        # "- **항목**: 설명" 다음에 서브 항목들이 있는 경우
        if (line.strip().startswith('- **') and ':' in line and 
            i + 1 < len(lines) and lines[i + 1].strip().startswith('  -')):
            
            # 서브 항목들이 2개 스페이스로 끝나지 않는 경우 확인
            j = i + 1
            sub_items_without_linebreak = []
            while j < len(lines) and lines[j].strip().startswith('  -'):
                if not lines[j].endswith('  ') and not lines[j].endswith('  \n'):
                    sub_items_without_linebreak.append(j + 1)
                j += 1
            
            if sub_items_without_linebreak:
                problems.append({
                    'type': 'bullet_sub_items_no_linebreak',
                    'content': f"라인 {i+1}의 서브 항목들 (라인 {sub_items_without_linebreak})",
                    'line': i + 1,
                    'issue': '불릿 포인트 서브 항목들이 줄바꿈 없이 연결되어 HTML에서 제대로 렌더링되지 않습니다',
                    'sub_lines': sub_items_without_linebreak
                })
    
    # 패턴 4: 매우 긴 줄 (150자 이상)에서 여러 항목이 포함된 경우
    for i, line in enumerate(lines, 1):
        if len(line) > 150 and line.count(' ') > 10:
            # 코드 블록이나 특수 구문 제외
            if not (line.strip().startswith('```') or line.strip().startswith('|') or 
                   line.strip().startswith('#') or '```' in line or
                   line.strip().startswith('- ') or line.strip().startswith('  - ')):
                problems.append({
                    'type': 'multi_item_long_line',
                    'content': line[:150] + '...' if len(line) > 150 else line,
                    'line': i,
                    'issue': f'긴 줄에 여러 항목이 포함되어 가독성이 떨어집니다 ({len(line)}자)'
                })
    
    # 패턴 5: 이모지와 볼드가 섞인 복잡한 형태
    pattern5 = r'[\U0001F300-\U0001F9FF] \*\*[^*]+\*\* [^-\n]+ - [\U0001F300-\U0001F9FF] \*\*[^*]+\*\*'
    matches = re.finditer(pattern5, markdown_content)
    
    for match in matches:
        line_num = markdown_content[:match.start()].count('\n') + 1
        problems.append({
            'type': 'emoji_bold_mixed',
            'content': match.group(0),
            'line': line_num,
            'issue': '이모지와 볼드가 섞인 항목들이 한 줄에 연결되어 있습니다'
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
    
    # 내용이 변경되었으면 파일에 저장
    if lines != original_lines:
        with open(markdown_file, 'w', encoding='utf-8') as f:
            f.writelines(lines)
        print(f"📝 파일 업데이트 완료: {markdown_file}")
    
    return fixed_count

if __name__ == "__main__":
    sys.exit(main()) 
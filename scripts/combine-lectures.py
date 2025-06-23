#!/usr/bin/env python3

import os
import sys

def combine_lectures():
    """모든 강의 파일을 하나로 합치는 함수"""
    
    # 강의 파일 순서대로 정의
    lecture_files = [
        'docs/index.md',
        'docs/lecture/intro.md',
        'docs/lecture/architecture.md', 
        'docs/lecture/setup.md',
        'docs/lecture/first-build.md',
        'docs/lecture/run-image.md',
        'docs/lecture/customize.md',
        'docs/lecture/custom-layer.md',
        'docs/lecture/advanced.md',
        'docs/lecture/conclusion.md'
    ]
    
    combined_content = []
    
    # 제목과 메타데이터 추가
    combined_content.append("# KEA Yocto Project 5.0 LTS 강의 - 전체 문서\n")
    combined_content.append("이 문서는 모든 강의 내용을 하나로 합친 통합 문서입니다.\n\n")
    combined_content.append("---\n\n")
    
    for i, file_path in enumerate(lecture_files):
        if os.path.exists(file_path):
            print(f"📄 처리 중: {file_path}")
            
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # 첫 번째 파일(index.md)이 아닌 경우 페이지 구분선 추가
            if i > 0:
                combined_content.append("\n\n---\n\n<div style='page-break-before: always;'></div>\n\n")
            
            # 파일 제목 추가 (파일명 기반)
            if file_path != 'docs/index.md':
                filename = os.path.basename(file_path).replace('.md', '')
                section_title = get_section_title(filename)
                combined_content.append(f"# {section_title}\n\n")
            
            combined_content.append(content)
            combined_content.append("\n\n")
        else:
            print(f"⚠️  파일을 찾을 수 없습니다: {file_path}")
    
    # 통합 파일 생성
    output_file = 'docs/all-lectures.md'
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(''.join(combined_content))
    
    print(f"✅ 통합 파일 생성 완료: {output_file}")
    return output_file

def get_section_title(filename):
    """파일명을 기반으로 섹션 제목 생성"""
    title_map = {
        'intro': '1. Yocto Project 소개',
        'architecture': '2. 아키텍처 이해', 
        'setup': '3. 환경 설정',
        'first-build': '4. 첫 번째 빌드',
        'run-image': '5. 이미지 실행',
        'customize': '6. 이미지 커스터마이징',
        'custom-layer': '7. 커스텀 레이어 생성',
        'advanced': '8. 고급 기능',
        'conclusion': '9. 마무리'
    }
    return title_map.get(filename, filename.title())

if __name__ == "__main__":
    print("🔄 Yocto 강의 파일 통합 시작...")
    try:
        output_file = combine_lectures()
        print(f"🎉 성공! 통합 파일: {output_file}")
        print("📝 이제 mkdocs.yml에 이 파일을 추가하고 다시 빌드하세요.")
    except Exception as e:
        print(f"❌ 오류 발생: {e}")
        sys.exit(1) 
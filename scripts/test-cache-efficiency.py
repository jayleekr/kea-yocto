#!/usr/bin/env python3
"""
Yocto 캐시 효율성 테스트 스크립트

이 스크립트는 Yocto 빌드에서 sstate-cache와 downloads 캐시가 
제대로 작동하는지 검증하고 빌드 시간을 측정합니다.
"""

import os
import sys
import time
import json
import logging
import argparse
import subprocess
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, List, Tuple, Optional
import re

# 로깅 설정
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('cache-test.log')
    ]
)
logger = logging.getLogger(__name__)

class YoctoCacheTest:
    """Yocto 캐시 효율성 테스트 클래스"""
    
    def __init__(self, workspace_dir: str = "./yocto-workspace", docker_image: str = "jabang3/yocto-lecture:5.0-lts"):
        self.workspace_dir = Path(workspace_dir).resolve()
        self.docker_image = docker_image
        self.downloads_dir = self.workspace_dir / "downloads"
        self.sstate_dir = self.workspace_dir / "sstate-cache"
        self.test_results = []
        
        # 테스트 대상 이미지들
        self.test_targets = [
            "core-image-minimal",
            "core-image-base"
        ]
        
        # Docker 실행 설정
        self.docker_run_base = [
            "docker", "run", "--rm",
            "-v", f"{self.downloads_dir}:/opt/yocto/downloads",
            "-v", f"{self.sstate_dir}:/opt/yocto/sstate-cache",
            "-e", "BB_NUMBER_THREADS=4",
            "-e", "PARALLEL_MAKE=-j 4",
            "-e", "MACHINE=qemux86-64"
        ]
        
    def setup_workspace(self) -> bool:
        """작업공간 디렉토리 설정"""
        try:
            self.workspace_dir.mkdir(exist_ok=True)
            self.downloads_dir.mkdir(exist_ok=True)
            self.sstate_dir.mkdir(exist_ok=True)
            logger.info(f"작업공간 설정 완료: {self.workspace_dir}")
            return True
        except Exception as e:
            logger.error(f"작업공간 설정 실패: {e}")
            return False
    
    def check_docker_image(self) -> bool:
        """Docker 이미지 존재 확인"""
        try:
            result = subprocess.run(
                ["docker", "image", "inspect", self.docker_image],
                capture_output=True, text=True, check=True
            )
            logger.info(f"Docker 이미지 확인: {self.docker_image}")
            return True
        except subprocess.CalledProcessError:
            logger.error(f"Docker 이미지가 없습니다: {self.docker_image}")
            logger.info("다음 명령으로 이미지를 다운로드하세요:")
            logger.info(f"docker pull {self.docker_image}")
            return False
    
    def get_cache_stats(self) -> Dict[str, int]:
        """캐시 디렉토리 통계 수집"""
        stats = {}
        
        try:
            # Downloads 캐시 통계
            if self.downloads_dir.exists():
                downloads_files = list(self.downloads_dir.rglob("*"))
                stats['downloads_files'] = len([f for f in downloads_files if f.is_file()])
                downloads_size = sum(f.stat().st_size for f in downloads_files if f.is_file())
                stats['downloads_size_mb'] = downloads_size // (1024 * 1024)
            else:
                stats['downloads_files'] = 0
                stats['downloads_size_mb'] = 0
                
            # sstate 캐시 통계
            if self.sstate_dir.exists():
                sstate_files = list(self.sstate_dir.rglob("*.siginfo"))
                stats['sstate_signatures'] = len(sstate_files)
                sstate_objects = list(self.sstate_dir.rglob("*.tgz"))
                stats['sstate_objects'] = len(sstate_objects)
                sstate_size = sum(f.stat().st_size for f in self.sstate_dir.rglob("*") if f.is_file())
                stats['sstate_size_mb'] = sstate_size // (1024 * 1024)
            else:
                stats['sstate_signatures'] = 0
                stats['sstate_objects'] = 0
                stats['sstate_size_mb'] = 0
                
        except Exception as e:
            logger.error(f"캐시 통계 수집 실패: {e}")
            
        return stats
    
    def parse_build_log(self, log_output: str) -> Dict[str, any]:
        """빌드 로그에서 캐시 히트 정보 추출"""
        stats = {
            'sstate_hits': 0,
            'sstate_misses': 0,
            'tasks_from_sstate': 0,
            'tasks_executed': 0,
            'downloaded_files': 0
        }
        
        try:
            # sstate 캐시 히트 검색
            sstate_hit_pattern = r"Sstate summary: Wanted (\d+) Found (\d+) Missed (\d+)"
            match = re.search(sstate_hit_pattern, log_output)
            if match:
                wanted = int(match.group(1))
                found = int(match.group(2))
                missed = int(match.group(3))
                stats['sstate_hits'] = found
                stats['sstate_misses'] = missed
                stats['sstate_hit_rate'] = (found / wanted * 100) if wanted > 0 else 0
            
            # 실행된 태스크 수 검색
            task_pattern = r"NOTE: Tasks Summary: Attempted (\d+) tasks of which (\d+) didn't need to be rerun"
            match = re.search(task_pattern, log_output)
            if match:
                attempted = int(match.group(1))
                cached = int(match.group(2))
                stats['tasks_executed'] = attempted - cached
                stats['tasks_from_sstate'] = cached
                stats['task_cache_rate'] = (cached / attempted * 100) if attempted > 0 else 0
            
            # 다운로드된 파일 수 검색
            download_pattern = r"Downloaded (\d+) files"
            downloads = re.findall(download_pattern, log_output)
            stats['downloaded_files'] = sum(int(d) for d in downloads)
            
        except Exception as e:
            logger.error(f"빌드 로그 파싱 실패: {e}")
            
        return stats
    
    def run_build_test(self, target: str, test_name: str, clean_tmp: bool = False) -> Dict[str, any]:
        """단일 빌드 테스트 실행"""
        logger.info(f"🚀 {test_name} 시작: {target}")
        
        # 빌드 전 캐시 상태
        cache_before = self.get_cache_stats()
        
        # 빌드 명령 구성
        build_cmd = self.docker_run_base + [
            self.docker_image,
            "/bin/bash", "-c", f"""
                set -eo pipefail
                set +u
                source /opt/poky/oe-init-build-env /tmp/test-build
                set -u
                
                echo "=== 빌드 시작: {target} ==="
                echo "캐시 상태 확인:"
                echo "Downloads: $(find /opt/yocto/downloads -type f | wc -l) files"
                echo "sstate: $(find /opt/yocto/sstate-cache -name '*.siginfo' | wc -l) signatures"
                
                {"rm -rf /tmp/test-build/tmp" if clean_tmp else ""}
                
                start_time=$(date +%s)
                echo "빌드 시작 시간: $(date)"
                
                if bitbake {target}; then
                    end_time=$(date +%s)
                    duration=$((end_time - start_time))
                    echo "=== 빌드 완료: {target} ==="
                    echo "소요 시간: ${{duration}}초"
                    echo "빌드 종료 시간: $(date)"
                else
                    echo "=== 빌드 실패: {target} ==="
                    exit 1
                fi
            """
        ]
        
        # 빌드 실행
        start_time = time.time()
        try:
            result = subprocess.run(
                build_cmd,
                capture_output=True,
                text=True,
                timeout=7200  # 2시간 타임아웃
            )
            
            end_time = time.time()
            duration = end_time - start_time
            
            if result.returncode == 0:
                logger.info(f"✅ {test_name} 성공 (소요 시간: {duration:.1f}초)")
                success = True
            else:
                logger.error(f"❌ {test_name} 실패")
                logger.error(f"에러: {result.stderr}")
                success = False
                
        except subprocess.TimeoutExpired:
            logger.error(f"⏰ {test_name} 타임아웃 (2시간 초과)")
            success = False
            duration = 7200
            result = subprocess.CompletedProcess(build_cmd, 1, "", "Timeout")
        
        # 빌드 후 캐시 상태
        cache_after = self.get_cache_stats()
        
        # 로그 분석
        build_stats = self.parse_build_log(result.stdout) if success else {}
        
        # 결과 정리
        test_result = {
            'test_name': test_name,
            'target': target,
            'success': success,
            'duration_seconds': duration,
            'duration_minutes': duration / 60,
            'cache_before': cache_before,
            'cache_after': cache_after,
            'build_stats': build_stats,
            'timestamp': datetime.now().isoformat(),
            'stdout': result.stdout if success else "",
            'stderr': result.stderr
        }
        
        self.test_results.append(test_result)
        return test_result
    
    def clean_build_dirs(self):
        """빌드 임시 디렉토리 정리 (캐시는 유지)"""
        logger.info("빌드 임시 디렉토리 정리 중...")
        try:
            subprocess.run([
                "docker", "run", "--rm",
                "-v", f"{self.workspace_dir}:/workspace",
                self.docker_image,
                "/bin/bash", "-c", "rm -rf /workspace/*/tmp /workspace/*/cache"
            ], check=True, capture_output=True)
        except subprocess.CalledProcessError as e:
            logger.warning(f"임시 디렉토리 정리 실패: {e}")
    
    def run_full_cache_test(self, iterations: int = 2) -> Dict[str, any]:
        """전체 캐시 효율성 테스트 실행"""
        logger.info(f"=== Yocto 캐시 효율성 테스트 시작 (반복: {iterations}회) ===")
        
        if not self.setup_workspace():
            return {"error": "작업공간 설정 실패"}
        
        if not self.check_docker_image():
            return {"error": "Docker 이미지 확인 실패"}
        
        overall_results = {
            'test_start_time': datetime.now().isoformat(),
            'iterations': iterations,
            'targets': self.test_targets,
            'docker_image': self.docker_image,
            'workspace_dir': str(self.workspace_dir),
            'test_results': [],
            'performance_analysis': {}
        }
        
        for target in self.test_targets:
            target_results = []
            
            for i in range(iterations):
                # 첫 번째 빌드는 clean build, 나머지는 incremental
                clean_tmp = (i == 0)
                test_name = f"{target}_build_{i+1}"
                if i == 0:
                    test_name += "_clean"
                else:
                    test_name += "_incremental"
                
                # 빌드 실행
                result = self.run_build_test(target, test_name, clean_tmp=clean_tmp)
                target_results.append(result)
                
                # 빌드 간 약간의 대기 시간
                if i < iterations - 1:
                    time.sleep(5)
            
            overall_results['test_results'].extend(target_results)
            
            # 성능 분석
            if len(target_results) >= 2 and all(r['success'] for r in target_results):
                first_build_time = target_results[0]['duration_seconds']
                second_build_time = target_results[1]['duration_seconds']
                speedup_ratio = first_build_time / second_build_time
                time_saved = first_build_time - second_build_time
                
                overall_results['performance_analysis'][target] = {
                    'first_build_time': first_build_time,
                    'second_build_time': second_build_time,
                    'speedup_ratio': speedup_ratio,
                    'time_saved_seconds': time_saved,
                    'time_saved_minutes': time_saved / 60,
                    'efficiency_percentage': ((time_saved / first_build_time) * 100)
                }
                
                logger.info(f"📊 {target} 성능 분석:")
                logger.info(f"   첫 빌드: {first_build_time/60:.1f}분")
                logger.info(f"   두 번째 빌드: {second_build_time/60:.1f}분")
                logger.info(f"   속도 향상: {speedup_ratio:.1f}배")
                logger.info(f"   시간 절약: {time_saved/60:.1f}분 ({time_saved/first_build_time*100:.1f}%)")
        
        overall_results['test_end_time'] = datetime.now().isoformat()
        return overall_results
    
    def save_results(self, results: Dict[str, any], filename: str = None):
        """테스트 결과 저장"""
        if filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"cache_test_results_{timestamp}.json"
        
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(results, f, indent=2, ensure_ascii=False)
        
        logger.info(f"테스트 결과 저장: {filename}")
    
    def generate_report(self, results: Dict[str, any]) -> str:
        """테스트 결과 리포트 생성"""
        report = []
        report.append("=" * 60)
        report.append("🧪 Yocto 캐시 효율성 테스트 결과 리포트")
        report.append("=" * 60)
        report.append("")
        
        # 기본 정보
        report.append(f"📅 테스트 시간: {results['test_start_time']}")
        report.append(f"🎯 테스트 대상: {', '.join(results['targets'])}")
        report.append(f"🔄 반복 횟수: {results['iterations']}회")
        report.append(f"🐳 Docker 이미지: {results['docker_image']}")
        report.append("")
        
        # 성능 분석
        if 'performance_analysis' in results:
            report.append("📊 성능 분석 결과:")
            report.append("-" * 40)
            
            for target, perf in results['performance_analysis'].items():
                report.append(f"\n🎯 {target}:")
                report.append(f"   첫 번째 빌드: {perf['first_build_time']/60:.1f}분")
                report.append(f"   두 번째 빌드: {perf['second_build_time']/60:.1f}분")
                report.append(f"   속도 향상: {perf['speedup_ratio']:.1f}배")
                report.append(f"   시간 절약: {perf['time_saved_minutes']:.1f}분")
                report.append(f"   효율성: {perf['efficiency_percentage']:.1f}%")
                
                # 캐시 효율성 평가
                if perf['efficiency_percentage'] >= 80:
                    status = "✅ 매우 우수"
                elif perf['efficiency_percentage'] >= 60:
                    status = "🟡 양호"
                elif perf['efficiency_percentage'] >= 40:
                    status = "🟠 보통"
                else:
                    status = "❌ 개선 필요"
                
                report.append(f"   평가: {status}")
        
        # 상세 빌드 결과
        report.append("\n📋 상세 빌드 결과:")
        report.append("-" * 40)
        
        for result in results['test_results']:
            status = "✅" if result['success'] else "❌"
            report.append(f"\n{status} {result['test_name']}")
            report.append(f"   소요 시간: {result['duration_minutes']:.1f}분")
            
            if 'build_stats' in result and result['build_stats']:
                stats = result['build_stats']
                if 'sstate_hit_rate' in stats:
                    report.append(f"   sstate 히트율: {stats['sstate_hit_rate']:.1f}%")
                if 'task_cache_rate' in stats:
                    report.append(f"   태스크 캐시율: {stats['task_cache_rate']:.1f}%")
        
        report.append("")
        report.append("=" * 60)
        
        return "\n".join(report)

def main():
    parser = argparse.ArgumentParser(description="Yocto 캐시 효율성 테스트")
    parser.add_argument("--workspace", default="./yocto-workspace", 
                       help="Yocto 작업공간 디렉토리 (기본값: ./yocto-workspace)")
    parser.add_argument("--image", default="jabang3/yocto-lecture:5.0-lts",
                       help="Docker 이미지 (기본값: jabang3/yocto-lecture:5.0-lts)")
    parser.add_argument("--iterations", type=int, default=2,
                       help="빌드 반복 횟수 (기본값: 2)")
    parser.add_argument("--targets", nargs="+", 
                       default=["core-image-minimal"],
                       help="빌드 대상 (기본값: core-image-minimal)")
    parser.add_argument("--output", help="결과 파일명")
    parser.add_argument("--report", action="store_true",
                       help="콘솔에 리포트 출력")
    
    args = parser.parse_args()
    
    # 테스트 실행
    tester = YoctoCacheTest(args.workspace, args.image)
    tester.test_targets = args.targets
    
    try:
        results = tester.run_full_cache_test(args.iterations)
        
        if "error" in results:
            logger.error(f"테스트 실패: {results['error']}")
            sys.exit(1)
        
        # 결과 저장
        tester.save_results(results, args.output)
        
        # 리포트 출력
        if args.report:
            report = tester.generate_report(results)
            print(report)
        
        # 종합 평가
        if 'performance_analysis' in results:
            avg_efficiency = sum(p['efficiency_percentage'] 
                               for p in results['performance_analysis'].values()) / len(results['performance_analysis'])
            
            if avg_efficiency >= 80:
                logger.info("🎉 캐시 시스템이 매우 효율적으로 작동하고 있습니다!")
            elif avg_efficiency >= 60:
                logger.info("✅ 캐시 시스템이 잘 작동하고 있습니다.")
            else:
                logger.warning("⚠️  캐시 효율성이 낮습니다. 설정을 확인해주세요.")
        
    except KeyboardInterrupt:
        logger.info("테스트가 사용자에 의해 중단되었습니다.")
        sys.exit(1)
    except Exception as e:
        logger.error(f"테스트 중 오류 발생: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main() 
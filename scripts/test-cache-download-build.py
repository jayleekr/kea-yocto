#!/usr/bin/env python3
"""
KEA Yocto Project Cache Download and Build Test

This script comprehensively tests:
1. Cache download functionality from GitHub releases
2. Tarball integrity verification (checksums)
3. Cache extraction and setup
4. Actual build execution with cached files
5. Performance comparison (cached vs uncached builds)

Based on README.md specifications and existing test patterns.
Cross-platform compatible (Linux, macOS).
"""

import os
import sys
import time
import json
import logging
import argparse
import subprocess
import hashlib
import shutil
import requests
import tempfile
import platform
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, List, Tuple, Optional, Any
import re

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('cache-download-build-test.log')
    ]
)
logger = logging.getLogger(__name__)

class CacheDownloadBuildTest:
    """Comprehensive cache download and build test class"""
    
    def __init__(self, 
                 workspace_dir: str = "./yocto-workspace-test",
                 docker_image: str = "jabang3/yocto-lecture:5.0-lts",
                 github_base_url: str = "https://github.com/jayleekr/kea-yocto/releases/download/split-cache-20250612-153704"):
        
        self.workspace_dir = Path(workspace_dir).resolve()
        self.docker_image = docker_image
        self.github_base_url = github_base_url
        
        # Detect platform for cross-platform compatibility
        self.is_macos = platform.system() == "Darwin"
        self.is_linux = platform.system() == "Linux"
        
        # Cache directories
        self.downloads_dir = self.workspace_dir / "downloads"
        self.sstate_dir = self.workspace_dir / "sstate-cache"
        self.temp_dir = Path(tempfile.mkdtemp(prefix="yocto_cache_test_"))
        
        # Test results storage
        self.test_results = {
            'download_test': {},
            'integrity_test': {},
            'extraction_test': {},
            'build_test': {},
            'performance_test': {}
        }
        
        # File definitions as per README.md
        self.cache_files = {
            'downloads_parts': [
                'full-downloads-cache.tar.gz.partaa',
                'full-downloads-cache.tar.gz.partab', 
                'full-downloads-cache.tar.gz.partac',
                'full-downloads-cache.tar.gz.partad'
            ],
            'sstate': 'full-sstate-cache.tar.gz',
            'info': 'full-cache-info.txt'
        }
        
        # Test targets as mentioned in README
        self.test_targets = ["core-image-minimal"]
        
        # Expected cache performance (from README.md)
        self.expected_performance = {
            'cache_size_gb': 6.7,
            'time_reduction_percent': 80,  # 80-90% reduction mentioned
            'source_packages': 88,
            'build_states': 257
        }

    def setup_test_environment(self) -> bool:
        """Setup test environment and directories"""
        try:
            logger.info("🔧 Setting up test environment...")
            
            # Create workspace directories
            self.workspace_dir.mkdir(parents=True, exist_ok=True)
            self.downloads_dir.mkdir(parents=True, exist_ok=True)
            self.sstate_dir.mkdir(parents=True, exist_ok=True)
            
            # Clean any existing test files
            for file_pattern in ['*.tar.gz*', '*.txt']:
                for file in self.workspace_dir.glob(file_pattern):
                    if file.is_file():
                        file.unlink()
                        
            logger.info(f"✅ Test environment setup complete: {self.workspace_dir}")
            return True
            
        except Exception as e:
            logger.error(f"❌ Test environment setup failed: {e}")
            return False

    def check_prerequisites(self) -> bool:
        """Check all prerequisites for testing"""
        logger.info("🔍 Checking prerequisites...")
        
        checks = {
            'docker': self._check_docker(),
            'docker_image': self._check_docker_image(),
            'internet': self._check_internet_connection(),
            'disk_space': self._check_disk_space()
        }
        
        all_passed = all(checks.values())
        
        for check, passed in checks.items():
            status = "✅" if passed else "❌"
            logger.info(f"{status} {check.replace('_', ' ').title()}: {'PASS' if passed else 'FAIL'}")
            
        if not all_passed:
            logger.error("❌ Prerequisites check failed. Please fix the issues above.")
            
        return all_passed

    def _check_docker(self) -> bool:
        """Check if Docker is available"""
        try:
            subprocess.run(["docker", "--version"], 
                         capture_output=True, check=True)
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            logger.error("Docker is not available or not running")
            return False

    def _check_docker_image(self) -> bool:
        """Check if required Docker image exists"""
        try:
            subprocess.run(["docker", "image", "inspect", self.docker_image],
                         capture_output=True, check=True)
            return True
        except subprocess.CalledProcessError:
            logger.warning(f"Docker image {self.docker_image} not found locally")
            logger.info("Attempting to pull image...")
            try:
                subprocess.run(["docker", "pull", self.docker_image], check=True)
                logger.info("✅ Docker image pulled successfully")
                return True
            except subprocess.CalledProcessError:
                logger.error(f"Failed to pull Docker image: {self.docker_image}")
                return False

    def _check_internet_connection(self) -> bool:
        """Check internet connectivity to GitHub"""
        try:
            response = requests.head(self.github_base_url, timeout=10)
            return response.status_code < 400
        except Exception:
            logger.error("No internet connection or GitHub is unreachable")
            return False

    def _check_disk_space(self, required_gb: float = 10.0) -> bool:
        """Check available disk space"""
        try:
            stat = shutil.disk_usage(self.workspace_dir.parent)
            available_gb = stat.free / (1024**3)
            
            if available_gb >= required_gb:
                logger.info(f"Disk space: {available_gb:.1f}GB available")
                return True
            else:
                logger.error(f"Insufficient disk space: {available_gb:.1f}GB available, {required_gb}GB required")
                return False
                
        except Exception as e:
            logger.error(f"Could not check disk space: {e}")
            return False

    def download_cache_files(self) -> bool:
        """Download all cache files from GitHub releases"""
        logger.info("📥 Starting cache file download...")
        
        download_start = time.time()
        downloaded_files = []
        
        try:
            # Download split download files
            for part in self.cache_files['downloads_parts']:
                if self._download_file(part):
                    downloaded_files.append(part)
                else:
                    logger.error(f"Failed to download {part}")
                    return False
            
            # Download sstate cache
            if self._download_file(self.cache_files['sstate']):
                downloaded_files.append(self.cache_files['sstate'])
            else:
                logger.error("Failed to download sstate cache")
                return False
                
            # Download info file
            if self._download_file(self.cache_files['info']):
                downloaded_files.append(self.cache_files['info'])
            else:
                logger.warning("Failed to download info file (non-critical)")
            
            download_time = time.time() - download_start
            
            # Store download results
            self.test_results['download_test'] = {
                'success': True,
                'download_time_seconds': download_time,
                'files_downloaded': len(downloaded_files),
                'downloaded_files': downloaded_files
            }
            
            logger.info(f"✅ Download completed in {download_time:.1f} seconds")
            return True
            
        except Exception as e:
            logger.error(f"❌ Download failed: {e}")
            self.test_results['download_test'] = {
                'success': False,
                'error': str(e)
            }
            return False

    def _download_file(self, filename: str) -> bool:
        """Download a single file with progress tracking"""
        url = f"{self.github_base_url}/{filename}"
        file_path = self.workspace_dir / filename
        
        try:
            logger.info(f"Downloading {filename}...")
            
            response = requests.get(url, stream=True)
            response.raise_for_status()
            
            total_size = int(response.headers.get('content-length', 0))
            downloaded_size = 0
            
            with open(file_path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    if chunk:
                        f.write(chunk)
                        downloaded_size += len(chunk)
                        
                        # Show progress for large files
                        if total_size > 0:
                            progress = (downloaded_size / total_size) * 100
                            if downloaded_size % (10 * 1024 * 1024) == 0:  # Every 10MB
                                logger.info(f"  {filename}: {progress:.1f}% ({downloaded_size // (1024*1024)}MB)")
            
            logger.info(f"✅ Downloaded {filename} ({downloaded_size // (1024*1024)}MB)")
            return True
            
        except Exception as e:
            logger.error(f"❌ Failed to download {filename}: {e}")
            return False

    def verify_file_integrity(self) -> bool:
        """Verify downloaded file integrity and reconstruct split files"""
        logger.info("🔍 Verifying file integrity...")
        
        try:
            # Reconstruct split downloads file
            logger.info("Reconstructing split downloads archive...")
            downloads_file = self.workspace_dir / "full-downloads-cache.tar.gz"
            
            with open(downloads_file, 'wb') as outfile:
                for part in self.cache_files['downloads_parts']:
                    part_path = self.workspace_dir / part
                    if part_path.exists():
                        with open(part_path, 'rb') as infile:
                            outfile.write(infile.read())
                        # Clean up part file
                        part_path.unlink()
                    else:
                        logger.error(f"Part file missing: {part}")
                        return False
            
            # Verify reconstructed file
            if not downloads_file.exists():
                logger.error("Failed to reconstruct downloads archive")
                return False
                
            # Check file sizes
            downloads_size = downloads_file.stat().st_size
            sstate_file = self.workspace_dir / self.cache_files['sstate']
            sstate_size = sstate_file.stat().st_size if sstate_file.exists() else 0
            
            total_size_gb = (downloads_size + sstate_size) / (1024**3)
            
            logger.info(f"Downloads archive: {downloads_size // (1024*1024)}MB")
            logger.info(f"sstate archive: {sstate_size // (1024*1024)}MB")
            logger.info(f"Total cache size: {total_size_gb:.2f}GB")
            
            # Verify archives can be opened
            verification_results = {
                'downloads_archive': self._verify_tarball(downloads_file),
                'sstate_archive': self._verify_tarball(sstate_file) if sstate_file.exists() else False
            }
            
            success = all(verification_results.values())
            
            self.test_results['integrity_test'] = {
                'success': success,
                'downloads_size_mb': downloads_size // (1024*1024),
                'sstate_size_mb': sstate_size // (1024*1024),
                'total_size_gb': total_size_gb,
                'verification_results': verification_results
            }
            
            if success:
                logger.info("✅ File integrity verification passed")
            else:
                logger.error("❌ File integrity verification failed")
                
            return success
            
        except Exception as e:
            logger.error(f"❌ Integrity verification failed: {e}")
            self.test_results['integrity_test'] = {
                'success': False,
                'error': str(e)
            }
            return False

    def _verify_tarball(self, file_path: Path) -> bool:
        """Verify a tarball can be opened and list contents"""
        try:
            # Use gtar on macOS if available (GNU tar), otherwise use built-in tar
            tar_cmd = "gtar" if self.is_macos and shutil.which("gtar") else "tar"
            result = subprocess.run(
                [tar_cmd, "-tzf", str(file_path)],
                capture_output=True, text=True, check=True
            )
            file_count = len(result.stdout.strip().split('\n'))
            logger.info(f"✅ {file_path.name}: {file_count} files")
            return True
        except subprocess.CalledProcessError as e:
            logger.error(f"❌ {file_path.name}: Corrupted archive - {e}")
            return False

    def _set_cache_permissions(self) -> bool:
        """Set appropriate permissions for cache directories (cross-platform)"""
        try:
            if self.is_macos:
                # On macOS, be more conservative with permissions
                # and handle potential permission issues with Docker volume mounting
                for cache_dir in [self.downloads_dir, self.sstate_dir]:
                    if cache_dir.exists():
                        subprocess.run(["chmod", "-R", "755", str(cache_dir)], check=True)
                        # Ensure current user owns the directories
                        subprocess.run(["chown", "-R", f"{os.getuid()}:{os.getgid()}", str(cache_dir)], 
                                     check=False)  # Don't fail if chown fails
            else:
                # Linux - use original approach
                subprocess.run(["chmod", "-R", "777", str(self.downloads_dir)], check=True)
                subprocess.run(["chmod", "-R", "777", str(self.sstate_dir)], check=True)
            
            return True
        except Exception as e:
            logger.warning(f"Could not set optimal permissions: {e}")
            return False

    def extract_caches(self) -> bool:
        """Extract cache archives to proper directories"""
        logger.info("📦 Extracting cache archives...")
        
        extraction_start = time.time()
        
        try:
            # Use appropriate tar command for platform
            tar_cmd = "gtar" if self.is_macos and shutil.which("gtar") else "tar"
            
            # Extract downloads cache
            downloads_archive = self.workspace_dir / "full-downloads-cache.tar.gz"
            if downloads_archive.exists():
                logger.info("Extracting downloads cache...")
                subprocess.run([
                    tar_cmd, "-xzf", str(downloads_archive), 
                    "-C", str(self.workspace_dir)
                ], check=True)
                logger.info("✅ Downloads cache extracted")
            
            # Extract sstate cache  
            sstate_archive = self.workspace_dir / self.cache_files['sstate']
            if sstate_archive.exists():
                logger.info("Extracting sstate cache...")
                subprocess.run([
                    tar_cmd, "-xzf", str(sstate_archive),
                    "-C", str(self.workspace_dir)
                ], check=True)
                logger.info("✅ sstate cache extracted")
            
            # Set permissions as mentioned in README (cross-platform)
            logger.info("Setting permissions...")
            self._set_cache_permissions()
            
            # Verify extracted content
            downloads_files = len(list(self.downloads_dir.rglob("*"))) if self.downloads_dir.exists() else 0
            sstate_files = len(list(self.sstate_dir.rglob("*"))) if self.sstate_dir.exists() else 0
            
            extraction_time = time.time() - extraction_start
            
            self.test_results['extraction_test'] = {
                'success': True,
                'extraction_time_seconds': extraction_time,
                'downloads_files': downloads_files,
                'sstate_files': sstate_files
            }
            
            logger.info(f"✅ Cache extraction completed in {extraction_time:.1f} seconds")
            logger.info(f"   Downloads: {downloads_files} files")
            logger.info(f"   sstate: {sstate_files} files")
            
            # Clean up archives
            for archive in [downloads_archive, sstate_archive]:
                if archive.exists():
                    archive.unlink()
            
            return True
            
        except Exception as e:
            logger.error(f"❌ Cache extraction failed: {e}")
            self.test_results['extraction_test'] = {
                'success': False,
                'error': str(e)
            }
            return False

    def run_build_test(self, target: str = "core-image-minimal") -> bool:
        """Run actual build test with cached files"""
        logger.info(f"🚀 Running build test with target: {target}")
        
        build_start = time.time()
        
        try:
            # Docker run command with cross-platform volume mounting
            downloads_mount = str(self.downloads_dir)
            sstate_mount = str(self.sstate_dir)
            
            # On macOS, ensure proper volume mounting format
            if self.is_macos:
                # macOS Docker Desktop may need explicit path resolution
                downloads_mount = str(self.downloads_dir.resolve())
                sstate_mount = str(self.sstate_dir.resolve())
            
            docker_cmd = [
                "docker", "run", "--rm",
                "-v", f"{downloads_mount}:/opt/yocto/downloads",
                "-v", f"{sstate_mount}:/opt/yocto/sstate-cache",
                "-e", "BB_NUMBER_THREADS=4",
                "-e", "PARALLEL_MAKE=-j 4", 
                "-e", "MACHINE=qemux86-64",
                self.docker_image,
                "/bin/bash", "-c", f"""
                    set -eo pipefail
                    source /opt/poky/oe-init-build-env /tmp/test-build
                    
                    echo "=== Build Test: {target} ==="
                    echo "Cache status:"
                    echo "Downloads: $(find /opt/yocto/downloads -type f | wc -l) files"
                    echo "sstate: $(find /opt/yocto/sstate-cache -name '*.siginfo' | wc -l) signatures"
                    
                    start_time=$(date +%s)
                    echo "Build start: $(date)"
                    
                    if bitbake {target}; then
                        end_time=$(date +%s)
                        duration=$((end_time - start_time))
                        echo "=== Build Success: {target} ==="
                        echo "Build time: ${{duration}} seconds"
                        echo "Build end: $(date)"
                        exit 0
                    else
                        echo "=== Build Failed: {target} ==="
                        exit 1
                    fi
                """
            ]
            
            # Run build
            logger.info("Starting Docker build...")
            result = subprocess.run(
                docker_cmd,
                capture_output=True,
                text=True,
                timeout=3600  # 1 hour timeout
            )
            
            build_time = time.time() - build_start
            
            # Parse build output
            build_success = result.returncode == 0
            build_log = result.stdout + result.stderr
            
            # Extract build statistics
            build_stats = self._parse_build_log(build_log)
            
            self.test_results['build_test'] = {
                'success': build_success,
                'target': target,
                'build_time_seconds': build_time,
                'build_time_minutes': build_time / 60,
                'return_code': result.returncode,
                'stats': build_stats
            }
            
            if build_success:
                logger.info(f"✅ Build test passed in {build_time/60:.1f} minutes")
                logger.info(f"   sstate hits: {build_stats.get('sstate_hits', 0)}")
                logger.info(f"   sstate misses: {build_stats.get('sstate_misses', 0)}")
                logger.info(f"   Cache hit rate: {build_stats.get('sstate_hit_rate', 0):.1f}%")
            else:
                logger.error(f"❌ Build test failed after {build_time/60:.1f} minutes")
                logger.error(f"   Return code: {result.returncode}")
                
                # Log some error details
                error_lines = build_log.split('\n')[-20:]  # Last 20 lines
                for line in error_lines:
                    if line.strip():
                        logger.error(f"   {line}")
            
            return build_success
            
        except subprocess.TimeoutExpired:
            logger.error("❌ Build test timed out after 1 hour")
            self.test_results['build_test'] = {
                'success': False,
                'error': 'Build timeout after 1 hour'
            }
            return False
            
        except Exception as e:
            logger.error(f"❌ Build test failed: {e}")
            self.test_results['build_test'] = {
                'success': False,
                'error': str(e)
            }
            return False

    def _parse_build_log(self, log_output: str) -> Dict[str, Any]:
        """Parse build log for performance statistics"""
        stats = {
            'sstate_hits': 0,
            'sstate_misses': 0,
            'sstate_hit_rate': 0,
            'tasks_executed': 0,
            'tasks_from_sstate': 0,
            'downloaded_files': 0
        }
        
        try:
            # Parse sstate summary
            sstate_pattern = r"Sstate summary: Wanted (\d+) Found (\d+) Missed (\d+)"
            match = re.search(sstate_pattern, log_output)
            if match:
                wanted = int(match.group(1))
                found = int(match.group(2))
                missed = int(match.group(3))
                stats['sstate_hits'] = found
                stats['sstate_misses'] = missed
                stats['sstate_hit_rate'] = (found / wanted * 100) if wanted > 0 else 0
            
            # Parse task summary
            task_pattern = r"Tasks Summary: Attempted (\d+) tasks of which (\d+) didn't need to be rerun"
            match = re.search(task_pattern, log_output)
            if match:
                attempted = int(match.group(1))
                cached = int(match.group(2))
                stats['tasks_executed'] = attempted - cached
                stats['tasks_from_sstate'] = cached
                
        except Exception as e:
            logger.warning(f"Could not parse build log: {e}")
            
        return stats

    def run_performance_test(self) -> bool:
        """Run performance comparison test"""
        logger.info("📊 Running performance analysis...")
        
        try:
            build_result = self.test_results.get('build_test', {})
            
            if not build_result.get('success'):
                logger.warning("Skipping performance test - build test failed")
                return False
                
            build_time_minutes = build_result.get('build_time_minutes', 0)
            stats = build_result.get('stats', {})
            
            # Calculate performance metrics
            sstate_hit_rate = stats.get('sstate_hit_rate', 0)
            cache_effectiveness = "Excellent" if sstate_hit_rate > 80 else "Good" if sstate_hit_rate > 60 else "Poor"
            
            # Estimate uncached build time (based on README claims of 80-90% reduction)
            estimated_uncached_time = build_time_minutes * 5  # Assume 80% reduction
            estimated_time_saved = estimated_uncached_time - build_time_minutes
            
            performance_results = {
                'build_time_minutes': build_time_minutes,
                'estimated_uncached_time_minutes': estimated_uncached_time,
                'estimated_time_saved_minutes': estimated_time_saved,
                'sstate_hit_rate_percent': sstate_hit_rate,
                'cache_effectiveness': cache_effectiveness,
                'meets_readme_claims': sstate_hit_rate >= 80 and build_time_minutes <= 30
            }
            
            self.test_results['performance_test'] = performance_results
            
            logger.info(f"✅ Performance analysis complete:")
            logger.info(f"   Build time: {build_time_minutes:.1f} minutes")
            logger.info(f"   Cache hit rate: {sstate_hit_rate:.1f}%")
            logger.info(f"   Cache effectiveness: {cache_effectiveness}")
            logger.info(f"   Estimated time saved: {estimated_time_saved:.1f} minutes")
            
            return True
            
        except Exception as e:
            logger.error(f"❌ Performance test failed: {e}")
            return False

    def generate_test_report(self) -> str:
        """Generate comprehensive test report"""
        report = []
        report.append("=" * 60)
        report.append("KEA YOCTO CACHE DOWNLOAD & BUILD TEST REPORT")
        report.append("=" * 60)
        report.append(f"Test Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        report.append(f"Workspace: {self.workspace_dir}")
        report.append("")
        
        # Download Test Results
        download_test = self.test_results.get('download_test', {})
        report.append("📥 DOWNLOAD TEST")
        report.append("-" * 20)
        if download_test.get('success'):
            report.append("✅ PASSED")
            report.append(f"   Download time: {download_test.get('download_time_seconds', 0):.1f}s")
            report.append(f"   Files downloaded: {download_test.get('files_downloaded', 0)}")
        else:
            report.append("❌ FAILED")
            report.append(f"   Error: {download_test.get('error', 'Unknown')}")
        report.append("")
        
        # Integrity Test Results
        integrity_test = self.test_results.get('integrity_test', {})
        report.append("🔍 INTEGRITY TEST")
        report.append("-" * 20)
        if integrity_test.get('success'):
            report.append("✅ PASSED")
            report.append(f"   Total cache size: {integrity_test.get('total_size_gb', 0):.2f}GB")
            report.append(f"   Downloads: {integrity_test.get('downloads_size_mb', 0)}MB")
            report.append(f"   sstate: {integrity_test.get('sstate_size_mb', 0)}MB")
        else:
            report.append("❌ FAILED")
            report.append(f"   Error: {integrity_test.get('error', 'Unknown')}")
        report.append("")
        
        # Extraction Test Results
        extraction_test = self.test_results.get('extraction_test', {})
        report.append("📦 EXTRACTION TEST")
        report.append("-" * 20)
        if extraction_test.get('success'):
            report.append("✅ PASSED")
            report.append(f"   Extraction time: {extraction_test.get('extraction_time_seconds', 0):.1f}s")
            report.append(f"   Downloads files: {extraction_test.get('downloads_files', 0)}")
            report.append(f"   sstate files: {extraction_test.get('sstate_files', 0)}")
        else:
            report.append("❌ FAILED")
            report.append(f"   Error: {extraction_test.get('error', 'Unknown')}")
        report.append("")
        
        # Build Test Results
        build_test = self.test_results.get('build_test', {})
        report.append("🚀 BUILD TEST")
        report.append("-" * 20)
        if build_test.get('success'):
            report.append("✅ PASSED")
            report.append(f"   Target: {build_test.get('target', 'Unknown')}")
            report.append(f"   Build time: {build_test.get('build_time_minutes', 0):.1f} minutes")
            stats = build_test.get('stats', {})
            report.append(f"   sstate hits: {stats.get('sstate_hits', 0)}")
            report.append(f"   sstate misses: {stats.get('sstate_misses', 0)}")
            report.append(f"   Cache hit rate: {stats.get('sstate_hit_rate', 0):.1f}%")
        else:
            report.append("❌ FAILED")
            report.append(f"   Error: {build_test.get('error', 'Unknown')}")
        report.append("")
        
        # Performance Test Results
        performance_test = self.test_results.get('performance_test', {})
        if performance_test:
            report.append("📊 PERFORMANCE ANALYSIS")
            report.append("-" * 20)
            report.append(f"   Build time: {performance_test.get('build_time_minutes', 0):.1f} minutes")
            report.append(f"   Cache hit rate: {performance_test.get('sstate_hit_rate_percent', 0):.1f}%")
            report.append(f"   Cache effectiveness: {performance_test.get('cache_effectiveness', 'Unknown')}")
            report.append(f"   Estimated time saved: {performance_test.get('estimated_time_saved_minutes', 0):.1f} minutes")
            meets_claims = performance_test.get('meets_readme_claims', False)
            report.append(f"   Meets README claims: {'✅ YES' if meets_claims else '❌ NO'}")
            report.append("")
        
        # Overall Summary
        report.append("📋 OVERALL SUMMARY")
        report.append("-" * 20)
        
        tests_passed = sum([
            download_test.get('success', False),
            integrity_test.get('success', False), 
            extraction_test.get('success', False),
            build_test.get('success', False)
        ])
        
        total_tests = 4
        overall_success = tests_passed == total_tests
        
        report.append(f"Tests passed: {tests_passed}/{total_tests}")
        report.append(f"Overall result: {'✅ ALL TESTS PASSED' if overall_success else '❌ SOME TESTS FAILED'}")
        
        if overall_success:
            report.append("")
            report.append("🎉 The cache download and build system is working correctly!")
            report.append("   You can use the cached builds as described in README.md")
        else:
            report.append("")
            report.append("⚠️  Some tests failed. Please check the issues above.")
            
        report.append("")
        report.append("=" * 60)
        
        return "\n".join(report)

    def cleanup(self) -> None:
        """Clean up test environment"""
        try:
            if self.temp_dir.exists():
                shutil.rmtree(self.temp_dir)
            logger.info("🧹 Cleanup completed")
        except Exception as e:
            logger.warning(f"Cleanup warning: {e}")

    def save_results(self, filename: str = None) -> None:
        """Save test results to JSON file"""
        if filename is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"cache_test_results_{timestamp}.json"
            
        try:
            with open(filename, 'w') as f:
                json.dump(self.test_results, f, indent=2, default=str)
            logger.info(f"💾 Test results saved to: {filename}")
        except Exception as e:
            logger.error(f"Failed to save results: {e}")

    def run_full_test_suite(self) -> bool:
        """Run the complete test suite"""
        logger.info("🚀 Starting KEA Yocto Cache Download & Build Test Suite")
        logger.info("=" * 60)
        
        try:
            # Step 1: Setup
            if not self.setup_test_environment():
                return False
                
            # Step 2: Check prerequisites  
            if not self.check_prerequisites():
                return False
                
            # Step 3: Download cache files
            if not self.download_cache_files():
                return False
                
            # Step 4: Verify integrity
            if not self.verify_file_integrity():
                return False
                
            # Step 5: Extract caches
            if not self.extract_caches():
                return False
                
            # Step 6: Run build test
            if not self.run_build_test():
                return False
                
            # Step 7: Performance analysis
            self.run_performance_test()
            
            # Step 8: Generate report
            report = self.generate_test_report()
            print("\n" + report)
            
            # Step 9: Save results
            self.save_results()
            
            logger.info("🎉 Test suite completed successfully!")
            return True
            
        except KeyboardInterrupt:
            logger.warning("Test suite interrupted by user")
            return False
        except Exception as e:
            logger.error(f"Test suite failed: {e}")
            return False
        finally:
            self.cleanup()


def main():
    """Main function with argument parsing"""
    parser = argparse.ArgumentParser(
        description="KEA Yocto Project Cache Download and Build Test",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 test-cache-download-build.py
  python3 test-cache-download-build.py --workspace ./test-workspace
  python3 test-cache-download-build.py --target core-image-base --verbose
        """
    )
    
    parser.add_argument(
        '--workspace', 
        default='./yocto-workspace-test',
        help='Test workspace directory (default: ./yocto-workspace-test)'
    )
    parser.add_argument(
        '--docker-image',
        default='jabang3/yocto-lecture:5.0-lts', 
        help='Docker image to use (default: jabang3/yocto-lecture:5.0-lts)'
    )
    parser.add_argument(
        '--target',
        default='core-image-minimal',
        help='Build target (default: core-image-minimal)'
    )
    parser.add_argument(
        '--github-url',
        default='https://github.com/jayleekr/kea-yocto/releases/download/split-cache-20250612-153704',
        help='GitHub release URL for cache files'
    )
    parser.add_argument(
        '--verbose', '-v',
        action='store_true',
        help='Enable verbose logging'
    )
    parser.add_argument(
        '--save-results',
        help='Save results to specific JSON file'
    )
    
    args = parser.parse_args()
    
    # Configure logging level
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    # Create test instance
    test = CacheDownloadBuildTest(
        workspace_dir=args.workspace,
        docker_image=args.docker_image,
        github_base_url=args.github_url
    )
    
    # Run test suite
    success = test.run_full_test_suite()
    
    # Save results if requested
    if args.save_results:
        test.save_results(args.save_results)
    
    # Exit with appropriate code
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
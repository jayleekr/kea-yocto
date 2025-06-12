#!/usr/bin/env python3
"""
KEA Yocto Cache Test Demo

This script demonstrates the cache download and build test functionality
without downloading large cache files. It validates the test infrastructure
and shows what the full test would do.

Cross-platform compatible (Linux, macOS).
"""

import sys
import os
import platform
from pathlib import Path

# Add the scripts directory to the path
sys.path.insert(0, str(Path(__file__).parent / 'scripts'))

try:
    from test_cache_download_build import CacheDownloadBuildTest
except ImportError:
    # If import fails, show the test script exists
    test_script = Path(__file__).parent / 'scripts' / 'test-cache-download-build.py'
    if test_script.exists():
        print(f"✅ Test script found: {test_script}")
        print("Run it directly with: python3 scripts/test-cache-download-build.py --help")
    else:
        print(f"❌ Test script not found: {test_script}")
    sys.exit(1)

def demo_test_infrastructure():
    """Demo the test infrastructure without downloading files"""
    print("🧪 KEA Yocto Cache Test Infrastructure Demo")
    print("=" * 50)
    print()
    
    # Detect platform
    is_macos = platform.system() == "Darwin"
    is_linux = platform.system() == "Linux"
    
    print(f"🖥️  Platform: {platform.system()} ({platform.machine()})")
    if is_macos:
        print("   macOS compatibility mode enabled")
    elif is_linux:
        print("   Linux compatibility mode enabled")
    print()
    
    # Create test instance
    test = CacheDownloadBuildTest(
        workspace_dir="./demo-workspace",
        docker_image="jabang3/yocto-lecture:5.0-lts"
    )
    
    print("📋 Test Configuration:")
    print(f"   Workspace: {test.workspace_dir}")
    print(f"   Docker Image: {test.docker_image}")
    print(f"   GitHub URL: {test.github_base_url}")
    print()
    
    print("📦 Cache Files to Download:")
    for category, files in test.cache_files.items():
        if isinstance(files, list):
            print(f"   {category}: {len(files)} files")
            for file in files:
                print(f"     - {file}")
        else:
            print(f"   {category}: {files}")
    print()
    
    print("🎯 Build Targets:")
    for target in test.test_targets:
        print(f"   - {target}")
    print()
    
    print("📊 Expected Performance (from README.md):")
    for key, value in test.expected_performance.items():
        print(f"   {key}: {value}")
    print()
    
    # Test environment setup (without downloading)
    print("🔧 Testing Environment Setup...")
    if test.setup_test_environment():
        print("✅ Environment setup successful")
    else:
        print("❌ Environment setup failed")
    
    # Test prerequisites (without Docker image pull)
    print()
    print("🔍 Testing Prerequisites...")
    
    # Mock the prerequisites check to avoid Docker operations
    prereqs = {
        'workspace_creation': test.workspace_dir.exists(),
        'downloads_dir': test.downloads_dir.exists(),
        'sstate_dir': test.sstate_dir.exists(),
    }
    
    for check, passed in prereqs.items():
        status = "✅" if passed else "❌"
        print(f"{status} {check.replace('_', ' ').title()}: {'PASS' if passed else 'FAIL'}")
    
    print()
    print("📝 Test Report Structure:")
    print("   The full test would generate a report covering:")
    print("   - 📥 Download Test (file download & verification)")
    print("   - 🔍 Integrity Test (tarball validation)")
    print("   - 📦 Extraction Test (cache extraction)")
    print("   - 🚀 Build Test (actual Yocto build)")
    print("   - 📊 Performance Analysis (vs README claims)")
    
    print()
    print("🚀 To run the full test:")
    print("   ./test-cache-build.sh")
    print("   python3 scripts/test-cache-download-build.py")
    print()
    print("⚡ Quick test options:")
    print("   ./test-cache-build.sh --verbose")
    print("   ./test-cache-build.sh --workspace ./my-test")
    print("   ./test-cache-build.sh --target core-image-base")
    
    # Cleanup demo workspace
    try:
        import shutil
        if test.workspace_dir.exists() and test.workspace_dir.name == "demo-workspace":
            shutil.rmtree(test.workspace_dir)
            print()
            print("🧹 Demo workspace cleaned up")
    except Exception as e:
        print(f"Warning: Could not clean up demo workspace: {e}")

if __name__ == "__main__":
    demo_test_infrastructure() 
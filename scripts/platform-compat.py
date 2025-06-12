#!/usr/bin/env python3
"""
Platform Compatibility Helper for KEA Yocto Cache Tests

This module provides cross-platform compatibility functions for:
- macOS (Darwin)
- Linux
- Windows (future support)

Handles differences in:
- Docker volume mounting
- File permissions
- Command availability (tar/gtar)
- Package management
"""

import os
import sys
import platform
import shutil
import subprocess
from pathlib import Path
from typing import Dict, List, Optional

class PlatformCompat:
    """Cross-platform compatibility helper"""
    
    def __init__(self):
        self.system = platform.system()
        self.is_macos = self.system == "Darwin"
        self.is_linux = self.system == "Linux"
        self.is_windows = self.system == "Windows"
        
    def get_tar_command(self) -> str:
        """Get appropriate tar command for the platform"""
        if self.is_macos:
            # Prefer GNU tar on macOS if available
            if shutil.which("gtar"):
                return "gtar"
            else:
                return "tar"
        else:
            return "tar"
    
    def get_docker_volume_path(self, local_path: Path) -> str:
        """Get properly formatted path for Docker volume mounting"""
        if self.is_macos:
            # macOS Docker Desktop needs explicit path resolution
            return str(local_path.resolve())
        else:
            return str(local_path)
    
    def set_cache_permissions(self, cache_dirs: List[Path]) -> bool:
        """Set appropriate permissions for cache directories"""
        try:
            for cache_dir in cache_dirs:
                if not cache_dir.exists():
                    continue
                    
                if self.is_macos:
                    # macOS: More conservative permissions
                    subprocess.run(["chmod", "-R", "755", str(cache_dir)], check=True)
                    # Try to set ownership (may fail without sudo)
                    try:
                        subprocess.run([
                            "chown", "-R", f"{os.getuid()}:{os.getgid()}", 
                            str(cache_dir)
                        ], check=True)
                    except subprocess.CalledProcessError:
                        pass  # Ignore ownership errors
                else:
                    # Linux: Original approach
                    subprocess.run(["chmod", "-R", "777", str(cache_dir)], check=True)
            
            return True
        except Exception:
            return False
    
    def get_python_install_commands(self, package: str) -> List[List[str]]:
        """Get platform-appropriate Python package install commands"""
        commands = []
        
        if self.is_macos:
            # macOS: Try multiple approaches
            if shutil.which("pip3"):
                commands.append(["pip3", "install", package])
            commands.append(["python3", "-m", "pip", "install", package])
        else:
            # Linux: Standard approach
            commands.append(["pip3", "install", package])
            commands.append(["python3", "-m", "pip", "install", package])
        
        return commands
    
    def check_docker_requirements(self) -> Dict[str, any]:
        """Check Docker requirements for the platform"""
        result = {
            'docker_available': False,
            'platform_notes': [],
            'recommendations': []
        }
        
        # Check Docker availability
        try:
            subprocess.run(["docker", "--version"], 
                         capture_output=True, check=True)
            result['docker_available'] = True
        except (subprocess.CalledProcessError, FileNotFoundError):
            result['docker_available'] = False
        
        # Platform-specific notes
        if self.is_macos:
            result['platform_notes'].extend([
                "Running on macOS with Docker Desktop",
                "File sharing must be enabled in Docker Desktop settings",
                "Volume mounting uses absolute paths"
            ])
            
            if not result['docker_available']:
                result['recommendations'].extend([
                    "Install Docker Desktop for macOS",
                    "Ensure Docker Desktop is running",
                    "Check Docker Desktop > Preferences > Resources > File Sharing"
                ])
            
            # Check for GNU tar
            if not shutil.which("gtar"):
                result['recommendations'].append(
                    "Consider installing GNU tar: brew install gnu-tar"
                )
                
        elif self.is_linux:
            result['platform_notes'].extend([
                "Running on Linux with native Docker",
                "Standard Docker configuration"
            ])
            
            if not result['docker_available']:
                result['recommendations'].extend([
                    "Install Docker: sudo apt-get install docker.io",
                    "Start Docker service: sudo systemctl start docker",
                    "Add user to docker group: sudo usermod -aG docker $USER"
                ])
        
        return result
    
    def get_platform_info(self) -> Dict[str, str]:
        """Get detailed platform information"""
        return {
            'system': self.system,
            'machine': platform.machine(),
            'python_version': platform.python_version(),
            'platform_info': platform.platform(),
            'compatibility_mode': 'macOS' if self.is_macos else 'Linux' if self.is_linux else 'Unknown'
        }

# Global instance for easy access
platform_compat = PlatformCompat() 
# 빌드된 이미지 실행

## QEMU로 이미지 실행

```bash
# QEMU에서 이미지 실행
runqemu qemux86-64 core-image-minimal
```

## 가상 머신 내부 탐색

```bash
# 시스템 정보 확인
uname -a
cat /etc/os-release

# 설치된 패키지 확인
opkg list-installed
```

---

← [첫 빌드](first-build.md) | [이미지 커스터마이징](customize.md) → 
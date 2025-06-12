# 첫 빌드: 코어 이미지 및 빌드 프로세스

## 환경 초기화

```bash
# Yocto 빌드 환경 초기화
source /opt/poky/oe-init-build-env /workspace/build
```

## 첫 번째 빌드

```bash
# core-image-minimal 빌드
bitbake core-image-minimal
```

!!! warning "빌드 시간"
    첫 빌드는 30분에서 3시간까지 소요될 수 있습니다.

---

← [환경 설정](setup.md) | [이미지 실행](run-image.md) → 
# Yocto 고급 주제 개요

## 개발 워크플로우 최적화

### devtool 사용

```bash
# 개발용 워크스페이스 생성
devtool create-workspace ../workspace

# 기존 레시피 수정
devtool modify hello-world
```

## 배포 및 업데이트

- **SWUpdate**: 안전한 시스템 업데이트
- **Mender**: OTA(Over-The-Air) 업데이트
- **OSTree**: 원자적 업데이트

## 보안 및 최적화

```bash
# 보안 기능 활성화
IMAGE_FEATURES += "read-only-rootfs"
```

---

← [커스텀 레이어](custom-layer.md) | [마무리](conclusion.md) → 
# 이미지 커스터마이징: 패키지 추가

## 패키지 추가하기

`local.conf` 파일을 편집하여 패키지를 추가할 수 있습니다:

```bash
# local.conf 편집
vi conf/local.conf

# 패키지 추가
IMAGE_INSTALL:append = " nano vim htop git"
IMAGE_INSTALL:append = " python3 python3-pip"
```

## 재빌드

```bash
# 수정된 설정으로 재빌드
bitbake core-image-minimal
```

---

← [이미지 실행](run-image.md) | [커스텀 레이어](custom-layer.md) → 
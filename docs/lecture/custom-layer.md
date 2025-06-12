# 커스텀 레이어 및 레시피 생성

## 새 레이어 생성

```bash
# 새 레이어 생성
bitbake-layers create-layer ../meta-myapp

# 레이어를 빌드에 추가
bitbake-layers add-layer ../meta-myapp
```

## Hello World 애플리케이션 만들기

### 소스 코드 작성

```c
// hello.c
#include <stdio.h>

int main() {
    printf("Hello from Yocto Custom Layer!\n");
    return 0;
}
```

### 레시피 작성

```bash
# hello-world_1.0.bb
SUMMARY = "Hello World application for Yocto"
LICENSE = "MIT"
# ... 레시피 내용
```

---

← [이미지 커스터마이징](customize.md) | [고급 주제](advanced.md) → 
# 🔐 **컨테이너 레지스트리 보안 가이드**

## **목차**
- [1. 보안 방법 비교](#1-보안-방법-비교)
- [2. GitHub Container Registry (권장)](#2-github-container-registry-권장)
- [3. Docker Hub 토큰 보안 강화](#3-docker-hub-토큰-보안-강화)
- [4. OIDC 인증 (고급)](#4-oidc-인증-고급)
- [5. 보안 체크리스트](#5-보안-체크리스트)
- [6. 트러블슈팅](#6-트러블슈팅)

---

## **1. 보안 방법 비교**

| 방법 | 보안성 | 설정 복잡도 | 비용 | 추천도 |
|------|--------|-------------|------|--------|
| **GitHub Container Registry** | ⭐⭐⭐⭐⭐ | ⭐ | 무료 | 🥇 최고 추천 |
| Fine-grained Token | ⭐⭐⭐⭐ | ⭐⭐ | 무료 | 🥈 권장 |
| Classic Token + Rotation | ⭐⭐⭐ | ⭐⭐⭐ | 무료 | 🥉 기본 |
| Username/Password | ⭐ | ⭐ | 무료 | ❌ 비추천 |
| OIDC | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 무료 | 🏆 전문가용 |

---

## **2. GitHub Container Registry (권장)**

### **🎯 장점**
- ✅ **별도 토큰 불필요** - `GITHUB_TOKEN` 자동 사용
- ✅ **완전 무료** - GitHub와 통합
- ✅ **자동 권한 관리** - Repository 권한과 연동
- ✅ **향상된 보안** - GitHub 계정 보안과 연동

### **📝 설정 방법**

#### **2.1 Workflow 설정**
```yaml
# .github/workflows/docker-build.yml 에 이미 적용됨
env:
  GHCR_REGISTRY: ghcr.io
  IMAGE_NAME: yocto-lecture

jobs:
  build:
    permissions:
      contents: read
      packages: write  # GHCR 권한
      id-token: write  # OIDC 지원

    steps:
    - name: Login to GitHub Container Registry
      uses: docker/login-action@v3
      with:
        registry: ghcr.io
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}  # 자동 제공
```

#### **2.2 이미지 사용법**
```bash
# Pull image from GHCR
docker pull ghcr.io/jayleekr/yocto-lecture:5.0-lts

# Run container
docker run -it ghcr.io/jayleekr/yocto-lecture:5.0-lts
```

#### **2.3 Public 설정 (강의용)**
1. Repository → Packages 탭 이동
2. `yocto-lecture` 패키지 클릭
3. Settings → Change visibility → Public

---

## **3. Docker Hub 토큰 보안 강화**

### **🔑 방법 1: Fine-grained Token (권장)**

#### **3.1 토큰 생성**
1. Docker Hub → Account Settings → Security
2. **New Access Token** 클릭
3. 설정:
   ```
   Token Name: kea-yocto-lecture-github-actions
   Access permissions: Public Repo Read + Write
   Scope: Repository - jabang3/yocto-lecture만 선택
   ```

#### **3.2 GitHub Secret 설정**
```bash
# Repository Settings → Secrets and variables → Actions
Name: DOCKERHUB_TOKEN_FINEGRAINED
Value: dckr_pat_xxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

#### **3.3 Workflow 업데이트**
```yaml
- name: Login to Docker Hub
  uses: docker/login-action@v3
  with:
    username: jabang3
    password: ${{ secrets.DOCKERHUB_TOKEN_FINEGRAINED }}
```

### **🔄 방법 2: 토큰 자동 순환**

#### **3.4 Monthly Rotation Script**
```yaml
# .github/workflows/token-rotation.yml
name: Rotate Docker Hub Token
on:
  schedule:
    - cron: '0 0 1 * *'  # 매월 1일

jobs:
  rotate:
    runs-on: ubuntu-latest
    steps:
    - name: Notify Token Rotation
      run: |
        echo "🔄 Docker Hub 토큰 순환 알림"
        echo "새 토큰을 생성하고 DOCKERHUB_TOKEN secret을 업데이트하세요"
        # Slack/Email 알림 추가 가능
```

### **🛡️ 방법 3: IP 제한 + 시간 제한**

#### **3.5 GitHub Actions IP 대역 확인**
```yaml
- name: Check IP for Security
  run: |
    echo "Current IP: $(curl -s ifconfig.me)"
    echo "GitHub Actions IP 대역: https://api.github.com/meta"
    curl -s https://api.github.com/meta | jq '.actions'
```

---

## **4. OIDC 인증 (고급)**

### **🏆 최고 보안 수준**

#### **4.1 OIDC 설정**
```yaml
jobs:
  build:
    permissions:
      id-token: write
      contents: read
      packages: write

    steps:
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        role-to-assume: arn:aws:iam::ACCOUNT:role/GitHubActionsRole
        aws-region: us-east-1

    - name: Login to ECR
      uses: docker/login-action@v3
      with:
        registry: ${{ env.AWS_ACCOUNT_ID }}.dkr.ecr.us-east-1.amazonaws.com
```

---

## **5. 보안 체크리스트**

### **✅ 필수 보안 조치**
- [ ] GitHub Container Registry 우선 사용
- [ ] Fine-grained Token 사용 (Docker Hub 필요시)
- [ ] 토큰 권한 최소화 (특정 레포지토리만)
- [ ] Secret 이름 명확화 (`DOCKERHUB_TOKEN_READONLY` 등)
- [ ] Workflow 권한 최소화 (`permissions` 명시)

### **🔒 고급 보안 조치**
- [ ] 토큰 자동 순환 설정
- [ ] 빌드 환경 격리 (self-hosted runner)
- [ ] 이미지 취약점 스캔 연동
- [ ] Cosign으로 이미지 서명
- [ ] SBOM 생성 및 관리

### **📊 모니터링**
- [ ] 토큰 사용량 모니터링
- [ ] 실패한 로그인 시도 추적
- [ ] 비정상적인 IP 접근 감지
- [ ] 이미지 다운로드 패턴 분석

---

## **6. 트러블슈팅**

### **❌ 일반적인 오류들**

#### **6.1 "Password required" 오류**
```bash
# 원인: DOCKERHUB_TOKEN secret 미설정 또는 만료
# 해결: Secret 재생성 및 업데이트

# 확인 방법
echo "Token length: ${#DOCKERHUB_TOKEN}"  # 0이면 미설정
```

#### **6.2 "403 Forbidden" 오류**
```bash
# 원인: 토큰 권한 부족
# 해결: Repository Write 권한 확인

# Fine-grained token 권한 확인:
# - Public Repo Read
# - Public Repo Write
# - Specific repository access
```

#### **6.3 GHCR "packages: write" 오류**
```yaml
# 원인: packages 권한 누락
# 해결: permissions 섹션 추가
permissions:
  contents: read
  packages: write  # 이 라인 필수!
```

### **🔍 디버깅 팁**

#### **6.4 토큰 유효성 검증**
```bash
# Docker Hub API로 토큰 테스트
curl -H "Authorization: Bearer $DOCKERHUB_TOKEN" \
     https://hub.docker.com/v2/repositories/jabang3/

# 응답: 200 OK (성공) / 401 Unauthorized (실패)
```

#### **6.5 GHCR 권한 확인**
```bash
# GitHub CLI로 패키지 권한 확인
gh api /user/packages?package_type=container

# 또는 웹에서 확인
# https://github.com/users/jayleekr/packages
```

---

## **📚 추가 리소스**

### **공식 문서**
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Docker Hub Access Tokens](https://docs.docker.com/docker-hub/access-tokens/)
- [GitHub OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)

### **보안 도구**
- [Trivy](https://github.com/aquasecurity/trivy) - 이미지 취약점 스캔
- [Cosign](https://github.com/sigstore/cosign) - 이미지 서명
- [SLSA](https://slsa.dev/) - 공급망 보안

### **모니터링 도구**
- [GitHub Security Advisories](https://github.com/advisories)
- [Docker Scout](https://docs.docker.com/scout/) - Docker Hub 내장 스캔
- [Dependabot](https://github.com/dependabot) - 종속성 업데이트

---

**💡 권장사항**: 강의 환경에서는 **GitHub Container Registry**를 사용하는 것이 가장 안전하고 간편합니다! 
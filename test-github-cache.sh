#!/bin/bash

echo "⏱️ 빌드 시작 시간: $(date)"
start_time=$(date +%s)

docker run --rm -v "$PWD:/shared" jabang3/yocto-lecture:5.0-lts /bin/bash -c "
cd /home/yocto
source /opt/poky/oe-init-build-env build

# 캐시 경로 설정
echo 'DL_DIR = \"/shared/downloads\"' >> conf/local.conf
echo 'SSTATE_DIR = \"/shared/sstate-cache\"' >> conf/local.conf

echo '=== 빌드 설정 확인 ==='
grep -E 'DL_DIR|SSTATE_DIR' conf/local.conf

echo ''
echo '=== 캐시 상태 확인 ==='
echo \"Downloads: \$(ls /shared/downloads 2>/dev/null | wc -l) files\"
echo \"sstate files: \$(find /shared/sstate-cache -name '*.tar.zst' 2>/dev/null | wc -l) files\"
echo \"sstate siginfo: \$(find /shared/sstate-cache -name '*.siginfo' 2>/dev/null | wc -l) files\"

echo ''
echo '=== m4-native 빌드 시작 ==='
bitbake m4-native
"

end_time=$(date +%s)
duration=$((end_time - start_time))
echo ""
echo "⏱️ 빌드 완료 시간: $(date)"
echo "🕐 총 소요 시간: ${duration}초 ($(($duration / 60))분 $(($duration % 60))초)" 
#!/bin/bash

# HOME 변수가 설정되지 않은 경우 기본값 설정 (예: /home/username)
if [ -z "$HOME" ]; then
  HOME="/home/$(whoami)"
fi

# 변수 설정 (필요에 따라 변경하세요)
HARBOR_VERSION="v2.2.2"
HARBOR_FILENAME="harbor-offline-installer-${HARBOR_VERSION}.tgz"
HARBOR_URL="https://github.com/goharbor/harbor/releases/download/${HARBOR_VERSION}/${HARBOR_FILENAME}"
INSTALL_DIR="${HOME}/harbor"
HOSTNAME="10.0.2.15"  # VirtualBox에서 확인한 게스트 IP
CERT_PATH="/etc/docker/certs.d/server/server.cert"
KEY_PATH="/etc/docker/certs.d/server/server.key"
CUSTOM_PORT="7000"

# 홈 디렉토리로 이동
cd "$HOME"

# 파일이 존재하지 않으면 다운로드 및 압축 해제
if [ ! -f $HARBOR_FILENAME ]; then
  wget $HARBOR_URL
  tar xzvf $HARBOR_FILENAME
fi

# 디렉토리 존재하는지 확인하고 이동
if [ -d "harbor" ]; then
  cd "harbor"
else
  echo "Harbor 디렉토리가 없습니다. 압축 해제를 확인하세요."
  exit 1
fi

# harbor.yml 파일 생성 및 수정
if [ ! -f harbor.yml ]; then
  cp harbor.yml.tmpl harbor.yml
  sed -i "s/hostname: .*/hostname: ${HOSTNAME}/" harbor.yml
  sed -i "s|# port: 80|port: ${CUSTOM_PORT}|" harbor.yml
  sed -i "s|port: 443|port: 443|" harbor.yml
  sed -i "s|/your/certificate/path|${CERT_PATH}|" harbor.yml
  sed -i "s|/your/private/key/path|${KEY_PATH}|" harbor.yml
fi

# 사전 작업 수행
./prepare

# 파일 권한 및 소유자 수정
sudo chown -R $(whoami):$(whoami) $INSTALL_DIR
sudo chmod -R u+rwX $INSTALL_DIR


# 환경 설정 파일 권한 수정
find $INSTALL_DIR -type f -name "env" -exec chmod 644 {} \;

# 설치 수행
./install.sh



# Firewalld 사용하여 7000번 포트 추가
sudo firewall-cmd --zone=public --add-port=${CUSTOM_PORT}/tcp --permanent
sudo firewall-cmd --reload

echo "Harbor 설치가 완료되었습니다!"
echo "포트 포워딩 설정:"
echo "HTTP: http://localhost:${CUSTOM_PORT}"
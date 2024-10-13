#!/bin/bash

# 변수 설정
DOCKER_USER="dockeruser"
CERT_DIR="/home/dockeruser/certs"
DOCKER_CERT_DIR="/etc/docker/certs.d/server"
COUNTRY="KR"
STATE="Jeollabuk-do"
LOCATION="Jeonju-si"
ORGANIZATION="Nineis"
ORG_UNIT="Solution"
CA_CN="ca.nineis.local"
SERVER_CN="server.nineis.local"
PASSPHRASE="your_passphrase"  # 사용하고자 하는 패스프레이즈로 변경

# OpenSSL 설치
sudo dnf install -y openssl

# 인증서 디렉토리 생성
sudo -u $DOCKER_USER mkdir -p $CERT_DIR
cd $CERT_DIR

# v3ext.cnf 파일 생성
echo '[ v3_ca ]
basicConstraints = CA:TRUE
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
[ v3_req ]
subjectAltName = @alt_names
[ alt_names ]
DNS.1 = server.nineis.local
DNS.2 = www.server.nineis.local' > v3ext.cnf

# CA 프라이빗 키 생성 (4096 비트 RSA 사용)
openssl genrsa -aes256 -out ca.key -passout pass:$PASSPHRASE 4096

# 서버용 프라이빗 키 생성 (4096 비트 RSA 사용)
openssl genrsa -aes256 -out server.key -passout pass:$PASSPHRASE 4096

# CA 인증서 생성 (SHA-512 사용)
openssl req -x509 -new -nodes -key ca.key -sha512 -days 1024 -out ca.crt -passin pass:$PASSPHRASE \
    -subj "/C=$COUNTRY/ST=$STATE/L=$LOCATION/O=$ORGANIZATION/OU=$ORG_UNIT/CN=$CA_CN"

# 서버 인증서 서명 요청(CSR) 생성 (SHA-512 사용)
openssl req -new -key server.key -out server.csr -sha512 -passin pass:$PASSPHRASE \
    -subj "/C=$COUNTRY/ST=$STATE/L=$LOCATION/O=$ORGANIZATION/OU=$ORG_UNIT/CN=$SERVER_CN"

# 서버 인증서 생성 및 서명 (SHA-512 사용, v3ext.cnf 사용)
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 500 -sha512 -extfile v3ext.cnf -extensions v3_req -passin pass:$PASSPHRASE

# server.crt 파일을 server.cert 파일로 변환
openssl x509 -inform PEM -in server.crt -outform PEM -out server.cert

# 퍼미션 변경 (프라이빗 키 접근 제한)
chmod 600 ca.key server.key

# 소유자 변경 (dockeradmin 사용자 소유로 변경)
sudo chown $DOCKER_USER:$DOCKER_USER ca.key server.key ca.crt server.cert v3ext.cnf

# Docker 인증서 디렉토리 생성 및 자격 증명 복사
sudo mkdir -p $DOCKER_CERT_DIR
sudo cp server.cert ca.crt server.key $DOCKER_CERT_DIR

# Docker 인증서 디렉토리 퍼미션 및 소유자 변경
sudo chmod 700 $DOCKER_CERT_DIR
sudo chown -R $DOCKER_USER:$DOCKER_USER $DOCKER_CERT_DIR

# 설정 확인
echo "CA 인증서와 서버 인증서가 생성되어 $CERT_DIR 디렉토리에 저장되었습니다."
echo "또한, 인증서들은 $DOCKER_CERT_DIR 디렉토리로 복사되었습니다."
echo "생성된 인증서를 확인하세요:"
echo "CA 인증서: $CERT_DIR/ca.crt"
echo "서버 인증서: $CERT_DIR/server.cert"
echo "서버 키: $CERT_DIR/server.key"
echo "확장 파일: $CERT_DIR/v3ext.cnf"
echo "$DOCKER_CERT_DIR 디렉토리에서도 확인하세요:"
echo "CA 인증서: $DOCKER_CERT_DIR/ca.crt"
echo "서버 인증서: $DOCKER_CERT_DIR/server.cert"
echo "서버 키: $DOCKER_CERT_DIR/server.key"

# 스크립트 종료
echo "스크립트가 성공적으로 완료되었습니다."
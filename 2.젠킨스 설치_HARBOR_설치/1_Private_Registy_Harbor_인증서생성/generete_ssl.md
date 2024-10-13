# CA 및 서버 인증서 생성 Shell Script

이 문서는 OpenSSL을 사용하여 CA 인증서와 서버 인증서를 생성하는 Shell Script에 대한 설명서입니다. 또한 생성된 인증서를 `/etc/docker/certs.d/server` 디렉토리로 복사하는 작업도 포함합니다.

## 스크립트 코드

```shell
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
```

## 설명

### 헤더 및 변수 설정

```shell
#!/bin/bash
```
스크립트의 첫 번째 줄은 이 스크립트가 Bash 셸을 사용하도록 지정합니다.

```shell
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
```
인증서 생성에 필요한 다양한 변수들을 설정합니다. `DOCKER_USER`, `CERT_DIR`, `DOCKER_CERT_DIR` 등의 디렉토리 위치와 인증서 정보들이 포함됩니다.

### OpenSSL 설치

```shell
sudo dnf install -y openssl
```
OpenSSL 패키지를 설치합니다. 이 명령은 Fedora 기반 시스템에서 사용됩니다.

### 인증서 디렉토리 생성

```shell
sudo -u $DOCKER_USER mkdir -p $CERT_DIR
```
인증서를 저장할 디렉토리를 생성합니다. `dockeruser` 권한으로 디렉토리를 만듭니다.

```shell
cd $CERT_DIR
```
생성한 디렉토리로 이동합니다.

### v3ext.cnf 파일 생성

```shell
echo '[ v3_ca ]
basicConstraints = CA:TRUE
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
[ v3_req ]
subjectAltName = @alt_names
[ alt_names ]
DNS.1 = server.nineis.local
DNS.2 = www.server.nineis.local' > v3ext.cnf
```
인증서 확장을 위한 구성 파일 `v3ext.cnf`를 생성합니다.

### 프라이빗 키 생성

```shell
openssl genrsa -aes256 -out ca.key -passout pass:$PASSPHRASE 4096
```
CA 프라이빗 키를 생성합니다.

```shell
openssl genrsa -aes256 -out server.key -passout pass:$PASSPHRASE 4096
```
서버용 프라이빗 키를 생성합니다.

### CA 인증서 생성

```shell
openssl req -x509 -new -nodes -key ca.key -sha512 -days 1024 -out ca.crt -passin pass:$PASSPHRASE \
    -subj "/C=$COUNTRY/ST=$STATE/L=$LOCATION/O=$ORGANIZATION/OU=$ORG_UNIT/CN=$CA_CN"
```
CA 인증서를 생성합니다. CA 프라이빗 키와 설정된 변수들을 사용해 인증서를 생성합니다.

### 서버 인증서 서명 요청(CSR) 생성

```shell
openssl req -new -key server.key -out server.csr -sha512 -passin pass:$PASSPHRASE \
    -subj "/C=$COUNTRY/ST=$STATE/L=$LOCATION/O=$ORGANIZATION/OU=$ORG_UNIT/CN=$SERVER_CN"
```
서버 인증서를 위한 CSR을 생성합니다.

### 서버 인증서 서명

```shell
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 500 -sha512 -extfile v3ext.cnf -extensions v3_req -passin pass:$PASSPHRASE
```
서버 인증서를 CA 인증서로 서명하여 생성합니다.

### 서버 인증서 변환

```shell
openssl x509 -inform PEM -in server.crt -outform PEM -out server.cert
```
서버 인증서를 `server.crt`에서 `server.cert`로 변환합니다.

### 파일 퍼미션 및 소유자 변경

```shell
chmod 600 ca.key server.key
```
프라이빗 키의 접근 권한을 설정합니다.

```shell
sudo chown $DOCKER_USER:$DOCKER_USER ca.key server.key ca.crt server.cert v3ext.cnf
```
파일의 소유자를 `dockeruser`로 변경합니다.

### Docker 인증서 디렉토리 생성 및 자격 증명 복사

```shell
sudo mkdir -p $DOCKER_CERT_DIR
```
Docker 인증서 디렉토리를 생성합니다.

```shell
sudo cp server.cert ca.crt server.key $DOCKER_CERT_DIR
```
인증서를 Docker 인증서 디렉토리로 복사합니다.

### Docker 인증서 디렉토리 퍼미션 및 소유자 변경

```shell
sudo chmod 700 $DOCKER_CERT_DIR
```
Docker 인증서 디렉토리의 접근 권한을 설정합니다.

```shell
sudo chown -R $DOCKER_USER:$DOCKER_USER $DOCKER_CERT_DIR
```
Docker 인증서 디렉토리와 그 내부 파일의 소유자를 `dockeruser`로 변경합니다.

### 설정 확인 및 종료

```shell
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
```

이 문서는 OpenSSL을 사용하여 CA 인증서와 서버 인증서를 생성하고, 
생성된 인증서를 `/etc/docker/certs.d/server` 디렉토리로 복사하는 완전한 Shell Script를 설명합니다.
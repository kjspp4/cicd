# Rocky Linux에서 SSH 서버 설치 및 설정

이 문서는 Rocky Linux에서 SSH 서버를 설치하고 설정하는 방법을 안내합니다.

## 1. SSH 서버 설치

먼저 시스템 패키지를 업데이트하고 `openssh-server` 패키지를 설치합니다.

```bash
sudo dnf update -y
sudo dnf install -y openssh-server
```

## 2. SSH 서비스 시작 및 활성화

SSH 서비스가 부팅 시 자동으로 시작되도록 활성화하고 즉시 시작합니다.

```bash
sudo systemctl enable sshd
sudo systemctl start sshd
```

## 3. SSH 서비스 상태 확인

SSH 서비스가 정상적으로 실행 중인지 확인합니다.

```bash
sudo systemctl status sshd
```

## 4. 방화벽 설정

SSH 연결을 허용하도록 방화벽을 설정합니다.

```bash
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --reload
```

## 5. SSH 설정 파일 수정 (선택 사항)

기본 설정을 변경하려면 `/etc/ssh/sshd_config` 파일을 수정합니다.

```bash
sudo vi /etc/ssh/sshd_config
```

몇 가지 예시 설정:
```text
# 포트 변경 (기본 포트: 22)
Port 2222

# Root 접속 비활성화
PermitRootLogin no
```

설정을 변경한 후 SSH 서비스를 재시작하여 변경 사항을 적용합니다:

```bash
sudo systemctl restart sshd
```

## 6. SSH 키 생성 및 복사 (선택 사항)

비밀번호 없이 SSH 접속을 하기 위해 SSH 키를 생성하고 원격 서버에 복사할 수 있습니다.

### SSH 키 생성

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
```

### SSH 키 복사

원격 서버로 SSH 키를 복사합니다:

```bash
ssh-copy-id -i ~/.ssh/id_rsa.pub 사용자명@원격서버주소
```

이제 SSH 키를 사용해 비밀번호 없이 접속이 가능합니다:

```bash
ssh -i ~/.ssh/id_rsa 사용자명@원격서버주소
```

## 전체 스크립트

아래는 위의 단계를 자동으로 수행하는 전체 스크립트입니다.

```bash
#!/bin/bash

set -e

echo "1. 시스템 업데이트 중..."
sudo dnf update -y

echo "2. OpenSSH 서버 설치 중..."
sudo dnf install -y openssh-server

echo "3. SSH 서비스 시작 및 활성화 중..."
sudo systemctl enable sshd
sudo systemctl start sshd

echo "4. SSH 서비스 상태 확인 중..."
sudo systemctl status sshd

echo "5. 방화벽 설정 중..."
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --reload

# SSH 설정 파일 수정을 원한다면 아래 부분을 활성화하십시오.
#echo "6. SSH 설정 파일 수정 중..."
#sudo sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config
#sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

#echo "7. SSH 서비스 재시작 중..."
#sudo systemctl restart sshd

echo "설치 및 설정이 완료되었습니다. SSH 서비스가 실행 중입니다."
```

위 스크립트를 파일(`setup_ssh.sh`)로 저장하고 실행 권한을 부여한 후 실행합니다:

```bash
chmod +x setup_ssh.sh
./setup_ssh.sh
```

이제 Rocky Linux에서 SSH 서버가 정상적으로 설치 및 설정되었으며, 필요에 따라 추가 설정을 적용할 수 있습니다.
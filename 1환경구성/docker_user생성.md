# 사용자 생성 도커 설치

## 개요
이 메뉴얼은 Rocky 기반 리눅스 환경에서 사용자 계정을 생성하고 Docker와 Docker Compose를 설치 및 설정하는 과정을 자동으로 수행하는 쉘 스크립트 사용법을 설명합니다.

## 스크립트 설명
스크립트는 다음과 같은 단계를 포함하며, 각 단계는 함수로 정의되어 있습니다:

1. Docker 설치
2. 사용자 생성
3. Docker 그룹 생성 및 사용자 추가
4. Docker 권한 설정
5. Docker 서비스 재시작
6. Docker Compose 설치

## 사전 준비
- Rocky 기반의 리눅스 시스템
- `curl`이 설치되어 있어야 합니다 (Docker Compose 설치 시 필요)

## 스크립트 내용

```shell
#!/bin/bash
DOCKER_USER="dockeradmin"  # 생성할 사용자 계정 이름 설정
DOCKER_USER_PASSWORD="1234"  # 변경 가능한 사용자 비밀번호 설정
DOCKER_SOCK="/var/run/docker.sock"

# 1. Docker 설치
install_docker() {
    if ! command -v docker &> /dev/null; then
        echo "Docker가 설치되어 있지 않습니다. 설치 중..."
        sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
        sudo dnf install -y docker-ce docker-ce-cli containerd.io
        sudo systemctl start docker
        sudo systemctl enable docker
        echo "Docker 설치 완료."
    else
        echo "Docker가 이미 설치되어 있습니다."
    fi
}

# 2. 사용자 생성
create_user() {
    if id "$DOCKER_USER" &>/dev/null; then
        echo "$DOCKER_USER 계정이 이미 존재합니다."
    else
        echo "$DOCKER_USER 계정을 추가합니다..."
        sudo adduser $DOCKER_USER
        echo "$DOCKER_USER:$DOCKER_USER_PASSWORD" | sudo chpasswd
        echo "$DOCKER_USER 계정이 정상적으로 추가되었습니다."
    fi
}

# 3. Docker 그룹 생성 및 사용자 추가
create_docker_group() {
    if ! getent group docker &> /dev/null; then
        sudo groupadd docker
        echo "docker 그룹이 생성되었습니다."
    fi
    sudo usermod -aG docker $DOCKER_USER
    echo "$DOCKER_USER 계정이 docker 그룹에 추가되었습니다."
}

# 4. Docker 권한 설정
set_docker_permissions() {
    sudo chmod 666 $DOCKER_SOCK
    echo "Docker 소켓의 권한이 666으로 설정되었습니다."
}

# 5. Docker 서비스 재시작
restart_docker_service() {
    sudo systemctl restart docker
    echo "Docker 서비스가 재시작되었습니다."
}

# 6. Docker Compose 설치
install_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        echo "Docker Compose를 설치 중..."
        sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        echo "Docker Compose 설치 완료."
    else
        echo "Docker Compose가 이미 설치되어 있습니다."
    }
}

# 실행 순서
install_docker
create_user
create_docker_group
set_docker_permissions
restart_docker_service
install_docker_compose

# Docker와 Docker Compose 테스트
echo "Docker 및 Docker Compose의 설정이 완료되었습니다. Docker 명령어를 테스트합니다."
su - $DOCKER_USER -c "docker run hello-world"
su - $DOCKER_USER -c "docker-compose --version"
echo "설정이 완료되었습니다."
```

## 실행 방법

1. 위의 스크립트를 파일로 저장합니다. 예: `setup_docker.sh`
2. 스크립트에 실행 권한을 부여합니다:
   ```bash
   chmod +x setup_docker.sh
   ```
3. 스크립트를 실행합니다:
   ```bash
   ./setup_docker.sh
   ```

## 참고 사항
- 스크립트 중 `DOCKER_USER`, `DOCKER_USER_PASSWORD`, `DOCKER_SOCK` 등의 변수는 필요에 따라 변경할 수 있습니다.
- 스크립트는 `sudo` 명령어를 사용하므로, 실행 시 sudo 권한이 필요합니다.


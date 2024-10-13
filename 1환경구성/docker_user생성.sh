#!/bin/bash
DOCKER_USER="dockeruser"  # 생성할 사용자 계정 이름 설정
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
        echo "$DOCKER_USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$DOCKER_USER
        echo "$DOCKER_USER 계정에 sudo 권한이 부여되었습니다."
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
    fi
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
#!/bin/bash

# 脚本名称：NAS-Tools 一键部署脚本（映射统一版）
# 作者：Eric
# YouTube频道：https://www.youtube.com/@Eric-f2v

# --- 定义默认变量 ---
DEFAULT_JACKETT_PORT=9117
DEFAULT_QBITTORRENT_WEBUI_PORT=8080
DEFAULT_NASTOOLS_PORT=3000

echo "========================================="
echo "  多服务一键部署脚本 - 映射统一版"
echo "========================================="

# 脚本所在目录将作为所有文件的根目录
DEPLOY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOCKER_BASE_DIR="$DEPLOY_DIR/docker"
MEDIA_BASE_DIR="$DEPLOY_DIR/media"

# --- 交互式输入 ---

# 1. 输入端口映射
read -p "请输入 Jackett 的宿主机端口 [默认: $DEFAULT_JACKETT_PORT]: " JACKETT_PORT
JACKETT_PORT=${JACKETT_PORT:-$DEFAULT_JACKETT_PORT}

read -p "请输入 Qbittorrent 的 Web UI 宿主机端口 [默认: $DEFAULT_QBITTORRENT_WEBUI_PORT]: " QBITTORRENT_WEBUI_PORT
QBITTORRENT_WEBUI_PORT=${QBITTORRENT_WEBUI_PORT:-$DEFAULT_QBITTORRENT_WEBUI_PORT}

read -p "请输入 NASTOOLS 的宿主机端口 [默认: $DEFAULT_NASTOOLS_PORT]: " NASTOOLS_PORT
NASTOOLS_PORT=${NASTOOLS_PORT:-$DEFAULT_NASTOOLS_PORT}

# 2. 输入 PUID 和 PGID
echo -e "\n--- 获取 PUID 和 PGID ---"
echo "你可以通过在终端运行 'id <你的用户名>' 命令来获取。"
read -p "请输入用户的 PUID (例如: 1026): " PUID
while ! [[ "$PUID" =~ ^[0-9]+$ ]]
do
  read -p "PUID 必须是数字，请重新输入: " PUID
done

read -p "请输入用户的 PGID (例如: 100): " PGID
while ! [[ "$PGID" =~ ^[0-9]+$ ]]
do
  read -p "PGID 必须是数字，请重新输入: " PGID
done

# --- 部署步骤 ---

echo -e "\n========================================="
echo "         正在生成并部署服务..."
echo "========================================="

# 自动创建所有需要的子目录
JACKETT_CONFIG_DIR="$DOCKER_BASE_DIR/jackett"
QBITTORRENT_CONFIG_DIR="$DOCKER_BASE_DIR/qbittorrent"
NASTOOLS_CONFIG_DIR="$DOCKER_BASE_DIR/nastools"
MEDIA_MOVIE_DIR="$MEDIA_BASE_DIR/Movie"
MEDIA_TV_DIR="$MEDIA_BASE_DIR/Tv"
MEDIA_LINK_DIR="$MEDIA_BASE_DIR/Link"
MEDIA_LINK_MOVIE_DIR="$MEDIA_LINK_DIR/Movie"
MEDIA_LINK_TV_DIR="$MEDIA_LINK_DIR/Tv"

for dir in "$JACKETT_CONFIG_DIR" "$QBITTORRENT_CONFIG_DIR" "$NASTOOLS_CONFIG_DIR" "$MEDIA_MOVIE_DIR" "$MEDIA_TV_DIR" "$MEDIA_LINK_MOVIE_DIR" "$MEDIA_LINK_TV_DIR"; do
    if [ ! -d "$dir" ]; then
        echo "创建目录 $dir..."
        mkdir -p "$dir" || { echo "错误: 无法创建目录 $dir。请检查权限。"; exit 1; }
    fi
done

# --- 移除旧容器，以防冲突 ---
echo "检查并移除旧容器..."
docker rm -f jackett qbittorrent nastools &>/dev/null

# 1. 部署 Jackett
echo "正在拉取 Jackett 镜像..."
docker pull linuxserver/jackett:latest || { echo "错误: 无法拉取 Jackett 镜像，请检查网络。"; exit 1; }
echo "正在部署 Jackett 容器..."
docker run -d \
  --name=jackett \
  --restart=always \
  -p $JACKETT_PORT:9117 \
  -e PUID=$PUID \
  -e PGID=$PGID \
  -e TZ=Asia/Shanghai \
  -v $JACKETT_CONFIG_DIR:/config \
  linuxserver/jackett:latest

# 2. 部署 Qbittorrent
echo "正在拉取 Qbittorrent 镜像..."
docker pull linuxserver/qbittorrent:latest || { echo "错误: 无法拉取 Qbittorrent 镜像，请检查网络。"; exit 1; }
echo "正在部署 Qbittorrent 容器..."
docker run -d \
  --name=qbittorrent \
  --restart=always \
  -p $QBITTORRENT_WEBUI_PORT:8080 \
  -p 6881:6881 \
  -p 6881:6881/udp \
  -e PUID=$PUID \
  -e PGID=$PGID \
  -e TZ=Asia/Shanghai \
  -e WEBUI_PORT=8080 \
  -v $QBITTORRENT_CONFIG_DIR:/config \
  -v $MEDIA_BASE_DIR:/media \
  linuxserver/qbittorrent:latest

# 3. 部署 NASTOOLS
echo "正在拉取 NASTOOLS 镜像..."
docker pull hsuyelin/nas-tools || { echo "错误: 无法拉取 NASTOOLS 镜像，请检查网络。"; exit 1; }
echo "正在部署 NASTOOLS 容器..."
docker run -d \
  --name=nastools \
  --restart=always \
  -p $NASTOOLS_PORT:3000 \
  -e PUID=$PUID \
  -e PGID=$PGID \
  -e TZ=Asia/Shanghai \
  -e AUTO_UPDATE=true \
  -e RUN_MODE=release \
  -v $NASTOOLS_CONFIG_DIR:/config \
  -v $MEDIA_BASE_DIR:/media \
  hsuyelin/nas-tools

if [ $? -eq 0 ]; then
    echo -e "\n========================================="
    echo "所有服务部署成功！"
    echo "你可以通过以下地址访问它们："
    echo "Jackett:      http://你的NAS_IP:$JACKETT_PORT"
    echo "Qbittorrent:  http://你的NAS_IP:$QBITTORRENT_WEBUI_PORT"
    echo "NASTOOLS:     http://你的NAS_IP:$NASTOOLS_PORT"
    echo "========================================="
    echo -e "\n注意：请在 NASTOOLS 和 Qbittorrent 的后台配置中，将所有相关路径设置为：/media。"
    echo "例如，Qbittorrent 的下载路径、NASTOOLS 的电影/电视节目/链接路径都应以 /media 开头。"
    echo "========================================="
else
    echo -e "\n错误：Docker 容器启动失败。"
    echo "请检查以上步骤或使用 'docker logs <容器名称>' 获取更多信息。"
fi

#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 进度函数
progress() {
    local percent=$1
    local description=$2
    printf "${YELLOW}[%-50s] %d%%${NC}\n" $(printf "#%.0s" $(seq 1 $((percent/2)))) $percent
    echo -e "${GREEN}$description${NC}"
}

# 第一部分: Redis单机安装

progress 5 "开始Redis单机安装..."

# 下载Redis
progress 10 "正在下载Redis..."
wget -O redis-6.2.4.tar.gz "https://dlink.host/1drv/aHR0cHM6Ly8xZHJ2Lm1zL3UvcyFBZ1NYRUpYME43RzliMTV6M2ItTlFza3RCdE0_ZT1RdXZjSGI.tar.gz"

# 解压Redis
progress 20 "正在解压Redis..."
tar -xvf redis-6.2.4.tar.gz

# 编译安装Redis
progress 30 "正在编译安装Redis..."
cd redis-6.2.4
make && make install

# 修改配置文件
progress 40 "正在修改配置文件..."
sed -i 's/bind 127.0.0.1/bind 0.0.0.0/' redis.conf
sed -i 's/databases 16/databases 1/' redis.conf

# 启动Redis
progress 50 "正在启动Redis..."
redis-server redis.conf &

progress 55 "Redis单机安装完成!"

# 第二部分: Sentinel集群搭建

progress 60 "开始Sentinel集群搭建..."

# 创建目录
cd /tmp
mkdir -p s1 s2 s3

# 创建配置文件
progress 70 "正在创建Sentinel配置文件..."
cat > s1/sentinel.conf <<EOF
port 27001
sentinel announce-ip 192.168.206.129
sentinel monitor mymaster 192.168.206.129 7001 2
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 60000
dir "/tmp/s1"
EOF

# 复制配置文件
progress 80 "正在复制Sentinel配置文件..."
cp s1/sentinel.conf s2
cp s1/sentinel.conf s3

# 修改配置文件
progress 90 "正在修改Sentinel配置文件..."
sed -i -e 's/27001/27002/g' -e 's/s1/s2/g' s2/sentinel.conf
sed -i -e 's/27001/27003/g' -e 's/s1/s3/g' s3/sentinel.conf

# 启动sentinel
progress 95 "Sentinel集群准备就绪..."
echo "启动Sentinel的命令:"
echo "redis-sentinel /tmp/s1/sentinel.conf"
echo "redis-sentinel /tmp/s2/sentinel.conf"
echo "redis-sentinel /tmp/s3/sentinel.conf"

progress 100 "安装和配置完成!"

echo "Redis已成功安装并启动。"
echo "Sentinel集群配置已完成。"
echo "要停止Redis，请运行: redis-cli shutdown"
echo "请在不同的终端窗口中运行上述Sentinel启动命令来启动Sentinel集群。"

#!/bin/bash

# 彩色输出的函数定义
function echo_color() {
    local color=$1
    local message=$2
    echo -e "\033[${color}m${message}\033[0m"
}

# 打印进度的函数定义
function print_progress() {
    local step=$1
    local total=$2
    local progress=$((step * 100 / total))
    echo_color "32" "步骤 $step/$total 完成 - ${progress}%"
}

# 获取本机IP地址
REDIS_IP=$(hostname -I | awk '{print $1}')

# Redis相关设置
REDIS_VERSION="6.2.4"
REDIS_TAR="redis-${REDIS_VERSION}.tar.gz"
REDIS_URL="https://dlink.host/1drv/aHR0cHM6Ly8xZHJ2Lm1zL3UvcyFBZ1NYRUpYME43RzliMTV6M2ItTlFza3RCdE0_ZT1RdXZjSGI.tar.gz"

# Sentinel相关设置
SENTINEL_PORTS=("27001" "27002" "27003")
SENTINEL_DIRS=("s1" "s2" "s3")
SENTINEL_CONFIG_TEMPLATE="sentinel.conf"

# 步骤1: 下载Redis安装包
echo_color "34" "步骤 1/9: 下载Redis安装包"
wget -O ${REDIS_TAR} ${REDIS_URL}
if [ $? -ne 0 ]; then
    echo_color "31" "下载Redis安装包失败！"
    exit 1
fi

print_progress 1 9

# 步骤2: 解压缩Redis安装包
echo_color "34" "步骤 2/9: 解压缩Redis安装包"
tar -xvf ${REDIS_TAR}
if [ $? -ne 0 ]; then
    echo_color "31" "解压Redis安装包失败！"
    exit 1
fi

# 检查解压后的目录名是否符合预期
if [ ! -d "redis-${REDIS_VERSION}" ]; then
    echo_color "31" "解压后的目录名不符合预期！"
    exit 1
fi

print_progress 2 9

# 步骤3: 编译Redis
echo_color "34" "步骤 3/9: 编译Redis"
cd redis-${REDIS_VERSION}
make && make install
if [ $? -ne 0 ]; then
    echo_color "31" "编译Redis失败！"
    exit 1
fi

# 返回到脚本所在目录
cd ..

print_progress 3 9

# 步骤4: 配置Redis
echo_color "34" "步骤 4/9: 配置Redis"
REDIS_CONF="redis.conf"
cp redis-${REDIS_VERSION}/redis.conf ${REDIS_CONF}.bak

# 修改redis.conf配置
sed -i 's/^bind 127.0.0.1/bind 0.0.0.0/' ${REDIS_CONF}
sed -i 's/^databases 16/databases 1/' ${REDIS_CONF}

# 检查redis.conf是否成功修改
grep -q 'bind 0.0.0.0' ${REDIS_CONF}
if [ $? -ne 0 ]; then
    echo_color "31" "修改redis.conf配置失败！"
    exit 1
fi

print_progress 4 9

# 步骤5: 启动Redis
echo_color "34" "步骤 5/9: 启动Redis"
redis-server ${REDIS_CONF} &
if [ $? -ne 0 ]; then
    echo_color "31" "启动Redis失败！"
    exit 1
fi

# 等待Redis启动
sleep 5

print_progress 5 9

# 步骤6: 创建Sentinel目录
echo_color "34" "步骤 6/9: 创建Sentinel目录"
SENTINEL_BASE_DIR="/etc/redis/sentinel"
mkdir -p ${SENTINEL_BASE_DIR}
for dir in "${SENTINEL_DIRS[@]}"; do
    mkdir -p ${SENTINEL_BASE_DIR}/${dir}
done

print_progress 6 9

# 步骤7: 创建Sentinel配置文件
echo_color "34" "步骤 7/9: 创建Sentinel配置文件"
cat <<EOL > ${SENTINEL_BASE_DIR}/${SENTINEL_DIRS[0]}/${SENTINEL_CONFIG_TEMPLATE}
port ${SENTINEL_PORTS[0]}
sentinel announce-ip ${REDIS_IP}
sentinel monitor mymaster ${REDIS_IP} 7001 2
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 60000
dir "${SENTINEL_BASE_DIR}/${SENTINEL_DIRS[0]}"
EOL

# 拷贝配置文件到其他目录并修改端口
for i in {1..2}; do
    cp ${SENTINEL_BASE_DIR}/${SENTINEL_DIRS[0]}/${SENTINEL_CONFIG_TEMPLATE} ${SENTINEL_BASE_DIR}/${SENTINEL_DIRS[$i]}/
    sed -i -e "s/${SENTINEL_PORTS[0]}/${SENTINEL_PORTS[$i]}/g" -e "s|${SENTINEL_BASE_DIR}/${SENTINEL_DIRS[0]}|${SENTINEL_BASE_DIR}/${SENTINEL_DIRS[$i]}|g" ${SENTINEL_BASE_DIR}/${SENTINEL_DIRS[$i]}/${SENTINEL_CONFIG_TEMPLATE}
done

print_progress 7 9

# 步骤8: 启动Sentinel实例
echo_color "34" "步骤 8/9: 启动Sentinel实例"
for i in "${!SENTINEL_PORTS[@]}"; do
    port=${SENTINEL_PORTS[$i]}
    dir=${SENTINEL_DIRS[$i]}
    echo_color "33" "启动Sentinel实例 ${port}..."
    redis-sentinel ${SENTINEL_BASE_DIR}/${dir}/${SENTINEL_CONFIG_TEMPLATE} &
done

# 等待Sentinel启动
sleep 5

print_progress 8 9

# 步骤9: 完成
echo_color "32" "步骤 9/9: 所有步骤完成！"
echo_color "32" "Redis和Sentinel集群已经启动并运行。请检查日志确认配置。"
print_progress 9 9

#!/bin/bash

# 定义颜色变量
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

yum install wget -y
# 将CentOS-Base.repo备份
printf "${YELLOW}正在备份CentOS-Base.repo...${NC}\n"
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
if [ $? -eq 0 ]; then
    printf "${GREEN}备份成功!${NC}\n"
else
    printf "${RED}备份失败!${NC}\n"
    exit 1
fi

# 下载新的CentOS-Base.repo
printf "${YELLOW}正在下载新的CentOS-Base.repo...${NC}\n"
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.cloud.tencent.com/repo/centos7_base.repo
if [ $? -eq 0 ]; then
    printf "${GREEN}下载成功!${NC}\n"
else
    printf "${RED}下载失败!${NC}\n"
    exit 1
fi

# 清理并生成新的缓存
printf "${YELLOW}正在清理并生成新的缓存...${NC}\n"
yum clean all
yum makecache
if [ $? -eq 0 ]; then
    printf "${GREEN}操作成功!${NC}\n"
else
    printf "${RED}操作失败!${NC}\n"
    exit 1
fi

printf "${BLUE}所有操作已完成!${NC}\n"

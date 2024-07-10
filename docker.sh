#!/bin/bash

# 检查并清理现有的Docker环境
echo -e "\033[34m检查并清理现有的Docker环境...\033[0m"
if command -v docker &>/dev/null; then
    echo -e "\033[33m发现现有Docker环境，准备清理...\033[0m"
    sudo systemctl stop docker
    sudo yum remove docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
    sudo rm -rf /var/lib/docker
    sudo rm -rf /var/lib/containerd
    echo -e "\033[32m现有Docker环境已清理完成。\033[0m"
else
    echo -e "\033[32m没有发现现有Docker环境。\033[0m"
fi

# 2.1 安装Docker

# （1）更新yum包到最新
echo -e "\033[34m更新yum包到最新...\033[0m"
sudo yum update -y

# （2）安装必要的软件包
echo -e "\033[34m安装必要的软件包...\033[0m"
sudo yum install -y yum-utils device-mapper-persistent-data lvm2

# （3）设置yum源为阿里云
echo -e "\033[34m设置yum源为阿里云...\033[0m"
sudo yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

# （4）安装docker
echo -e "\033[34m安装docker...\033[0m"
sudo yum install docker-ce -y

# （5）安装后查看docker版本
echo -e "\033[34m查看docker版本...\033[0m"
docker -v

# 2.2 设置ustc的镜像
echo -e "\033[34m配置ustc镜像加速器...\033[0m"
# 创建或编辑daemon.json文件
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://docker.mirrors.ustc.edu.cn"]
}
EOF

# 2.3 Docker的启动与停止

# 启动docker
echo -e "\033[34m启动docker服务...\033[0m"
sudo systemctl start docker

# 可选：设置Docker开机自启
echo -e "\033[34m设置Docker开机自启...\033[0m"
sudo systemctl enable docker

echo -e "\033[32mDocker安装与配置完成！\033[0m"

echo -e "\033[34m当前Docker安装版本\033[0m"
docker -v

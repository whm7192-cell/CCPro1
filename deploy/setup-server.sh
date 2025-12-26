#!/bin/bash

# PAD诊断系统 - 阿里云服务器初始化脚本
# 使用方法：sudo bash setup-server.sh

set -e

echo "======================================"
echo "  PAD诊断系统 - 服务器环境配置"
echo "======================================"

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}请使用 sudo 运行此脚本${NC}"
    exit 1
fi

# 1. 更新系统
echo -e "${YELLOW}[1/6] 更新系统包...${NC}"
apt update && apt upgrade -y

# 2. 确认Nginx已安装
echo -e "${YELLOW}[2/6] 检查Nginx...${NC}"
if ! command -v nginx &> /dev/null; then
    echo -e "${RED}Nginx未安装，正在安装...${NC}"
    apt install nginx -y
fi
nginx -v

# 3. 安装Git（如果未安装）
echo -e "${YELLOW}[3/6] 检查Git...${NC}"
if ! command -v git &> /dev/null; then
    echo "Git未安装，正在安装..."
    apt install git -y
fi
git --version

# 4. 创建部署目录
echo -e "${YELLOW}[4/6] 创建部署目录...${NC}"
DEPLOY_DIR="/var/www/ccpro1"
mkdir -p $DEPLOY_DIR
chown -R www-data:www-data $DEPLOY_DIR
chmod -R 755 $DEPLOY_DIR
echo "部署目录: $DEPLOY_DIR"

# 5. 配置Nginx
echo -e "${YELLOW}[5/6] 配置Nginx...${NC}"

# 获取服务器IP
SERVER_IP=$(curl -s ifconfig.me || echo "your-server-ip")

# 创建Nginx配置文件
cat > /etc/nginx/sites-available/ccpro1 << EOF
server {
    listen 80;
    server_name $SERVER_IP;

    root $DEPLOY_DIR;
    index index.html;

    access_log /var/log/nginx/ccpro1_access.log;
    error_log /var/log/nginx/ccpro1_error.log;

    charset utf-8;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 7d;
        add_header Cache-Control "public, immutable";
    }

    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
}
EOF

# 启用站点
ln -sf /etc/nginx/sites-available/ccpro1 /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default  # 删除默认站点

# 测试Nginx配置
nginx -t

# 6. 启动服务
echo -e "${YELLOW}[6/6] 启动服务...${NC}"
systemctl enable nginx
systemctl restart nginx

echo ""
echo -e "${GREEN}======================================"
echo "  服务器配置完成！"
echo "======================================${NC}"
echo ""
echo -e "部署目录: ${GREEN}$DEPLOY_DIR${NC}"
echo -e "访问地址: ${GREEN}http://$SERVER_IP${NC}"
echo ""
echo "下一步操作："
echo "1. 在GitHub仓库中配置Secrets（见 DEPLOY.md）"
echo "2. 推送代码到GitHub，将自动部署"
echo ""
echo -e "${YELLOW}提示：确保服务器安全组已开放80端口！${NC}"
echo ""

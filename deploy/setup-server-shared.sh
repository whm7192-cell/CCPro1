#!/bin/bash

# PAD诊断系统 - 多项目共存服务器配置脚本
# 适用于已有 Nginx 项目的服务器
# 使用方法：sudo bash setup-server-shared.sh

set -e

echo "=============================================="
echo "  PAD诊断系统 - 多项目共存配置"
echo "=============================================="

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}请使用 sudo 运行此脚本${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}此脚本将配置 PAD 诊断系统，不会影响现有项目${NC}"
echo ""

# 1. 检查 Nginx
echo -e "${YELLOW}[1/4] 检查 Nginx...${NC}"
if ! command -v nginx &> /dev/null; then
    echo -e "${RED}错误：Nginx 未安装！${NC}"
    echo "请先安装 Nginx: sudo apt install nginx"
    exit 1
fi
echo -e "${GREEN}✓ Nginx 已安装${NC}"
nginx -v

# 2. 创建部署目录
echo -e "\n${YELLOW}[2/4] 创建部署目录...${NC}"
DEPLOY_DIR="/var/www/ccpro1"
mkdir -p $DEPLOY_DIR
chown -R www-data:www-data $DEPLOY_DIR
chmod -R 755 $DEPLOY_DIR
echo -e "${GREEN}✓ 部署目录创建成功: $DEPLOY_DIR${NC}"

# 3. 检测现有 Nginx 配置
echo -e "\n${YELLOW}[3/4] 检测现有 Nginx 配置...${NC}"

# 查找主要配置文件
CONFIG_FILE=""
if [ -f "/etc/nginx/sites-available/default" ]; then
    CONFIG_FILE="/etc/nginx/sites-available/default"
elif [ -f "/etc/nginx/conf.d/default.conf" ]; then
    CONFIG_FILE="/etc/nginx/conf.d/default.conf"
elif [ -f "/etc/nginx/nginx.conf" ]; then
    CONFIG_FILE="/etc/nginx/nginx.conf"
fi

if [ -z "$CONFIG_FILE" ]; then
    echo -e "${RED}未找到 Nginx 配置文件${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 找到配置文件: $CONFIG_FILE${NC}"

# 备份现有配置
BACKUP_FILE="${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
cp $CONFIG_FILE $BACKUP_FILE
echo -e "${GREEN}✓ 已备份配置到: $BACKUP_FILE${NC}"

# 4. 生成配置建议
echo -e "\n${YELLOW}[4/4] 生成配置...${NC}"

cat > /tmp/ccpro1_nginx_snippet.conf << 'EOF'
# ==================== PAD诊断系统配置 ====================
# 将以下内容添加到你的 server 块中

location /pad/ {
    alias /var/www/ccpro1/;
    index index.html;
    try_files $uri $uri/ =404;

    charset utf-8;

    # 静态文件缓存
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 7d;
        add_header Cache-Control "public, immutable";
    }
}

# 可选：自动重定向 /pad 到 /pad/
location = /pad {
    return 301 /pad/;
}
EOF

echo -e "${GREEN}✓ 配置片段已生成${NC}"

# 检查是否已经配置
if grep -q "location /pad/" $CONFIG_FILE; then
    echo -e "${YELLOW}⚠ 检测到已存在 /pad/ 配置${NC}"
else
    echo -e "\n${BLUE}================================================${NC}"
    echo -e "${BLUE}  手动配置步骤（重要！）${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""
    echo -e "1. 编辑 Nginx 配置文件："
    echo -e "   ${GREEN}sudo nano $CONFIG_FILE${NC}"
    echo ""
    echo -e "2. 在现有的 ${YELLOW}server { ... }${NC} 块中，添加以下内容："
    echo -e "   ${GREEN}（在 location / { proxy_pass ... } 之后）${NC}"
    echo ""
    cat /tmp/ccpro1_nginx_snippet.conf
    echo ""
    echo -e "3. 保存并退出（Ctrl+O, Enter, Ctrl+X）"
    echo ""
    echo -e "4. 测试配置："
    echo -e "   ${GREEN}sudo nginx -t${NC}"
    echo ""
    echo -e "5. 重新加载 Nginx："
    echo -e "   ${GREEN}sudo systemctl reload nginx${NC}"
    echo ""
fi

# 5. 显示当前配置预览
echo -e "\n${BLUE}================================================${NC}"
echo -e "${BLUE}  当前 Nginx 配置预览${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
grep -A 5 "server {" $CONFIG_FILE | head -n 20 || true
echo ""

# 6. 完成提示
echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  服务器环境配置完成！${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo -e "部署目录: ${GREEN}$DEPLOY_DIR${NC}"
echo -e "配置文件: ${GREEN}$CONFIG_FILE${NC}"
echo -e "配置备份: ${GREEN}$BACKUP_FILE${NC}"
echo ""
echo -e "${YELLOW}下一步操作：${NC}"
echo "1. 手动添加 Nginx 配置（见上面的说明）"
echo "2. 测试配置：sudo nginx -t"
echo "3. 重新加载：sudo systemctl reload nginx"
echo "4. 在 GitHub 配置 Secrets（见 DEPLOY.md）"
echo "5. 推送代码，自动部署"
echo ""
echo -e "${BLUE}配置参考：${NC}"
echo "- 完整文档：deploy/MULTI_PROJECT_SETUP.md"
echo "- 配置示例：deploy/nginx-shared.conf"
echo ""
echo -e "${YELLOW}访问地址：${NC}"
echo "- 现有项目：http://你的域名/"
echo "- PAD诊断：http://你的域名/pad/"
echo "- PAD管理：http://你的域名/pad/admin.html"
echo ""
echo -e "${GREEN}✓ 脚本执行完成${NC}"
echo ""

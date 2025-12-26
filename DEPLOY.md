# 阿里云自动部署指南

本文档将指导你如何将PAD诊断系统自动部署到阿里云服务器。

> 💡 **服务器上已有其他项目？** 查看 [多项目共存配置指南](deploy/MULTI_PROJECT_SETUP.md)

## 📋 前置要求

- ✅ 阿里云服务器（已安装 Ubuntu/CentOS）
- ✅ 服务器已安装 Nginx
- ✅ 本地已配置 Git 和 GitHub
- ✅ 有服务器 SSH 访问权限

## 🔀 两种部署场景

### 场景A：服务器上还没有其他项目（独立部署）
使用本文档的标准配置

### 场景B：服务器上已有其他项目（多项目共存）
**👉 请查看 [多项目共存配置指南](deploy/MULTI_PROJECT_SETUP.md)**

访问方式将是：`http://你的域名/pad/`

---

## 🚀 快速部署（三步完成）

### 第一步：配置服务器

#### 1.1 登录阿里云服务器

```bash
ssh root@你的服务器IP
```

#### 1.2 运行初始化脚本

```bash
# 下载并运行服务器配置脚本
wget https://raw.githubusercontent.com/whm7192-cell/CCPro1/main/deploy/setup-server.sh
sudo bash setup-server.sh
```

或者手动执行：

```bash
# 创建部署目录
sudo mkdir -p /var/www/ccpro1
sudo chown -R www-data:www-data /var/www/ccpro1
sudo chmod -R 755 /var/www/ccpro1

# 复制Nginx配置
sudo nano /etc/nginx/sites-available/ccpro1
# 粘贴 deploy/nginx.conf 的内容，并修改域名/IP

# 启用站点
sudo ln -s /etc/nginx/sites-available/ccpro1 /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default  # 可选：删除默认站点

# 测试并重启Nginx
sudo nginx -t
sudo systemctl restart nginx
```

#### 1.3 配置安全组

在阿里云控制台，确保安全组已开放：
- **80端口**（HTTP）
- **22端口**（SSH，用于部署）

---

### 第二步：生成并配置 SSH 密钥

#### 2.1 在本地生成 SSH 密钥对

```bash
# 生成新的SSH密钥（如果还没有）
ssh-keygen -t rsa -b 4096 -C "deploy@ccpro1" -f ~/.ssh/ccpro1_deploy

# 查看私钥（稍后要用）
cat ~/.ssh/ccpro1_deploy

# 查看公钥
cat ~/.ssh/ccpro1_deploy.pub
```

#### 2.2 将公钥添加到服务器

```bash
# 复制公钥内容
cat ~/.ssh/ccpro1_deploy.pub

# 登录服务器
ssh root@你的服务器IP

# 添加公钥到授权文件
mkdir -p ~/.ssh
echo "你的公钥内容" >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# 退出服务器
exit
```

#### 2.3 测试 SSH 连接

```bash
# 测试免密登录
ssh -i ~/.ssh/ccpro1_deploy root@你的服务器IP

# 如果成功连接，说明配置正确
```

---

### 第三步：配置 GitHub Secrets

#### 3.1 获取 SSH 私钥内容

```bash
# 在本地运行，复制完整输出
cat ~/.ssh/ccpro1_deploy
```

复制从 `-----BEGIN OPENSSH PRIVATE KEY-----` 到 `-----END OPENSSH PRIVATE KEY-----` 的所有内容。

#### 3.2 在 GitHub 仓库配置 Secrets

1. 打开你的 GitHub 仓库：https://github.com/whm7192-cell/CCPro1

2. 点击 **Settings** → **Secrets and variables** → **Actions**

3. 点击 **New repository secret**，添加以下四个密钥：

| 名称 | 值 | 说明 |
|------|-----|------|
| `SERVER_SSH_KEY` | 完整的私钥内容 | SSH 私钥（包含 BEGIN 和 END 行） |
| `SERVER_HOST` | 你的服务器IP或域名 | 例如：`123.456.78.90` |
| `SERVER_USER` | 服务器用户名 | 通常是 `root` |
| `DEPLOY_PATH` | 部署路径 | `/var/www/ccpro1` |

**配置示例：**

```
SERVER_SSH_KEY:
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUA...（完整私钥）
-----END OPENSSH PRIVATE KEY-----

SERVER_HOST: 123.456.78.90

SERVER_USER: root

DEPLOY_PATH: /var/www/ccpro1
```

---

## ✅ 测试自动部署

### 手动触发部署

1. 进入 GitHub 仓库的 **Actions** 标签页
2. 选择 "自动部署到阿里云" 工作流
3. 点击 **Run workflow** → **Run workflow**
4. 等待部署完成（约 30 秒）

### 自动触发部署

每次推送代码到 `main` 分支时，会自动触发部署：

```bash
# 本地修改代码后
git add .
git commit -m "更新功能"
git push origin main

# GitHub Actions 会自动部署到服务器
```

---

## 🌐 访问网站

部署成功后，访问：

- **主诊断页面**：`http://你的服务器IP/index.html`
- **管理后台**：`http://你的服务器IP/admin.html`

---

## 🔧 常见问题

### 1. 部署失败：Permission denied

**原因**：SSH 密钥权限问题

**解决**：
```bash
# 在服务器上执行
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

### 2. Nginx 403 Forbidden

**原因**：文件权限问题

**解决**：
```bash
sudo chown -R www-data:www-data /var/www/ccpro1
sudo chmod -R 755 /var/www/ccpro1
```

### 3. 无法访问网站

**检查清单**：
- ✅ Nginx 是否运行：`sudo systemctl status nginx`
- ✅ 80 端口是否开放：`sudo netstat -tlnp | grep 80`
- ✅ 阿里云安全组是否开放 80 端口
- ✅ 防火墙是否允许：`sudo ufw allow 80`

### 4. GitHub Actions 部署失败

**检查步骤**：
1. 确认 Secrets 配置正确（注意私钥格式）
2. 检查服务器 SSH 22 端口是否开放
3. 查看 Actions 日志中的具体错误信息

---

## 🔒 配置 HTTPS（可选）

### 使用 Let's Encrypt 免费证书

```bash
# 安装 Certbot
sudo apt install certbot python3-certbot-nginx -y

# 自动配置 HTTPS
sudo certbot --nginx -d 你的域名.com

# 设置自动续期
sudo certbot renew --dry-run
```

修改 GitHub Secrets 中的 `DEPLOY_PATH`：
```
DEPLOY_PATH: /var/www/ccpro1
```

---

## 📊 部署流程图

```
开发者推送代码到 GitHub
         ↓
GitHub Actions 自动触发
         ↓
使用 SSH 连接到阿里云服务器
         ↓
将代码同步到 /var/www/ccpro1
         ↓
重新加载 Nginx 配置
         ↓
部署完成，网站自动更新
```

---

## 🛠 手动部署（备选方案）

如果不想使用自动部署，可以手动部署：

```bash
# 在本地
git clone https://github.com/whm7192-cell/CCPro1.git
cd CCPro1

# 使用 SCP 上传文件
scp -r index.html admin.html root@你的服务器IP:/var/www/ccpro1/

# 或使用 rsync
rsync -avz --exclude='.git' ./ root@你的服务器IP:/var/www/ccpro1/
```

---

## 📝 维护建议

### 定期备份

```bash
# 在服务器上定期备份网站文件
tar -czf /backup/ccpro1_$(date +%Y%m%d).tar.gz /var/www/ccpro1
```

### 查看日志

```bash
# Nginx 访问日志
sudo tail -f /var/log/nginx/ccpro1_access.log

# Nginx 错误日志
sudo tail -f /var/log/nginx/ccpro1_error.log
```

### 监控服务状态

```bash
# 检查 Nginx 状态
sudo systemctl status nginx

# 重启 Nginx
sudo systemctl restart nginx
```

---

## 📞 需要帮助？

- 查看 GitHub Actions 运行日志
- 检查服务器 Nginx 错误日志
- 提交 Issue：https://github.com/whm7192-cell/CCPro1/issues

---

## 🎉 完成！

现在你的 PAD 诊断系统已经配置了自动部署。每次修改代码并推送到 GitHub，系统会自动部署到阿里云服务器！

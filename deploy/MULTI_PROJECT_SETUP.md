# 多项目共存配置指南

## 场景说明

你的服务器上已有：
- 现有项目运行在端口 **5001**
- Nginx 反向代理配置已存在

现在要部署 PAD 诊断系统，通过 **子路径访问**，互不影响。

---

## 📍 访问路径规划

配置完成后的访问方式：

| 项目 | 访问地址 |
|------|----------|
| 现有项目 | `http://你的域名/` （保持不变） |
| PAD诊断系统 | `http://你的域名/pad/` （新增） |
| PAD管理后台 | `http://你的域名/pad/admin.html` （新增） |

---

## 🔧 配置步骤

### 第一步：创建部署目录

```bash
# SSH 登录服务器
ssh root@你的服务器IP

# 创建 PAD 诊断系统的部署目录
sudo mkdir -p /var/www/ccpro1
sudo chown -R www-data:www-data /var/www/ccpro1
sudo chmod -R 755 /var/www/ccpro1
```

### 第二步：修改 Nginx 配置

#### 方案A：直接修改现有配置文件（推荐）

```bash
# 1. 找到你现有的 Nginx 配置文件
# 通常在这些位置之一：
# - /etc/nginx/sites-available/default
# - /etc/nginx/conf.d/default.conf
# - /etc/nginx/nginx.conf

# 2. 编辑配置文件
sudo nano /etc/nginx/sites-available/default

# 3. 在现有的 server 块中，添加以下 location 配置
# （在你现有的 location / { proxy_pass ... } 之后添加）
```

在你的 Nginx 配置文件中添加：

```nginx
server {
    listen 80;
    server_name your-domain.com;  # 你的域名或IP

    # ==================== 现有项目（保持不变）====================
    location / {
        proxy_pass http://127.0.0.1:5001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # ==================== 新增：PAD诊断系统 ====================
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
}
```

#### 方案B：查看现有配置示例

如果不确定如何修改，先查看现有配置：

```bash
# 查看当前 Nginx 配置
sudo nginx -T | grep -A 20 "server {"

# 或查看具体文件
cat /etc/nginx/sites-available/default
```

### 第三步：测试并重启 Nginx

```bash
# 测试配置语法
sudo nginx -t

# 如果测试通过，重新加载配置
sudo systemctl reload nginx

# 如果测试失败，检查错误信息并修正
```

### 第四步：配置自动部署

修改 GitHub Actions 部署路径保持不变（`/var/www/ccpro1`），不影响现有项目。

GitHub Secrets 配置：

| 名称 | 值 |
|------|-----|
| `SERVER_SSH_KEY` | 你的 SSH 私钥 |
| `SERVER_HOST` | 你的服务器IP |
| `SERVER_USER` | `root` |
| `DEPLOY_PATH` | `/var/www/ccpro1` |

---

## 📋 完整配置示例

### 示例1：与反向代理项目共存

```nginx
server {
    listen 80;
    server_name example.com;

    # 现有项目（端口 5001）
    location / {
        proxy_pass http://127.0.0.1:5001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    # PAD 诊断系统（静态文件）
    location /pad/ {
        alias /var/www/ccpro1/;
        index index.html;
        try_files $uri $uri/ =404;
    }

    # 如果还有其他项目，继续添加
    # location /admin/ {
    #     proxy_pass http://127.0.0.1:3000;
    # }
}
```

### 示例2：多个静态网站共存

```nginx
server {
    listen 80;
    server_name example.com;

    # 主网站
    location / {
        root /var/www/main-site;
        index index.html;
    }

    # PAD 诊断系统
    location /pad/ {
        alias /var/www/ccpro1/;
        index index.html;
    }

    # 文档站点
    location /docs/ {
        alias /var/www/docs/;
        index index.html;
    }
}
```

---

## ✅ 验证配置

### 1. 检查文件部署

```bash
# SSH 登录服务器
ssh root@你的服务器IP

# 检查目录和文件
ls -la /var/www/ccpro1/

# 应该看到：
# index.html
# admin.html
```

### 2. 测试访问

```bash
# 在服务器上测试
curl http://localhost/pad/

# 应该返回 HTML 内容
```

### 3. 浏览器访问

- 现有项目：`http://你的域名/`
- PAD诊断：`http://你的域名/pad/`
- PAD管理：`http://你的域名/pad/admin.html`

---

## 🔍 常见问题

### Q1: 访问 /pad/ 出现 404

**原因**：Nginx 配置中的 `alias` 路径不正确

**解决**：
```bash
# 检查路径是否存在
ls -la /var/www/ccpro1/

# 确保 alias 后面有斜杠
location /pad/ {
    alias /var/www/ccpro1/;  # ← 结尾的斜杠很重要！
}
```

### Q2: 访问 /pad/ 被重定向到现有项目

**原因**：location 匹配顺序问题

**解决**：将 `location /pad/` 配置放在 `location /` 之前，或使用更精确的匹配：

```nginx
# 精确匹配
location ^~ /pad/ {
    alias /var/www/ccpro1/;
}
```

### Q3: 静态文件（CSS/JS）加载失败

**原因**：路径问题或缓存问题

**解决**：
```bash
# 检查文件权限
sudo chmod -R 755 /var/www/ccpro1

# 清除浏览器缓存，或使用无痕模式访问
```

### Q4: 部署后看不到更新

**原因**：浏览器缓存或 Nginx 缓存

**解决**：
```bash
# 重新加载 Nginx
sudo systemctl reload nginx

# 清除浏览器缓存（Ctrl+Shift+R 强制刷新）
```

---

## 📊 路径对比表

| 类型 | 配置方式 | 文件路径 | 访问URL |
|------|----------|----------|---------|
| `root` | `root /var/www/ccpro1;` | `/var/www/ccpro1/pad/index.html` | `/pad/index.html` |
| `alias` | `alias /var/www/ccpro1/;` | `/var/www/ccpro1/index.html` | `/pad/index.html` |

**注意**：我们使用 `alias`，所以文件直接放在 `/var/www/ccpro1/` 下，访问时需要加 `/pad/` 前缀。

---

## 🚀 自动部署流程

配置完成后，每次推送代码：

```bash
git add .
git commit -m "更新功能"
git push origin main
```

GitHub Actions 会：
1. 连接到服务器
2. 将文件同步到 `/var/www/ccpro1/`
3. 重新加载 Nginx
4. 现有项目继续运行在端口 5001，互不影响！

---

## 🔒 安全建议

### 1. 限制访问（可选）

如果只允许内网访问 PAD 系统：

```nginx
location /pad/ {
    alias /var/www/ccpro1/;

    # 只允许特定 IP 访问
    allow 192.168.1.0/24;  # 内网IP段
    allow 123.45.67.89;     # 特定IP
    deny all;
}
```

### 2. 基本认证（可选）

添加密码保护：

```bash
# 安装工具
sudo apt install apache2-utils

# 创建密码文件
sudo htpasswd -c /etc/nginx/.htpasswd admin

# 在 Nginx 配置中添加
location /pad/ {
    alias /var/www/ccpro1/;
    auth_basic "PAD诊断系统";
    auth_basic_user_file /etc/nginx/.htpasswd;
}
```

---

## 📝 快速检查清单

部署前确认：

- [ ] 部署目录已创建：`/var/www/ccpro1`
- [ ] 目录权限正确：`755`，所有者：`www-data`
- [ ] Nginx 配置已添加 `location /pad/` 块
- [ ] Nginx 语法测试通过：`sudo nginx -t`
- [ ] Nginx 已重新加载：`sudo systemctl reload nginx`
- [ ] GitHub Secrets 配置完成
- [ ] 浏览器可以访问：`http://你的域名/pad/`

---

## 🎉 完成！

现在你的服务器上运行了两个项目：

✅ **现有项目**：`http://你的域名/` → 反向代理到端口 5001
✅ **PAD诊断系统**：`http://你的域名/pad/` → 静态文件，互不影响

需要帮助？查看 Nginx 错误日志：
```bash
sudo tail -f /var/log/nginx/error.log
```

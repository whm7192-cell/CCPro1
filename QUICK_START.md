# 快速开始指南

## 📁 项目文件说明

```
CCPro1/
├── index.html                      # 主诊断页面（客服使用）
├── admin.html                      # 管理后台（查看记录）
├── README.md                       # 项目说明文档
├── DEPLOY.md                       # 阿里云部署详细教程
├── QUICK_START.md                  # 快速开始指南（本文件）
├── LICENSE                         # MIT 开源协议
├── .gitignore                      # Git 忽略文件配置
│
├── .github/
│   └── workflows/
│       └── deploy.yml              # GitHub Actions 自动部署配置
│
└── deploy/
    ├── nginx.conf                  # Nginx 独立部署配置
    ├── nginx-shared.conf           # Nginx 多项目共存配置
    ├── setup-server.sh             # 独立服务器初始化脚本
    ├── setup-server-shared.sh      # 多项目共存配置脚本
    └── MULTI_PROJECT_SETUP.md      # 多项目共存详细教程
```

---

## 🎯 5分钟上手

### 本地测试

```bash
# 1. 克隆或下载项目
cd CCPro1

# 2. 启动本地服务器
python3 -m http.server 8000

# 3. 浏览器访问
open http://localhost:8000/index.html
```

### 阿里云部署（多项目共存）

> 💡 **服务器上已有其他项目？** 使用子路径 `/pad/` 访问，互不影响！

```bash
# 1. 登录服务器
ssh root@你的服务器IP

# 2. 运行多项目共存配置脚本
wget https://raw.githubusercontent.com/whm7192-cell/CCPro1/main/deploy/setup-server-shared.sh
sudo bash setup-server-shared.sh

# 3. 手动添加 Nginx 配置（脚本会提示）
# 在现有 server 块中添加 location /pad/ 配置

# 4. 在 GitHub 配置 Secrets（4个必需）
# 详见下方 "GitHub Secrets 配置"

# 5. 推送代码，自动部署
git push origin main
```

**详细教程**：[多项目共存配置指南](deploy/MULTI_PROJECT_SETUP.md)

---

## 📝 使用流程

### 客服人员使用 `index.html`

1. **打开页面** → `http://你的域名/pad/` 或 `http://你的服务器IP/pad/`
2. **输入 UID** → 用户的唯一标识
3. **选择问题类型** → 硬件或软件
4. **选择具体问题** → 从下拉菜单选择，或填写"其他"
5. **提交诊断** → 系统显示解决方案
6. **确认状态** → 已解决 / 未解决转人工
7. **复制结果** → 一键复制，粘贴到工单系统

### 管理员使用 `admin.html`

1. **打开页面** → `http://你的域名/pad/admin.html` 或 `http://你的服务器IP/pad/admin.html`
2. **查看统计** → 总数、已解决、未解决等
3. **筛选记录** → 按类型、状态、UID 搜索
4. **导出数据** → JSON + CSV 双格式
5. **管理记录** → 查看详情、删除记录

---

## 🌐 访问地址说明

部署完成后的访问路径：

| 页面 | 访问地址 |
|------|----------|
| 主诊断页面 | `http://你的域名/pad/` |
| 管理后台 | `http://你的域名/pad/admin.html` |
| 现有项目 | `http://你的域名/` （不受影响） |

---

## 🔑 GitHub Secrets 配置（必需）

在 GitHub 仓库设置中添加以下 Secrets：

| 名称 | 值示例 | 说明 |
|------|--------|------|
| `SERVER_SSH_KEY` | `-----BEGIN OPENSSH PRIVATE KEY-----...` | SSH 私钥完整内容 |
| `SERVER_HOST` | `123.456.78.90` | 服务器 IP 地址 |
| `SERVER_USER` | `root` | SSH 登录用户名 |
| `DEPLOY_PATH` | `/var/www/ccpro1` | 部署目标路径 |

**详细配置步骤**：查看 [DEPLOY.md](DEPLOY.md)

---

## 🔍 常见操作

### 查看部署日志

GitHub 仓库 → **Actions** → 选择最新的工作流运行

### 手动触发部署

GitHub 仓库 → **Actions** → **自动部署到阿里云** → **Run workflow**

### 服务器上查看日志

```bash
# Nginx 访问日志
sudo tail -f /var/log/nginx/ccpro1_access.log

# Nginx 错误日志
sudo tail -f /var/log/nginx/ccpro1_error.log
```

### 重启 Nginx

```bash
# 测试配置
sudo nginx -t

# 重启服务
sudo systemctl restart nginx
```

### 查看存储的记录

1. 打开浏览器控制台（F12）
2. 运行：`JSON.parse(localStorage.getItem('feedbackRecords'))`

### 导出所有记录

在 `admin.html` 页面点击"导出记录"按钮

---

## 🛡️ 安全检查清单

部署前确认：

- [ ] 阿里云安全组已开放 80 端口（HTTP）
- [ ] 阿里云安全组已开放 22 端口（SSH）
- [ ] SSH 私钥妥善保管，不要泄露
- [ ] GitHub Secrets 配置正确
- [ ] Nginx 配置文件语法正确（`nginx -t`）
- [ ] 部署目录权限正确（755）

---

## 🚨 故障排查

### 无法访问网站

```bash
# 检查 Nginx 状态
sudo systemctl status nginx

# 检查端口占用
sudo netstat -tlnp | grep 80

# 检查防火墙
sudo ufw status
sudo ufw allow 80
```

### GitHub Actions 部署失败

1. 检查 Secrets 是否配置正确
2. 确认 SSH 密钥格式完整（包含 BEGIN/END 行）
3. 测试本地 SSH 连接：`ssh -i ~/.ssh/key root@服务器IP`
4. 查看 Actions 日志中的详细错误信息

### 记录数据丢失

**原因**：localStorage 是浏览器本地存储
- 清除浏览器缓存会删除数据
- 更换浏览器/设备会看不到数据

**解决**：定期使用 `admin.html` 导出记录

---

## 📞 获取帮助

- **部署问题**：查看 [DEPLOY.md](DEPLOY.md)
- **功能说明**：查看 [README.md](README.md)
- **提交 Issue**：https://github.com/whm7192-cell/CCPro1/issues

---

## 🎉 开始使用

现在一切就绪！修改代码后：

```bash
git add .
git commit -m "你的修改说明"
git push origin main
```

GitHub Actions 会自动将代码部署到阿里云服务器 🚀

# Docker 部署指南

本目录包含完整的 Docker 部署配置，支持 GitHub Actions 自动构建和推送。

## 📦 Docker 镜像

- **Docker Hub**: `kobex95/nanobot-now:latest`
- **多架构支持**: linux/amd64, linux/arm64
- **构建特性**: 包含所有可选特性（feishu-websocket, dingtalk-stream, qq-botrs）

## 🚀 快速开始

### 方式一：Docker Compose（推荐）

```bash
# 1. 克隆项目
git clone https://github.com/kobex95/nanobot-now.git
cd nanobot-now

# 2. 创建配置目录
mkdir -p config data

# 3. 编辑配置文件（见下方示例）
vi config/config.json

# 4. 启动服务
docker-compose up -d

# 5. 查看日志
docker-compose logs -f nanobot

# 6. 访问 WebUI
浏览器打开：http://localhost:18890
```

### 方式二：纯 Docker 命令

```bash
# 创建配置和数据目录
mkdir -p ~/.nanobot/config ~/.nanobot/data

# 编辑配置
vi ~/.nanobot/config/config.json

# 运行容器
docker run -d \
  --name nanobot \
  --restart unless-stopped \
  -p 18890:18890 \
  -v ~/.nanobot/config:/home/nanobot/.nanobot:rw \
  -v ~/.nanobot/data:/data:rw \
  -e TZ=Asia/Shanghai \
  kobex95/nanobot-now:latest
```

## ⚙️ 配置说明

### 配置文件位置

配置文件挂载到容器内的 `/home/nanobot/.nanobot/config.json`。

### 最小配置示例

```json
{
  "providers": {
    "openai": {
      "apiKey": "sk-xxx"
    }
  },
  "agents": {
    "defaults": {
      "model": "gpt-4o-mini"
    }
  }
}
```

### 完整配置示例

```json
{
  "providers": {
    "openai": {
      "apiKey": "sk-xxx"
    },
    "openrouter": {
      "apiKey": "sk-or-xxx",
      "extraHeaders": {
        "HTTP-Referer": "https://example.com",
        "X-Title": "nanobot-rs"
      }
    },
    "siliconflow": {
      "apiKey": "sk-xxx"
    }
  },
  "agents": {
    "defaults": {
      "model": "gpt-4o-mini",
      "maxTokens": 4096
    }
  },
  "tools": {
    "web": {
      "search": {
        "provider": "brave",
        "maxResults": 5
      }
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "123:ABC",
      "allowFrom": []
    },
    "feishu": {
      "enabled": true,
      "appId": "xxx",
      "appSecret": "xxx",
      "encryptKey": "xxx"
    }
  },
  "cron": {
    "enabled": true
  }
}
```

更多配置选项参考：[README.md](README.md)

## 🔐 环境变量覆盖

可以通过环境变量覆盖配置（优先级：环境变量 > 配置文件）：

```bash
docker run -d \
  -e NANOBOT_PROVIDERS_OPENAI_API_KEY=sk-xxx \
  -e NANOBOT_AGENTS_DEFAULTS_MODEL=gpt-4o-mini \
  kobex95/nanobot-now:latest
```

环境变量格式：`NANOBOT_<配置路径>`，用下划线代替点号。

## 📡 端口说明

- `18890`: WebUI 和 API（默认）

## 📁 数据持久化

容器运行时会在挂载的目录中生成：

- `~/.nanobot/config.json` - 配置文件
- `~/.nanobot/memory/` - 记忆文件
- `~/.nanobot/skills/` - 自定义技能
- `~/.nanobot/.nanolog` - 日志文件

**务必使用卷挂载**，否则重启容器后配置会丢失。

## 🔧 常用命令

```bash
# 进入容器
docker exec -it nanobot /bin/bash

# 查看日志
docker logs -f nanobot

# 重启服务
docker restart nanobot

# 健康检查
docker exec nanobot nanobot health

# 查看会话
docker exec nanobot nanobot sessions list

# 定时任务
docker exec nanobot nanobot cron list

# 停止并清理
docker-compose down
```

## 🔄 更新镜像

```bash
# 拉取最新镜像
docker pull kobex95/nanobot-now:latest

# 重启容器
docker-compose restart

# 或（如果使用 docker run）
docker stop nanobot && docker rm nanobot
docker run ... # 重新运行上面的命令
```

## 🐛 故障排查

### 1. 容器启动失败

```bash
docker logs nanobot
```

检查日志看是否有配置错误或 API key 问题。

### 2. WebUI 无法访问

- 确认端口 18890 已正确映射
- 检查防火墙规则
- 尝试 `localhost:18890` 而非 `127.0.0.1:18890`

### 3. 通道不工作

确认 `config.json` 中对应 channel 的 `enabled: true`，并已填写正确的 token/密钥。

### 4. 构建自定义镜像

```bash
docker build -t my-nanobot:custom .
```

## 🏗️ GitHub Actions 自动构建

本仓库已配置 GitHub Actions 自动构建：

- 推送到 `main` 分支：构建并推送 `:latest` 和 `:分支名` 标签
- 创建 Git tag (v*.*.*)：构建并推送版本标签
- PR 构建但不推送

需要设置 Docker Hub secrets：
- `DOCKERHUB_USERNAME` - Docker Hub 用户名
- `DOCKERHUB_TOKEN` - Docker Hub Access Token

## 📝 注意事项

- 容器内运行用户为 `nanobot` (UID 1000)
- 配置文件、数据、日志都通过卷挂载到宿主机
- 支持多架构镜像（amd64/arm64）
- 建议使用 docker-compose 管理，更简洁

## 🆘 更多帮助

查看项目 [README.md](README.md) 获取完整功能说明和配置文档。

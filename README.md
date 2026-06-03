# 拼多多 AI 客服助手 — Linux / Docker 部署

## 环境要求

- Docker >= 20.10
- Docker Compose >= 2.0
- 至少 2GB 可用内存（Chromium 浏览器 + PyQt6 GUI）

---

## 安装与启动

### 1. 准备配置文件

在 `linux/` 目录下创建 `config.json`，填入你的 LLM 配置：

```json
{
    "business_hours": {
        "start": "08:00",
        "end": "23:00"
    },
    "llm": {
        "model_name": "你的模型名称",
        "api_key": "你的API密钥",
        "api_base": "你的API地址"
    },
    "prompt": {
        "instructions": [
            "1. 请用中文回复客户问题",
            "2. 优先使用知识库回答",
            "3. 知识库无结果时建议联系人工客服"
        ]
    },
    "db_path": "./temp/channel_shop.db"
}
```

如果不创建 `config.json`，应用启动后会自动生成默认配置，可在界面中修改。

### 2. 构建并启动

```bash
cd linux
docker compose up -d --build
```

首次构建大约需要 3-5 分钟（下载依赖 + Playwright Chromium）。

### 3. 访问界面

浏览器打开 **http://localhost:6080**，即可看到完整的拼多多 AI 客服助手桌面界面。

> 如果端口被占用，修改 `docker-compose.yml` 中的 `6080:6080` 为其他端口，如 `8080:6080`。

---

## 常用操作

```bash
# 查看日志
docker compose logs -f

# 重启
docker compose restart

# 停止
docker compose down

# 停止并删除数据卷（会清除数据库）
docker compose down -v
```

---

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `RESOLUTION` | `1280x800` | 虚拟桌面分辨率 |

修改分辨率启动：

```bash
RESOLUTION=1920x1080 docker compose up -d
```

---

## 数据持久化

| 挂载路径 | 说明 |
|----------|------|
| `./config.json` | 配置文件 |
| `./temp/` | 数据库文件（`channel_shop.db`）及临时文件 |
| `agent-data` (Docker Volume) | 应用内部数据 |

---

## 容器架构

```
┌──────────────────────────────────────┐
│  Docker Container                    │
│                                      │
│  Xvfb (虚拟显示器 :99)               │
│      ↓                               │
│  PyQt6 桌面应用 (app.py)             │
│      ↓                               │
│  x11vnc (VNC Server → port 5900)    │
│      ↓                               │
│  noVNC (WebSocket → port 6080)      │
│      ↓                               │
│  浏览器访问 http://localhost:6080    │
└──────────────────────────────────────┘
```

---

## 常见问题

**Q: 页面显示黑屏？**
等待几秒让应用完全启动，Xvfb + PyQt6 初始化需要时间。查看日志确认：`docker compose logs app`

**Q: 如何在本地 Linux 直接运行（不用 Docker）？**
安装 Python 3.11+ 和 uv，然后：
```bash
uv sync
uv run playwright install chromium
uv run playwright install-deps chromium
python app.py
```

**Q: 容器内 Chromium 启动失败？**
确保宿主机分配了足够的内存，或在 `docker-compose.yml` 中增加 `shm_size`。
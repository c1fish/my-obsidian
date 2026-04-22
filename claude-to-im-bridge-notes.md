# Claude-to-IM 桥接排障与配置经验整理

日期：2026-04-22

## 一、这次完成了什么

本次对话中，成功完成了以下事项：

1. 启动并修复了 `claude-to-im` 的 QQ 桥接
2. 配置并打通了微信桥接
3. 开启了 `CTI_AUTO_APPROVE=true`，减少微信里的 `Permission Required` 提示
4. 确认了当前桥接状态为：
   - QQ adapter 已启动
   - Weixin adapter 已启动
   - Bridge started with 2 adapter(s)

---

## 二、关键问题与根因

### 1. Windows 启动脚本兼容问题

在 `C:\Users\fish\.claude\skills\claude-to-im\scripts\supervisor-windows.ps1` 中遇到过多处 Windows / PowerShell 兼容问题：

- `Join-Path` 参数写法不兼容，导致出现 `找不到接受实际参数“bridge.log”的位置形式参数`
- 使用了 `$pid` 变量，但 PowerShell 中 `$PID` 是只读内置变量，导致报错：
  - `无法覆盖变量 PID，因为该变量为只读变量或常量`
- `Start-Process` 同时把 stdout 和 stderr 重定向到同一个文件，导致：
  - `RedirectStandardOutput 和 RedirectStandardError 相同`

#### 修复点

- 把多段 `Join-Path` 改为嵌套写法
- 将 `$pid` 改成 `$processId` / `$fallbackPid`
- 将日志拆分为：
  - `bridge.log`
  - `bridge.err.log`

---

### 2. config.env 字段名与实际代码不一致

最初配置中使用了旧字段名，导致桥接启动时出现：

- `No adapters started successfully`

#### 错误字段

- `CTI_CHANNELS`
- `CTI_QQ_ALLOWED_OPENIDS`
- `CTI_QQ_MAX_IMAGE_SIZE_MB`
- `CTI_WORK_DIR`
- `CTI_MODEL`
- `CTI_MODE`

#### 正确字段

- `CTI_ENABLED_CHANNELS`
- `CTI_QQ_ALLOWED_USERS`
- `CTI_QQ_MAX_IMAGE_SIZE`
- `CTI_DEFAULT_WORKDIR`
- `CTI_DEFAULT_MODEL`
- `CTI_DEFAULT_MODE`

---

### 3. Git Bash 在当前机器上不稳定

多次执行 bash 命令时出现：

- `fork: retry: Resource temporarily unavailable`

因此在 Windows 上更稳定的方案是：

- 优先使用 PowerShell
- 避免依赖 Git Bash 进行桥接运维

---

### 4. 微信登录脚本依赖缺失 / npm 异常

在尝试执行：

- `npm run weixin:login`

时，遇到过：

- `Cannot find package 'tsx'`
- `Cannot find package 'qrcode'`
- `npm error Cannot read properties of null (reading 'parent')`

说明本地 skill 目录依赖安装不完整，且 npm / lockfile / file dependency 存在异常。

#### 绕行策略

没有依赖官方 helper，而是通过 PowerShell 直接调用微信二维码登录接口：

- `get_bot_qrcode`
- `get_qrcode_status`

再手动生成并写入：

- `C:\Users\fish\.claude-to-im\data\weixin-accounts.json`

---

## 三、微信桥接排障的最关键经验

### 1. `weixin-accounts.json` 必须是数组，不是对象

错误格式：

```json
{
  "accountId": "...",
  "token": "..."
}
```

正确格式：

```json
[
  {
    "accountId": "...",
    "token": "..."
  }
]
```

桥接代码实际判断逻辑是：

- `listWeixinAccounts()` 返回数组
- 且每条记录必须满足：
  - `enabled === true`
  - `token` 非空

否则就会报：

- `weixin adapter not valid: No linked WeChat account. Run the WeChat QR login helper first.`

---

### 2. UTF-8 BOM 会导致 JSON.parse 失败

即使文件结构看起来正确，如果用 PowerShell 某些写法写入了 BOM，也可能导致 daemon 读文件失败，最后回退为空数组。

#### 更稳的写法

使用无 BOM 写法：

```powershell
[System.IO.File]::WriteAllText($p, $json, (New-Object System.Text.UTF8Encoding($false)))
```

---

### 3. 最终验证成功的关键日志

当微信真正接通时，日志里会出现：

- `Started adapter: weixin`
- `weixin-adapter] Poll loop started for account ...`
- `weixin-adapter] Started in single-account mode with ...`
- `Bridge started with 2 adapter(s)`

这是微信桥接成功的标志。

---

## 四、关于微信里出现 `Permission Required`

这不是故障，而是 bridge 的正常行为。

### 原因

微信 / QQ 通道没有图形按钮式交互，因此当 Claude 需要请求工具权限时，会把权限请求转成文字消息。

例如：

- `1 - Allow once`
- `2 - Allow session`
- `3 - Deny`

或者：

- `/perm allow ...`
- `/perm allow_session ...`
- `/perm deny ...`

这表示 Claude 不是在直接回答，而是在等待用户授权执行下一步工具调用。

### 解决办法

为了减少这类提示，已在配置中开启：

```env
CTI_AUTO_APPROVE=true
```

这样在个人可信环境中，大量权限请求会自动放行。

---

## 五、当前推荐配置

当前 `C:\Users\fish\.claude-to-im\config.env` 至少应包含：

```env
CTI_ENABLED_CHANNELS=qq,weixin
CTI_RUNTIME=claude
CTI_DEFAULT_MODE=plan
CTI_WEIXIN_MEDIA_ENABLED=true
CTI_AUTO_APPROVE=true
```

QQ 相关字段按实际配置填写：

```env
CTI_QQ_APP_ID=...
CTI_QQ_APP_SECRET=...
CTI_QQ_IMAGE_ENABLED=true
CTI_QQ_MAX_IMAGE_SIZE=20
```

---

## 六、常用运维命令（Windows / PowerShell）

### 启动

```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\.claude\skills\claude-to-im\scripts\supervisor-windows.ps1" start
```

### 停止

```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\.claude\skills\claude-to-im\scripts\supervisor-windows.ps1" stop
```

### 查看状态

```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\.claude\skills\claude-to-im\scripts\supervisor-windows.ps1" status
```

### 查看日志

```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\.claude\skills\claude-to-im\scripts\supervisor-windows.ps1" logs 120
```

### 查看错误日志

```powershell
Get-Content "$HOME\.claude-to-im\logs\bridge.err.log" -Tail 120
```

---

## 七、安全提醒

本次排障过程中，微信 token 曾在终端 / 对话中明文出现。

### 建议

- 成功完成桥接后，重新扫码登录一次微信
- 用新 token 覆盖旧 token
- 避免后续再把 `weixin-accounts.json` 内容完整贴到聊天里

---

## 八、后续可做的改进

1. 把修复过的 `supervisor-windows.ps1` 变更固化，避免后续更新回退
2. 为微信登录补一份无需 `tsx/qrcode` 的纯 PowerShell 备用脚本
3. 把 `weixin-accounts.json` 的正确格式做成模板
4. 如果长期使用微信通道，可增加一份“桥接运维手册”
5. 若希望 Claude 自动识别本仓库额外技能目录，可把 `D:\Fish\桌面\Note\my-obsidian\.claude\skills` 作为固定 skills 来源维护

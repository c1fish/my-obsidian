# Claude-to-IM 桥接器诊断与运维

**基于实战排障经验，提供快速诊断与修复指南**

---

## 核心诊断流程

### 1. 桥接启动检查
```
[问题] No adapters started successfully
[原因] 配置字段错误或缺少必要的微信账户
[修复] 
1. 确认 CTI_ENABLED_CHANNELS=qq,weixin
2. 验证 weixin-accounts.json 格式正确（数组非对象）
3. 确保账户 enabled: true 且 token 非空
```

### 2. 脚本兼容性修复
```
[问题] 找不到接受实际参数“bridge.log”的位置形式参数
[修复] 替换多段 Join-Path 为嵌套写法

[问题] 无法覆盖变量 PID，因为该变量为只读
[修复] 将 $pid 改成 $processId / $fallbackPid

[问题] RedirectStandardOutput 和 RedirectStandardError 相同
[修复] 分离日志文件为 bridge.log 和 bridge.err.log
```

### 3. 微信账户配置
```
[错误格式]
{
  "accountId": "...",
  "token": "..."
}

[正确格式]
[
  {
    "accountId": "...",
    "token": "...",
    "enabled": true
  }
]
```

---

## 快速启动命令（Windows/PowerShell）

### 启动桥接
```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\.claude\skills\claude-to-im\scripts\supervisor-windows.ps1" start
```

### 查看状态（实时诊断）
```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\.claude\skills\claude-to-im\scripts\supervisor-windows.ps1" status
```

### 查看错误日志
```powershell
Get-Content "$HOME\.claude-to-im\logs\bridge.err.log" -Tail 120
```

### 直接配置微信账户（绕过 npm）
```powershell
$accountJson = @'
[
  {
    "accountId": "你的微信ID",
    "token": "你的token",
    "enabled": true
  }
]
'@
$path = "$HOME\.claude-to-im\data\weixin-accounts.json"
[System.IO.File]::WriteAllText($path, $accountJson, (New-Object System.Text.UTF8Encoding($false)))
```

---

## 关键成功标志（查看 bridge.log）

```log
Started adapter: qq
Started adapter: weixin
weixin-adapter] Poll loop started for account ...
Bridge started with 2 adapter(s)
```

**这些日志出现意味着桥接通了！**

---

## 配置模板（config.env）

```ini
CTI_ENABLED_CHANNELS=qq,weixin
CTI_RUNTIME=claude
CTI_DEFAULT_MODE=plan
CTI_WEIXIN_MEDIA_ENABLED=true
CTI_AUTO_APPROVE=true

# QQ 部分
CTI_QQ_APP_ID=...
CTI_QQ_APP_SECRET=...
CTI_QQ_IMAGE_ENABLED=true
CTI_QQ_MAX_IMAGE_SIZE=20
```

---

## 💡 实战经验总结

### 1. Windows 环境首选 PowerShell
Git Bash 在当前机器不稳定（fork: retry），优先使用修复后的 PowerShell 脚本。

### 2. 配置字段必须准确
新旧字段名差异是最大陷阱（如 CTI_CHANNELS → CTI_ENABLED_CHANNELS）。

### 3. 微信账户 JSON 格式严格
- **必须是数组**，不是对象
- 必须 `enabled: true`
- 避免 UTF-8 BOM 问题

### 4. 权限提示是桥接正常行为
微信/QQ 通道无图形交互，权限请求会转为 `/perm allow ...` 文字消息，开启 `CTI_AUTO_APPROVE=true` 减少打扰。

### 5. 安全第一
微信 token 曾在终端/对话明文出现，**建议重新扫码登录一次**，用新 token 覆盖旧 token。

---

标签： #Skill #technology #bridge #运维 #微信 #QQ  
创建时间：2026-04-23  
来源：基于 [[技能/claude-to-im-bridge-notes.md]] 实战排障记录整理
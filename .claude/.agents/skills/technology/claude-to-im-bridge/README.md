# Claude-to-IM 桥接器技能

**微信/QQ 桥接配置、排障、运维指南**

## 概述

此技能提供 **Claude-to-IM（CTI）桥接器** 的完整配置、启动、排障与运维方案。内容包括 Windows 环境下的脚本修复、微信/QQ 通道配置、权限管理、故障诊断等。

## 核心内容

### 1. 修复脚本兼容性
- `supervisor-windows.ps1` 修复（Join-Path 写法、$pid 变量冲突、日志重定向）
- 无 BOM 编码写入避免 JSON 解析失败
- Windows PowerShell 优先，避免不稳定 Git Bash

### 2. 正确配置字段
- 新旧字段对照表（CTI_CHANNELS → CTI_ENABLED_CHANNELS 等）
- `weixin-accounts.json` 的正确数组格式（非对象格式）

### 3. 微信成功标志
- `Bridge started with 2 adapter(s)`
- `Started adapter: weixin`
- `weixin-adapter] Poll loop started for account ...`

### 4. 权限与安全问题
- `CTI_AUTO_APPROVE=true` 减少权限弹窗
- 微信 token 安全提醒（重新扫码覆盖、避免明文暴露）

## 使用方式

### 启动桥接
```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\.claude\skills\claude-to-im\scripts\supervisor-windows.ps1" start
```

### 查看状态
```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\.claude\skills\claude-to-im\scripts\supervisor-windows.ps1" status
```

### 查看日志
```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\.claude\skills\claude-to-im\scripts\supervisor-windows.ps1" logs 120
```

### 配置文件位置
- `C:\Users\fish\.claude-to-im\config.env`
- `C:\Users\fish\.claude-to-im\data\weixin-accounts.json`

## 故障诊断

### 无微信连接
1. 检查 `weixin-accounts.json` 是否为**数组格式**
2. 验证 token 是否有效（可重新扫码）
3. 检查 `CTI_ENABLED_CHANNELS` 是否包含 `weixin`

### 脚本错误
1. 优先使用修复后的 PowerShell 脚本
2. 确保无 UTF-8 BOM 编码问题
3. 避免 Git Bash 因 fork 错误不稳定

### 权限提示
- 微信/QQ 通道无图形交互，权限请求会转为文字消息
- 开启 `CTI_AUTO_APPROVE=true` 减少提示

## 更新记录

- **2026-04-23**：整理至统一技能仓库
- **2026-04-22**：桥接实战排障记录整理

## 后续改进

1. 固化修复过的 `supervisor-windows.ps1`
2. 提供纯 PowerShell 微信登录脚本（绕过 npm/tsx）
3. 制作 `weixin-accounts.json` 模板与验证工具
4. 编写详细运维手册

---

**注意**：此技能仅提供 **运维指导**，实际桥接功能由 `.claude/skills/claude-to-im/` 原生 skill 提供。
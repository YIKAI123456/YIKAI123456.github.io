---
layout: post
title: "踩坑实录：GOG CLI (Google Workspace 命令行工具) 安装全流程"
date: 2026-03-10 20:48:00 +0800
categories: [工具, 踩坑]
tags: [gogcli, google workspace, 命令行, 安装教程]
---

## 前言
最近发现了一个神器 [gogcli](https://github.com/steipete/gogcli)，可以在命令行直接操作谷歌全家桶：Gmail、日历、云盘、联系人、表格、文档全能搞定，不用开浏览器，效率直接拉满。但安装过程踩了一堆坑，整理出来给大家避坑。

## 什么是 GOG CLI？
GOG CLI 是一个开源的 Google Workspace 命令行工具，支持：
- 📧 Gmail 邮件搜索、发送、导出
- 📅 Calendar 日程查看、创建、管理
- ☁️ Drive 文件搜索、上传、下载
- 📇 Contacts 联系人管理
- 📊 Sheets 表格读写、追加、导出
- 📝 Docs 文档导出、内容查看

对我这种喜欢用终端的人来说简直是刚需。

## 安装流程
### 前提条件
需要 Go 1.25+ 版本，因为 gogcli 用了很多新特性，低版本编译不通过。

#### 步骤1：安装新版 Go
Ubuntu 源里的 Go 版本太老（1.18），直接装官方最新版：
```bash
cd /tmp
wget https://go.dev/dl/go1.26.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.26.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc
```
验证版本：
```bash
go version
# 输出 go version go1.26 linux/amd64 就对了
```

#### 步骤2：编译 gogcli
```bash
git clone https://github.com/steipete/gogcli.git
cd gogcli
make
```
编译出来的二进制文件在 `bin/gog`。

#### 步骤3：安装到系统路径
```bash
sudo install bin/gog /usr/local/bin/
```
验证安装：
```bash
gog --version
# 输出 v0.12.0-xxx 就成功了
```

## 踩过的坑
### 坑1：低版本 Go 编译报错
```
go: errors parsing go.mod:
/tmp/gogcli/go.mod:3: invalid go version '1.25.8': must match format 1.23
```
**原因**：Ubuntu 源里的 Go 1.18 不支持 go.mod 里写三位版本号（1.25.8）。
**解决**：手动安装 Go 1.25+ 版本，或者把 go.mod 里的 `go 1.25.8` 改成 `go 1.25` 也能凑合用。

### 坑2：GitHub Release 404
作者把旧版本的 Release 包都删了，想直接下载二进制的话会404，只能自己编译。

### 坑3：brew 安装权限不足
Linux 下 brew 默认要装到 `/home/linuxbrew/.linuxbrew`，没有 sudo 权限的话装不了，而且还要编译一堆依赖，特别慢，不如直接手动装 Go 编译快。

## 配置 OAuth 授权
安装完还需要配置谷歌 OAuth 才能用：
### 步骤1：创建谷歌云项目
1. 打开 https://console.cloud.google.com/ 新建项目
2. 启用需要的 API：Gmail API、Calendar API、Drive API、People API、Sheets API、Docs API
3. 创建 OAuth 客户端 ID，应用类型选「桌面应用」，下载 `client_secret.json`

### 步骤2：配置 gogcli
```bash
# 配置凭证路径
gog auth credentials /path/to/client_secret.json

# 添加账号
gog auth add 你的邮箱@gmail.com --services gmail,calendar,drive,contacts,sheets,docs
```

### 坑4：未验证应用警告
**原因**：自己创建的 OAuth 应用没有经过谷歌审核，会弹这个警告。
**解决**：
1. 点「高级」→「前往 [应用名]（不安全）」，直接授权即可，个人用完全没问题
2. 或者在 OAuth 同意屏幕页面把自己的邮箱加到「测试用户」列表里，就不会弹警告了

### 坑5：访问被拒绝（Access denied）
```
Error 403: access_denied, The developer hasn’t given you access to this app.
```
**原因**：谷歌现在要求未审核的应用必须把用户加到测试用户列表里才能用。
**解决**：在 OAuth 同意屏幕的「测试用户」里添加你的谷歌邮箱，保存后再授权就可以了。

## 使用示例
配置完就能爽用了：
```bash
# 查看最近7天的未读邮件
gog gmail search "is:unread newer_than:7d" --max 20

# 查看未来一周的日程
gog calendar events primary --from "$(date -I)" --to "$(date -I -d "+7 days")"

# 搜索云盘里的PDF报告
gog drive search "type:pdf name:报告" --max 10

# 读取表格数据
gog sheets get 表格ID "Sheet1!A1:D10" --json
```

## 总结
虽然安装过程有点折腾，但装好之后是真的香，现在处理邮件、查日程、导表格都不用开浏览器了，命令行里直接搞定，效率提升N倍。推荐所有谷歌全家桶用户都试试~

有问题欢迎在评论区交流！

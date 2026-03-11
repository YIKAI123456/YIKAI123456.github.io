#!/bin/bash

# Hexo博客一键发布脚本
# 使用方法: ./publish.sh "提交信息"

set -e

# 检查是否提供了提交信息
if [ $# -eq 0 ]; then
    echo "请提供提交信息，例如: ./publish.sh \"新增文章: xxx\""
    exit 1
fi

COMMIT_MSG="$1"

echo "=== 开始发布博客 ==="

# 清理旧的生成文件
echo "1. 清理缓存..."
hexo clean

# 生成静态文件
echo "2. 生成静态文件..."
hexo generate

# 复制静态文件到根目录
echo "3. 同步静态文件到根目录..."
rm -rf css/ js/ images/ 2026/ about/ archives/ categories/ tags/ index.html avatar.jpg
cp -r public/* .

# 提交到Git
echo "4. 提交到Git仓库..."
git add .
git commit -m "$COMMIT_MSG"

# 推送到远程
echo "5. 推送到远程仓库..."
git push origin gh-pages

echo "=== 发布完成! ==="
echo "请稍等1-2分钟，访问 https://yikai123456.github.io 查看效果"

#!/bin/bash
# iOS归档脚本 - 用法: ./release.sh <版本号> <提交描述>
# 示例: ./release.sh v2.0.70 "修复聊天消息滚动"
#
# 流程: 更新版本号 → commit → 打tag → 合并master → 推送GitHub → 触发编译 → 下载IPA归档

set -e

# 参数检查
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "用法: ./release.sh <版本号> <提交描述>"
    echo "示例: ./release.sh v2.0.70 修复聊天消息滚动"
    exit 1
fi

VERSION=$1
MSG=$2
# 从版本号提取数字部分(去掉v前缀)
VER_NUM="${VERSION#v}"

echo "===== iOS归档开始 ====="
echo "版本: $VERSION"
echo "分支: $(git branch --show-current)"
echo ""

# 1. 检查工作区是否干净
if [ -n "$(git status --porcelain)" ]; then
    echo "📝 检测到未提交的改动，自动commit..."
    git add -A
    git commit -m "$VERSION: $MSG"
    echo "✅ commit完成"
fi

# 2. 更新project.yml中的版本号
echo "📝 更新project.yml版本号..."
sed -i "s/MARKETING_VERSION: \".*\"/MARKETING_VERSION: \"$VER_NUM\"/" project.yml
sed -i "s/CURRENT_PROJECT_VERSION: \".*\"/CURRENT_PROJECT_VERSION: \"${VER_NUM##*.}\"/" project.yml
sed -i "s/CFBundleShortVersionString: \".*\"/CFBundleShortVersionString: \"$VER_NUM\"/" project.yml
sed -i "s/CFBundleVersion: \".*\"/CFBundleVersion: \"${VER_NUM##*.}\"/" project.yml

git add project.yml
git commit -m "$VERSION: bump version in project.yml" --allow-empty 2>/dev/null || echo "(无变更跳过)"

# 3. 打tag
if git tag -l "$VERSION" | grep -q .; then
    echo "❌ tag $VERSION 已存在，请检查版本号"
    exit 1
fi
git tag "$VERSION" -m "$VERSION: $MSG"
echo "✅ tag $VERSION 已创建"

# 4. 推送tag到GitHub
echo "📤 推送tag到GitHub..."
git push origin "$VERSION"
echo "✅ tag已推送，GitHub Actions将自动触发编译"

# 5. 推送代码
git push origin main
echo "✅ 代码已推送"

echo ""
echo "===== iOS归档完成 ====="
echo "版本 $VERSION 已归档并推送"
echo ""
echo "下一步："
echo "  1. 等待GitHub Actions编译完成（约3-5分钟）"
echo "  2. 运行 ./download-release.sh $VERSION 下载IPA归档"
echo "  3. 或用签名工具重签名后安装到iPhone测试"

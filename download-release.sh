#!/bin/bash
# iOS编译产物下载脚本 - 用法: ./download-release.sh <版本号>
# 示例: ./download-release.sh v2.0.70
#
# 从GitHub Actions下载编译好的IPA，保存到releases目录

set -e

if [ -z "$1" ]; then
    echo "用法: ./download-release.sh <版本号>"
    echo "示例: ./download-release.sh v2.0.70"
    exit 1
fi

VERSION=$1
VER_NUM="${VERSION#v}"
GITHUB_TOKEN="${GITHUB_TOKEN}"
REPO="baichuangbaijia/chuangpu-ai-ios"
RELEASES_DIR="/data/chuangpu-ai-ios/releases"

echo "===== iOS下载归档开始 ====="
echo "版本: $VERSION"
echo ""

# 1. 检查本地是否已有该版本IPA
if [ -f "$RELEASES_DIR/ChuangpuAI_${VERSION}.ipa" ]; then
    echo "⚠️  本地已有 $VERSION 的IPA，跳过下载"
    ls -la "$RELEASES_DIR/ChuangpuAI_${VERSION}.ipa"
    exit 0
fi

# 2. 查找GitHub Actions中对应tag的workflow run
echo "🔍 查找GitHub Actions编译任务..."
RUNS=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/$REPO/actions/runs?event=push&per_page=10" 2>/dev/null)

# 查找包含该tag的run
RUN_ID=$(echo "$RUNS" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for run in data.get(\"workflow_runs\", []):
    if run.get(\"head_branch\") == \"$VERSION\":
        print(run[\"id\"])
        break
" 2>/dev/null)

if [ -z "$RUN_ID" ]; then
    echo "❌ 未找到版本 $VERSION 的编译任务"
    echo "可能还没编译完成，请稍后重试"
    echo ""
    echo "查看编译状态:"
    echo "  https://github.com/$REPO/actions"
    exit 1
fi

echo "✅ 找到编译任务 ID: $RUN_ID"

# 3. 检查编译状态
STATUS=$(echo "$RUNS" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for run in data.get(\"workflow_runs\", []):
    if str(run[\"id\"]) == \"$RUN_ID\":
        print(run[\"status\"] + \"|\" + run[\"conclusion\"])
        break
" 2>/dev/null)

echo "编译状态: $STATUS"
if echo "$STATUS" | grep -q "completed|success"; then
    echo "✅ 编译成功"
elif echo "$STATUS" | grep -q "in_progress\|queued"; then
    echo "⏳ 编译中，请稍后再试"
    exit 1
else
    echo "❌ 编译失败"
    exit 1
fi

# 4. 下载artifact
echo "📥 下载编译产物..."
ARTIFACTS=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/$REPO/actions/runs/$RUN_ID/artifacts" 2>/dev/null)

ARTIFACT_ID=$(echo "$ARTIFACTS" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for a in data.get(\"artifacts\", []):
    print(a[\"id\"])
    break
" 2>/dev/null)

if [ -z "$ARTIFACT_ID" ]; then
    echo "❌ 未找到编译产物"
    exit 1
fi

# 下载并解压
TMP_DIR=$(mktemp -d)
curl -s -L -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/$REPO/actions/artifacts/$ARTIFACT_ID/zip" \
    -o "$TMP_DIR/artifact.zip"

echo "📦 解压IPA..."
cd "$TMP_DIR"
unzip -q artifact.zip

# 查找IPA文件
IPA_FILE=$(find . -name "*.ipa" | head -1)
if [ -z "$IPA_FILE" ]; then
    echo "❌ 压缩包中未找到IPA文件"
    ls -la
    rm -rf "$TMP_DIR"
    exit 1
fi

# 5. 归档
mkdir -p "$RELEASES_DIR"
cp "$IPA_FILE" "$RELEASES_DIR/ChuangpuAI_${VERSION}.ipa"
echo "✅ 已归档: $RELEASES_DIR/ChuangpuAI_${VERSION}.ipa"
ls -la "$RELEASES_DIR/ChuangpuAI_${VERSION}.ipa"

# 清理临时文件
rm -rf "$TMP_DIR"

echo ""
echo "===== iOS下载归档完成 ====="
echo ""
echo "所有归档版本:"
ls -lh "$RELEASES_DIR/"*.ipa 2>/dev/null

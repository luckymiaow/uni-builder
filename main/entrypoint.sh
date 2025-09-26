#!/bin/bash
set -e

# 默认项目目录
PROJECT_DIR=/opt/project

# 如果用户指定了目录，就用挂载目录；否则使用 /workspace（默认工作目录）
WORK_DIR=${WORK_DIR:-/workspace}

# DEBUG 参数，可通过环境变量控制
DEBUG=${DEBUG:-false}


# 如果挂载目录下有 gradlew，就直接用外部项目打包
if [ -x "$WORK_DIR/gradlew" ]; then
  echo "📁 检测到外部项目，使用挂载项目进行打包..."
  PROJECT_DIR=$WORK_DIR
else
  echo "📁 使用内置默认项目..."
  CONFIG_FILE="$WORK_DIR/config.json"
  # 调用 apply-config.sh，传入工作目录和项目目录
  if [ -f "$CONFIG_FILE" ]; then
    echo "🔧 检测到配置文件：$CONFIG_FILE"
    /apply-config.sh "$WORK_DIR" "$PROJECT_DIR"
  else
    echo "ℹ️ 未检测到配置文件，跳过配置注入。"
  fi
fi

# 开始打包前先导出项目内容
if [ "$DEBUG" = "true" ]; then
  OUTPUT_DIR=${OUTPUT_DIR:-$WORK_DIR/output}
  mkdir -p $OUTPUT_DIR
  echo "📦 导出项目目录用于调试: $PROJECT_DIR -> $OUTPUT_DIR/project"
  rm -rf "$OUTPUT_DIR/project"
  cp -r "$PROJECT_DIR" "$OUTPUT_DIR/project"
fi

# 开始打包
cd $PROJECT_DIR
chmod +x ./gradlew || true
echo "⚙️ 开始构建 Release APK..."
./gradlew assembleRelease --no-daemon --stacktrace

# 导出 APK
OUTPUT_DIR=${OUTPUT_DIR:-$WORK_DIR/output}
mkdir -p $OUTPUT_DIR
find $PROJECT_DIR -type f -path "*/build/outputs/apk/release/*.apk" -exec cp {} $OUTPUT_DIR/ \;

echo "✅ APK 已导出到: $OUTPUT_DIR"
ls -lh $OUTPUT_DIR

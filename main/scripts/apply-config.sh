#!/bin/bash
set -e

WORK_DIR="$1"
PROJECT_DIR="$2"
CONFIG_FILE="$WORK_DIR/config.json"
OVERRIDE_DIR="$WORK_DIR/override"

GRADLE_FILE="$PROJECT_DIR/simpleDemo/build.gradle"
MANIFEST_FILE="$PROJECT_DIR/simpleDemo/src/main/AndroidManifest.xml"
STRINGS_FILE="$PROJECT_DIR/simpleDemo/src/main/res/values/strings.xml"
DCLOUD_CONTROL_FILE="$PROJECT_DIR/simpleDemo/src/main/assets/data/dcloud_control.xml"


# ---------------------
# 1️⃣ 应用 override 覆盖文件
# ---------------------
if [ -d "$OVERRIDE_DIR" ]; then
    echo "🔄 应用 override 覆盖文件..."
    echo "🔹 从 $OVERRIDE_DIR 覆盖到 $PROJECT_DIR"

    for f in "$OVERRIDE_DIR"/* "$OVERRIDE_DIR"/.*; do
        [ -e "$f" ] || continue
        filename=$(basename "$f")

        # 跳过 . 和 ..
        if [ "$filename" = "." ] || [ "$filename" = ".." ]; then
            continue
        fi

        src="$f"
        dest="$PROJECT_DIR/$filename"

        if [ -d "$src" ]; then
            # 合并目录内容
            mkdir -p "$dest"
            cp -r "$src/"* "$dest/" 2>/dev/null || true
        else
            # 文件直接覆盖
            cp -r "$src" "$dest"
        fi
    done

    echo "🔹 覆盖完成"
fi


# ---------------------
# 统一文件为 LF
# ---------------------
for f in "$GRADLE_FILE" "$MANIFEST_FILE" "$STRINGS_FILE" "$DCLOUD_CONTROL_FILE"; do
    [ -f "$f" ] && dos2unix "$f" >/dev/null 2>&1
done

# ---------------------
# 占位符与 JSON 路径映射（全大写常量命名）
# ---------------------
declare -A FIELDS=(
    ["@APP_NAME@"]='.appName'
    ["@PACKAGE_NAME@"]='.packageName'
    ["@VERSION_NAME@"]='.versionName'
    ["@VERSION_CODE@"]='.versionCode'
    ["@COMPILE_SDK_VERSION@"]='.compileSdkVersion'
    ["@BUILD_TOOLS_VERSION@"]='.buildToolsVersion'
    ["@MIN_SDK_VERSION@"]='.minSdkVersion'
    ["@TARGET_SDK_VERSION@"]='.targetSdkVersion'
    ["@MULTI_DEX_ENABLED@"]='.multiDexEnabled'
    ["@SOURCE_COMPATIBILITY@"]='.sourceCompatibility'
    ["@TARGET_COMPATIBILITY@"]='.targetCompatibility'
    ["@SIGNING_KEY_ALIAS@"]='.signingConfig.keyAlias'
    ["@SIGNING_KEY_PASSWORD@"]='.signingConfig.keyPassword'
    ["@SIGNING_STORE_FILE@"]='.signingConfig.storeFile'
    ["@SIGNING_STORE_PASSWORD@"]='.signingConfig.storePassword'
    ["@SIGNING_V1_ENABLED@"]='.signingConfig.v1SigningEnabled'
    ["@SIGNING_V2_ENABLED@"]='.signingConfig.v2SigningEnabled'
    ["@DCLOUD_APPID@"]='.dcloudControl.appid'
    ["@DCLOUD_APPVER@"]='.dcloudControl.appver'
)

# ---------------------
# 占位符替换函数
# ---------------------
replace_placeholder() {
    local file="$1"
    local placeholder="$2"
    local value="$3"
    sed -i "s|$placeholder|$value|g" "$file"
}

# ---------------------
# 执行占位符替换
# ---------------------
for placeholder in "${!FIELDS[@]}"; do
    json_path="${FIELDS[$placeholder]}"
    value=$(jq -r "${json_path} // empty" "$CONFIG_FILE")
    replace_placeholder "$GRADLE_FILE" "$placeholder" "$value"
    replace_placeholder "$MANIFEST_FILE" "$placeholder" "$value"
    replace_placeholder "$STRINGS_FILE" "$placeholder" "$value"
    replace_placeholder "$DCLOUD_CONTROL_FILE" "$placeholder" "$value"
done

# ---------------------
# 处理 meta-data 数组
# ---------------------
META_DATA=$(jq -c '.metaData // []' "$CONFIG_FILE")
META_TAGS=""
for row in $(echo "$META_DATA" | jq -c '.[]'); do
    NAME=$(echo "$row" | jq -r '.name')
    VALUE=$(echo "$row" | jq -r '.value')
    META_TAGS="$META_TAGS        <meta-data android:name=\"$NAME\" android:value=\"$VALUE\" />\n"
done

if [ -n "$META_TAGS" ]; then
    echo "🔹 替换 @META_DATA@"
    sed -i "s|@META_DATA@|$META_TAGS|" "$MANIFEST_FILE"
else
    echo "ℹ️ meta-data 数组为空，@META_DATA@ 保留不变"
fi

echo "✅ 占位符替换完成"

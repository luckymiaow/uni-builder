# UniApp Android 构建工具

UniApp Android 项目的 Docker 构建工具，支持通过配置文件和资源覆盖来自定义打包内置默认项目，或直接打包外部项目。

## 安装要求

- Docker 18.03 或更高版本
- 至少 4GB 可用磁盘空间
- 推荐 8GB 以上内存


## 快速开始

### 方式一：使用预构建镜像（推荐）

直接使用 Docker Hub 上的预构建镜像，无需克隆项目：

```bash
docker pull your-dockerhub-username/uni-builder:latest
```

### 方式二：本地构建镜像

如需自定义或开发，可以克隆项目并构建：

```bash
# 1. 克隆项目
git clone https://github.com/your-username/uniapp-android.git
cd uniapp-android

# 2. 构建镜像
cd ./main
docker build -t uni-builder .

# 3. 使用本地镜像
docker run --rm -v your-project:/workspace uni-builder
```

---

## 使用方式

### 方式一：配置文件 + 资源覆盖

本地目录结构：
```
my-build/
├── config.json                      # 配置文件
├── override/                        # 资源覆盖
│   └── simpleDemo/
│       ├── test.jks                 # 签名文件
│       └── src/main/
│           ├── res/drawable/icon.png
│           └── assets/apps/         # UniApp 前端代码
└── output/                          # 构建输出（自动创建）
```

运行命令：
```bash
cd my-build
# 使用预构建镜像
docker run --rm -v ${PWD}:/workspace your-dockerhub-username/uni-builder:latest

# 或使用本地构建的镜像
docker run --rm -v ${PWD}:/workspace uni-builder

# 调试模式
docker run --rm -e DEBUG=true -v ${PWD}:/workspace your-dockerhub-username/uni-builder:latest

调试模式会在 `output/project/` 目录导出完整的项目文件，便于检查配置是否正确应用。
```

### 方式二：外部项目直接打包

```bash
# 打包现有的 Android 项目（使用预构建镜像）
docker run --rm -v /path/to/your-android-project:/workspace your-dockerhub-username/uni-builder:latest
```


---

## 项目结构

```
uniapp-android/
├── README.md                          # 项目说明文档
├── main/                              # Docker 构建环境
│   ├── Dockerfile                     # Docker 镜像定义
│   ├── entrypoint.sh                  # 容器入口脚本
│   ├── android-sdk/                   # Android SDK 离线包
│   │   ├── cmdline-tools.zip          # Android 命令行工具
│   │   └── gradle-7.3-bin.zip         # Gradle 构建工具
│   ├── default-project/               # 内置默认 UniApp 项目
│   │   ├── build.gradle               # 根级构建配置
│   │   ├── settings.gradle            # 项目设置
│   │   ├── gradlew                    # Gradle 包装器
│   │   ├── simpleDemo/                # 应用模块
│   │   │   ├── build.gradle           # 应用构建配置（支持占位符）
│   │   │   ├── src/main/
│   │   │   │   ├── AndroidManifest.xml  # 应用清单（支持占位符）
│   │   │   │   ├── res/values/strings.xml  # 字符串资源
│   │   │   │   └── assets/             # UniApp 资源文件
│   │   │   └── libs/                  # UniApp 核心 AAR 库
│   │   └── gradle/wrapper/            # Gradle 包装器文件
│   └── scripts/
│       └── apply-config.sh            # 配置应用脚本
└── test/                              # 测试配置示例
    ├── config.json                    # 配置文件示例
    └── override/simpleDemo/           # 资源覆盖示例
```

---

## 构建流程

1. **检测项目类型**
   - 如果工作目录存在 `gradlew`，使用外部项目
   - 否则使用内置默认项目

2. **应用配置**（仅内置项目）
   - 读取 `config.json` 配置文件
   - 应用 `override/` 目录覆盖
   - 替换占位符变量

3. **执行构建**
   - 运行 `./gradlew assembleRelease`
   - 导出 APK 到 `output/` 目录

4. **输出结果**
   - APK 文件：`output/*.apk`
   - 调试文件：`output/project/`（DEBUG=true 时）

---

## 配置说明

### config.json 配置文件

挂载到容器 `/workspace/config.json`，支持以下配置：

#### 基础配置
| 字段名 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| `appName` | string | 应用名称 | `"我的应用"` |
| `packageName` | string | Android 包名 | `"com.example.myapp"` |
| `versionName` | string | 版本名称 | `"1.0.0"` |
| `versionCode` | integer | 版本号 | `100` |

#### SDK 配置
| 字段名 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| `compileSdkVersion` | integer | 编译 SDK 版本 | `33` |
| `buildToolsVersion` | string | 构建工具版本 | `"33.0.2"` |
| `minSdkVersion` | integer | 最小 SDK 版本 | `21` |
| `targetSdkVersion` | integer | 目标 SDK 版本 | `33` |

#### 编译配置
| 字段名 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| `multiDexEnabled` | boolean | 多 Dex 支持 | `true` |
| `sourceCompatibility` | string | Java 源码兼容性 | `"1_8"` |
| `targetCompatibility` | string | Java 目标兼容性 | `"1_8"` |

#### 签名配置
```json
{
  "signingConfig": {
    "keyAlias": "release_key",
    "keyPassword": "key_password",
    "storeFile": "release.jks",
    "storePassword": "store_password",
    "v1SigningEnabled": true,
    "v2SigningEnabled": true
  }
}
```

#### DCloud 配置
```json
{
  "dcloudControl": {
    "appid": "__UNI__1234567",
    "appver": "1.0.0"
  }
}
```

#### 元数据配置
```json
{
  "metaData": [
    {
      "name": "dcloud_appkey",
      "value": "your_app_key"
    }
  ]
}
```

### 完整配置示例

```json
{
  "appName": "我的UniApp应用",
  "packageName": "com.example.myuniapp",
  "compileSdkVersion": 33,
  "buildToolsVersion": "33.0.2",
  "versionCode": 100,
  "versionName": "1.0.0",
  "minSdkVersion": 21,
  "targetSdkVersion": 33,
  "multiDexEnabled": true,
  "sourceCompatibility": "1_8",
  "targetCompatibility": "1_8",
  "signingConfig": {
    "keyAlias": "release_key",
    "keyPassword": "password123",
    "storeFile": "release.jks",
    "storePassword": "storepass123",
    "v1SigningEnabled": true,
    "v2SigningEnabled": true
  },
  "dcloudControl": {
    "appid": "__UNI__1234567",
    "appver": "1.0.0"
  },
  "metaData": [
    {
      "name": "dcloud_appkey",
      "value": "your_dcloud_key_here"
    }
  ]
}
```

---

## 资源覆盖 (override)

通过 `override/` 目录可以覆盖默认项目的任意文件。

### 目录结构要求
覆盖目录结构必须与默认项目保持一致：

```
override/
└── simpleDemo/                        # 对应 default-project/simpleDemo/
    ├── src/main/
    │   ├── AndroidManifest.xml        # 覆盖应用清单
    │   ├── res/
    │   │   ├── drawable/icon.png      # 覆盖应用图标
    │   │   ├── values/
    │   │   │   ├── strings.xml        # 覆盖字符串资源
    │   │   │   └── colors.xml         # 添加颜色资源
    │   └── assets/                    # 覆盖 UniApp 资源
    └── libs/                          # 覆盖或添加 AAR 库
```

### 常用覆盖文件
| 文件路径 | 说明 |
|----------|------|
| `simpleDemo/src/main/res/drawable/icon.png` | 应用图标 |
| `simpleDemo/src/main/res/values/strings.xml` | 字符串资源 |
| `simpleDemo/src/main/res/values/colors.xml` | 颜色主题 |
| `simpleDemo/src/main/AndroidManifest.xml` | 应用清单文件 |
| `simpleDemo/src/main/assets/apps/` | UniApp 前端资源 |
| `simpleDemo/libs/` | 第三方 AAR 库 |
| `simpleDemo/test.jks` | 签名证书文件 |

---

## 环境变量

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `DEBUG` | `false` | 是否启用调试模式 |
| `OUTPUT_DIR` | `/workspace/output` | 输出目录路径 |
| `WORK_DIR` | `/workspace` | 工作目录路径 |

---

## 注意事项

1. **配置文件格式**：`config.json` 必须是合法的 JSON 格式
2. **目录结构**：`override/` 目录结构必须与默认项目保持一致
3. **项目优先级**：外部项目优先，挂载外部项目时不会应用 `config.json` 和 `override/`
4. **签名文件**：如果使用自定义签名，需将 `.jks` 文件放在 `override/simpleDemo/` 目录
5. **权限问题**：确保挂载的文件和目录有正确的读写权限
6. **路径格式**：Windows 用户注意使用正确的路径格式和卷挂载语法
7. **镜像更新**：建议定期更新镜像以获取最新功能和安全修复：`docker pull your-dockerhub-username/uni-builder:latest`
8. **网络要求**：首次使用预构建镜像时需要网络连接下载，后续可离线使用
9. **镜像标签**：生产环境建议使用具体版本标签而非 `latest` 以确保构建一致性

## 故障排除

### 常见问题

**Q: 镜像拉取失败？**  
A: 检查网络连接和 Docker Hub 访问权限，或尝试使用镜像加速器。

**Q: 构建时内存不足？**  
A: 增加 Docker 内存限制，建议设置为 8GB 或以上。

**Q: Windows 路径挂载问题？**  
A: 使用 `${PWD}` 替代相对路径，或使用绝对路径格式。

**Q: 想使用特定版本？**  
A: 替换 `latest` 标签为具体版本号，如 `your-dockerhub-username/uni-builder:v1.0.0`

---

## 更新日志

### v1.0.0
- 初始版本发布
- 支持 UniApp Android 项目构建
- 支持配置文件和资源覆盖
- 支持外部项目直接打包

---

## 贡献

欢迎提交 Issues 和 Pull Requests！

### 开发环境
```bash
git clone https://github.com/your-username/uniapp-android.git
cd uniapp-android
```

### 提交流程
1. Fork 项目
2. 创建功能分支
3. 提交更改
4. 发起 Pull Request

---

## 支持

- 📖 [项目文档](https://github.com/your-username/uniapp-android)
- 🐛 [问题反馈](https://github.com/your-username/uniapp-android/issues)
- 💬 [讨论区](https://github.com/your-username/uniapp-android/discussions)
- 📧 联系邮箱：your-email@example.com

---

## 许可证

本项目采用 MIT 许可证，详见 [LICENSE](LICENSE) 文件。

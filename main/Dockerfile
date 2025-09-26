FROM openjdk:11-jdk-slim

# 先更新系统并安装基础工具
RUN apt-get update && apt-get install -y unzip jq curl dos2unix && rm -rf /var/lib/apt/lists/*

ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools

# 在线下载并安装 Android SDK cmdline-tools
RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools && \
    curl -o /tmp/commandlinetools-linux.zip https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip && \
    unzip /tmp/commandlinetools-linux.zip -d /tmp/ && \
    mv /tmp/cmdline-tools $ANDROID_SDK_ROOT/cmdline-tools/latest && \
    chmod +x $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/* && \
    rm /tmp/commandlinetools-linux.zip

# 安装 SDK 组件
RUN yes | sdkmanager --licenses && \
    sdkmanager "platform-tools" \
               "platforms;android-33" \
               "build-tools;33.0.2"

# 使用项目自带的 Gradle Wrapper，无需单独安装 Gradle

# 复制默认项目
COPY default-project /opt/project

# 复制脚本并转换换行符 + 可执行
COPY entrypoint.sh /entrypoint.sh
COPY scripts/apply-config.sh /apply-config.sh
RUN dos2unix /entrypoint.sh /apply-config.sh /opt/project/gradlew && \
    chmod +x /entrypoint.sh /apply-config.sh /opt/project/gradlew

WORKDIR /workspace
ENTRYPOINT ["/entrypoint.sh"]

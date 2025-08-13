FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 切换到阿里云 apt 源，加速安装（可选）
RUN sed -i 's@archive.ubuntu.com@mirrors.aliyun.com@g' /etc/apt/sources.list && \
    sed -i 's@security.ubuntu.com@mirrors.aliyun.com@g' /etc/apt/sources.list && \
    apt-get clean && apt-get update && apt-get upgrade -y

# 设置中文语言环境和时区
RUN apt-get install -y locales tzdata && \
    locale-gen zh_CN.UTF-8 && \
    update-locale LANG=zh_CN.UTF-8 && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

ENV LANG=zh_CN.UTF-8 \
    LC_ALL=zh_CN.UTF-8 \
    TZ=Asia/Shanghai

# 安装常用工具及 tesseract OCR 和语言包（中文简体、繁体、英文），以及 leptonica 依赖
RUN apt-get install -y --no-install-recommends \
    iputils-ping curl net-tools busybox unzip wget \
    tesseract-ocr tesseract-ocr-chi-sim tesseract-ocr-chi-tra tesseract-ocr-eng \
    libleptonica-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 安装 JDK 17 （从你提供的 tar.gz）
RUN curl -SL "https://github.com/gezhiwei8899/java17-tini/releases/download/17/jdk-17.0.12_linux-x64_bin.tar.gz" -o /tmp/jdk.tar.gz && \
    mkdir -p /usr/lib/jvm && \
    tar -xf /tmp/jdk.tar.gz -C /usr/lib/jvm && \
    rm /tmp/jdk.tar.gz

ENV JAVA_HOME=/usr/lib/jvm/jdk-17.0.12
ENV PATH=$PATH:$JAVA_HOME/bin

# 复制 tini 二进制，授权执行
ADD ./tini /tini
RUN chmod +x /tini

ENTRYPOINT ["/tini", "--"]

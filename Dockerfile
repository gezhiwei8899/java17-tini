# ============================
# 1. 构建阶段
# ============================
FROM centos:centos7 AS builder

# 切换到阿里云 YUM 源，加速安装
RUN curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo \
    && curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo \
    && yum clean all && yum makecache \
    && yum update -y \
    && yum install -y wget tar unzip git

# 安装 Maven
RUN wget https://downloads.apache.org/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz \
    && tar -xf apache-maven-3.9.9-bin.tar.gz \
    && mv apache-maven-3.9.9 /usr/local/maven \
    && rm apache-maven-3.9.9-bin.tar.gz

ENV MAVEN_HOME=/usr/local/maven
ENV PATH=$PATH:$MAVEN_HOME/bin

# 安装 JDK 17（构建用）
RUN curl -SL "https://github.com/gezhiwei8899/java17-tini/releases/download/17/jdk-17.0.12_linux-x64_bin.tar.gz" \
    -o /tmp/jdk.tar.gz \
    && mkdir -p /usr/lib/jvm \
    && tar -xf /tmp/jdk.tar.gz -C /usr/lib/jvm \
    && rm /tmp/jdk.tar.gz
ENV JAVA_HOME=/usr/lib/jvm/jdk-17.0.12
ENV PATH=$PATH:$JAVA_HOME/bin

# 将项目源码复制到构建容器
WORKDIR /build
COPY . .

# 构建 fat-jar（包含 Tess4J 依赖）
RUN mvn -B clean package -DskipTests

# ============================
# 2. 运行阶段
# ============================
FROM centos:centos7

# 基础环境（中文支持 + 常用工具）
RUN curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo \
    && curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo \
    && yum clean all && yum makecache \
    && yum update -y \
    && yum -y install kde-l10n-Chinese glibc-common tzdata \
    && localedef -c -f UTF-8 -i zh_CN zh_CN.UTF-8 \
    && echo 'LANG="zh_CN.UTF-8"' > /etc/locale.conf \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone

ENV LANG=zh_CN.UTF-8 \
    LC_ALL=zh_CN.UTF-8

# 安装 JDK 17（运行用）
RUN curl -SL "https://github.com/gezhiwei8899/java17-tini/releases/download/17/jdk-17.0.12_linux-x64_bin.tar.gz" \
    -o /tmp/jdk.tar.gz \
    && mkdir -p /usr/lib/jvm \
    && tar -xf /tmp/jdk.tar.gz -C /usr/lib/jvm \
    && rm /tmp/jdk.tar.gz
ENV JAVA_HOME=/usr/lib/jvm/jdk-17.0.12
ENV PATH=$PATH:$JAVA_HOME/bin

# 安装 Tesseract OCR 和语言包
RUN yum install -y tesseract tesseract-langpack-chi_sim tesseract-langpack-chi_tra tesseract-langpack-eng \
    && yum clean all

# tini 作为容器入口
ADD ./tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

# 从构建阶段复制 fat-jar
WORKDIR /app
COPY --from=builder /build/target/*.jar app.jar

# 启动应用
CMD ["java", "-jar", "app.jar"]

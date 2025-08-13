FROM centos:centos7

# 切换到阿里云 YUM 源，加速安装
RUN curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo \
    && curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo \
    && yum clean all && yum makecache \
    && yum update -y

# 中文语言环境
RUN yum -y install kde-l10n-Chinese glibc-common tzdata \
    && localedef -c -f UTF-8 -i zh_CN zh_CN.UTF-8 \
    && echo 'LANG="zh_CN.UTF-8"' > /etc/locale.conf \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone
ENV LANG=zh_CN.UTF-8 \
    LC_ALL=zh_CN.UTF-8

# 安装常用工具 安装 Tesseract OCR 和语言包（中文简体、繁体、英文）
RUN yum install -y iputils curl net-tools busybox unzip wget epel-release tesseract tesseract-langpack-chi_sim tesseract-langpack-chi_tra tesseract-langpack-eng leptonica leptonica-devel \
    && yum clean all

# 安装 JDK 17
RUN curl -SL "https://github.com/gezhiwei8899/java17-tini/releases/download/17/jdk-17.0.12_linux-x64_bin.tar.gz" \
    -o /tmp/jdk.tar.gz \
    && mkdir -p /usr/lib/jvm \
    && tar -xf /tmp/jdk.tar.gz -C /usr/lib/jvm \
    && rm /tmp/jdk.tar.gz
ENV JAVA_HOME=/usr/lib/jvm/jdk-17.0.12
ENV PATH=$PATH:$JAVA_HOME/bin

# tini 作为容器入口
ADD ./tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

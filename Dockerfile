FROM centos:centos7

# 将JDK压缩包复制到镜像中
RUN curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo && curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo \ 
        && yum clean all && yum makecache \
        && yum update -y && yum -y install kde-l10n-Chinese \
        && yum -y reinstall glibc-common \
        && localedef -c -f UTF-8 -i zh_CN zh_CN.UTF-8 \
        && echo 'LANG="zh_CN.UTF-8"' > /etc/locale.conf \
        && source /etc/locale.conf \
        && yum clean all && \
    curl -SL "https://github.com/gezhiwei8899/java8-tini/releases/download/24.0.1/jdk-8u411-linux-x64.tar.gz" -o /tmp/jdk-8u411-linux-x64.tar.gz && \
    mkdir -p /usr/lib/jvm && \
    tar -xf /tmp/jdk-8u411-linux-x64.tar.gz -C /usr/lib/jvm && \
    rm /tmp/jdk-8u411-linux-x64.tar.gz && \
    yum install -y iputils curl net-tools busybox tzdata && \
    rm -rf /var/cache/yum/* && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone

ENV LANG=zh_CN.UTF-8 \
    LC_ALL=zh_CN.UTF-8
# 设置环境变量
ENV JAVA_HOME=/usr/lib/jvm/jdk1.8.0_411
ENV PATH=$PATH:$JAVA_HOME/bin

# 安装tini，并设置为容器的入口点
ADD ./tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

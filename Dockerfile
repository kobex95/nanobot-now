# 第一阶段：构建
FROM rust:1.85-alpine AS builder

# 安装构建依赖
RUN apk add --no-cache \
    musl-dev \
    openssl-dev \
    pkgconfig \
    && rm -rf /var/cache/apk/*

WORKDIR /build

# 复制依赖文件，利用缓存
COPY Cargo.toml ./
COPY Cargo.lock ./
COPY vendor ./vendor

# 复制源代码
COPY src ./src
COPY skills ./skills

# 构建 release 版本
RUN cargo build --release --all-features

# 第二阶段：运行环境
FROM alpine:latest

# 安装运行时依赖
RUN apk add --no-cache \
    ca-certificates \
    libssl3 \
    && update-ca-certificates \
    && rm -rf /var/cache/apk/*

# 创建非 root 用户
RUN adduser -D -u 1000 -s /bin/sh nanobot

WORKDIR /app

# 从构建阶段复制二进制文件
COPY --from=builder /build/target/release/nanobot /usr/local/bin/nanobot

# 创建配置和存储目录
RUN mkdir -p /home/nanobot/.nanobot && \
    mkdir -p /data && \
    chown -R nanobot:nanobot /home/nanobot /data

USER nanobot

# 暴露 WebUI 端口
EXPOSE 18890

# 默认运行网关模式
CMD ["nanobot", "gateway"]

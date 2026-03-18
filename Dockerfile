# 第一阶段：构建
FROM rust:1.89-slim AS builder

# 安装构建依赖
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    zlib1g-dev \
    libsqlite3-dev \
    libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# 复制依赖文件，利用缓存
COPY Cargo.toml ./
COPY Cargo.lock ./
COPY vendor ./vendor

# 复制源代码
COPY src ./src
COPY skills ./skills

# 构建 release 版本
RUN cargo build --release

# 第二阶段：运行环境
FROM debian:bookworm-slim

# 安装运行时依赖
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    zlib1g \
    libsqlite3-0 \
    libcurl4 \
    && rm -rf /var/lib/apt/lists/*

# 创建非 root 用户
RUN useradd -m -u 1000 -s /bin/bash nanobot

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

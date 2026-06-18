#!/bin/bash

echo "正在检测内核源码目录..."
KERNEL_SRC_DIR=""
for d in */ ; do
    dir_name="${d%/}"
    if [[ "$dir_name" =~ ^(kernel|temp_modules|vendor|device|.*\.git)$ ]]; then continue; fi
    if [ -f "$dir_name/Makefile" ] && [ -d "$dir_name/arch" ]; then
        KERNEL_SRC_DIR="$dir_name"
        break
    fi
done

if [ -z "$KERNEL_SRC_DIR" ]; then
    echo "错误：未找到内核源码目录！"
    exit 1
fi

VER=$(grep -E "^VERSION =" "$KERNEL_SRC_DIR/Makefile" | awk '{print $3}')
PATCH=$(grep -E "^PATCHLEVEL =" "$KERNEL_SRC_DIR/Makefile" | awk '{print $3}')
TARGET_DIR="kernel/msm-${VER}.${PATCH}"

echo "正在进行外部模块依赖检测..."
if [ -L "$KERNEL_SRC_DIR/block/healthinfo" ] || \
   [ -L "$KERNEL_SRC_DIR/kernel/tuning" ] || \
   [ -L "$KERNEL_SRC_DIR/kernel/sched_assist" ]; then
    
    echo "检测到内核源码包含指向外部模块的软链接 (healthinfo/tuning/sched_assist)。"
    
    if [ -z "$DT_URL" ]; then
        echo "致命错误：当前内核环境依赖外部模块，但未检测到设备树仓库变量 (DT_URL)！"
        echo "必须提供设备树来补全缺失的文件实体。"
        echo "请检查并设置 DT_URL 环境变量后重试。"
        exit 1
    else
        echo "设备树地址已提供，继续执行部署流程。"
    fi
else
    echo "未检测到关键外部软链接，环境完整或不依赖外部模块。"
fi

mkdir -p kernel
if [ ! -d "$TARGET_DIR" ]; then
    echo "将内核移动至标准路径: $TARGET_DIR"
    mv "$KERNEL_SRC_DIR" "$TARGET_DIR"
    ln -snf "$TARGET_DIR" "./$KERNEL_SRC_DIR"
fi

if [ -n "$DT_URL" ] && [ -n "$DT_BRANCH" ]; then
    echo "正在从 $DT_URL 拉取设备树..."
    git clone "$DT_URL" -b "$DT_BRANCH" --depth=1 temp_dt
    
    echo "正在将设备树部署至 kernel 同级目录..."
    [ -d "temp_dt/vendor" ] && rm -rf ./vendor && mv temp_dt/vendor ./vendor
    [ -d "temp_dt/device" ] && rm -rf ./device && mv temp_dt/device ./device
    rm -rf temp_dt
    echo "设备树部署完毕。"
fi

echo "部署完成：厂商内核目录结构已标准化，设备树已就绪！"

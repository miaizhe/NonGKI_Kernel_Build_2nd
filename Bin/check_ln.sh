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

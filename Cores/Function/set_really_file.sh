#!/bin/bash
#VERSION="1.0.2"
# 设置Really文件路径
set_really_file() {
    local purity=$1
    local category=$2
    local purity_suffix
    local category_suffix

    # 设置纯度后缀
    case "$purity" in
        100) purity_suffix="R8" ;;
        110) purity_suffix="R13" ;;
        111) purity_suffix="R18" ;;
        010) purity_suffix="Only13" ;;
        001) purity_suffix="Only18" ;;
        011) purity_suffix="R18D" ;;
        *) purity_suffix="R13" ;;
    esac

    # 设置类别后缀
    case "$category" in
        zr) category_suffix="zr" ;;
        dm) category_suffix="dm" ;;
        *) category_suffix="General" ;;
    esac

    REALLY_DIR="/storage/emulated/0/Wallpaper/Cores/Reallys"
    mkdir -p "$REALLY_DIR"
    export REALLY_FILE="$REALLY_DIR/Really_${purity_suffix}_${category_suffix}.txt"
    touch "$REALLY_FILE"
    REALLY="${purity_suffix}_${category_suffix}.txt"
}
#!/bin/bash
#VERSION="1.0.2"
#设置MAX缓存
set_cache_file() {
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
        *) purity_suffix="R13" ;;  # 默认 R13
    esac

    # 设置类别后缀
    case "$category" in
        zr) category_suffix="zr" ;;
        dm) category_suffix="dm" ;;
        *) category_suffix="zr" ;;  # 默认 zr
    esac

    CACHE_FILE="/storage/emulated/0/Wallpaper/Cores/Pages/page_cache_${purity_suffix}_${category_suffix}.txt"
    FILE="${purity_suffix}_${category_suffix}.txt"
    touch "$CACHE_FILE"  # 确保缓存文件存在
    echo "$(date '+%m-%d %H:%M') | 加载Max文件" >&2
}
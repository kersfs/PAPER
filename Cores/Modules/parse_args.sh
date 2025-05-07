#!/bin/bash
#VERSION="1.0.2"
#========== 解析参数 ==========
MODE="$1"
INTERVAL_MINUTES="$2"
PURITY=""
CATEGORY_MODE=""
SEARCH_MODE="zh"
#====== 如果没有参数则进入交互模式 ===
if [ -z "$MODE" ]; then
    echo "请选择运行模式："
    echo "(1) 下载模式"
    echo "(2) 定时更换壁纸模式"
    read -p "输入序号（默认 1）: " mode_choice
    case "$mode_choice" in
        2)
            MODE="bz"
            read -p "请输入更换间隔分钟数（默认 7 分钟）: " interval_input
            INTERVAL_MINUTES="${interval_input:-7}"
            ;;
        *)
            MODE="xz"
            ;;
    esac
    # 添加 purity 选择并显示年龄提示
    echo "请选择壁纸纯度等级（括号内为建议年龄范围）："
    echo "(1) R8（仅 SFW，适合工作场所，适合 8 岁及以上）"
    echo "(2) R13（SFW + Sketchy，适合 13 岁及以上）"
    echo "(3) R18（SFW + Sketchy + NSFW，适合 18 岁及以上）"
    echo "(4) Only13（仅 Sketchy，适合 13 岁及以上）"
    echo "(5) Only18（仅 NSFW，适合 18 岁及以上）"
    echo "(6) R18D（Sketchy + NSFW，适合 18 岁及以上）"
    read -p "输入序号（默认 2）： " purity_choice
    case "$purity_choice" in
        1) PURITY="100"; echo "已选择 R8（仅 SFW，适合 8 岁及以上）" ;;
        3) PURITY="111"; echo "已选择 R18（SFW + Sketchy + NSFW，适合 18 岁及以上）" ;;
        4) PURITY="010"; echo "已选择 Only13（仅 Sketchy，适合 13 岁及以上）" ;;
        5) PURITY="001"; echo "已选择 Only18（仅 NSFW，适合 18 岁及以上）" ;;
        6) PURITY="011"; echo "已选择 R18D（Sketchy + NSFW，适合 18 岁及以上）" ;;
        *) PURITY="110"; echo "已选择 R13（SFW + Sketchy，适合 13 岁及以上）" ;;
    esac
# 添加类别模式选择
    echo "请选择壁纸类别模式："
    echo "(1) Only zr"
    echo "(2) Only dm"
    echo "(3) zr dm Rotation"
    read -p "输入序号（默认 3）： " category_choice
    case "$category_choice" in
    1)
            CATEGORY_MODE="zr"
            echo "已选择 Only zr 模式"
        # 添加搜索模式选择
            echo "请选择搜索模式："
            echo "(1) gjc"
            echo "(2) zh"
            read -p "输入序号（默认 2）： " search_mode_choice
            case "$search_mode_choice" in
            1) SEARCH_MODE="gjc"; echo "已选择 gjc" ;;
            *) SEARCH_MODE="zh"; echo "已选择 zh" ;;
            esac
            ;;
    2) CATEGORY_MODE="dm"; echo "已选择 Only dm 模式" ;;
    *) CATEGORY_MODE="lh"; echo "已选择 zr dm Rotation 模式" ;;
esac
# 添加分辨率选项交互
echo "请选择最低分辨率模式："
echo "(1) 设备自适应（根据设备分辨率自动调整）"
echo "(2) 1.5K优先（最低 1500x1500）"
echo "(3) 自定义分辨率（手动输入宽度和高度）"
read -p "输入序号（默认 1）： " resolution_choice
case "$resolution_choice" in
    2)
        RESOLUTION_MODE="1.5k"
        MIN_WIDTH=1500
        MIN_HEIGHT=1500
        echo "已选择 1.5K优先（最低 1500x1500）"
        ;;
    3)
        RESOLUTION_MODE="zdy"
        read -p "请输入最低宽度（像素，例如 1920）： " zdy_width
        read -p "请输入最低高度（像素，例如 1080）： " zdy_height
        # 验证输入是否为正整数
        if [[ "$zdy_width" =~ ^[0-9]+$ ]] && [[ "$zdy_height" =~ ^[0-9]+$ ]] && [ "$zdy_width" -gt 0 ] && [ "$zdy_height" -gt 0 ]; then
            MIN_WIDTH="$zdy_width"
            MIN_HEIGHT="$zdy_height"
            echo "已选择自定义分辨率：${MIN_WIDTH}x${MIN_HEIGHT}"
        else
            echo "输入无效，默认使用设备自适应"
            RESOLUTION_MODE="zsy"
            resolution=$(get_device_resolution)
            MIN_WIDTH=$(echo "$resolution" | cut -d'x' -f1)
            MIN_HEIGHT=$(echo "$resolution" | cut -d'x' -f2)
            echo "设备分辨率：${MIN_WIDTH}x${MIN_HEIGHT}"
        fi
        ;;
    *)
        RESOLUTION_MODE="zsy"
        resolution=$(get_device_resolution)
        MIN_WIDTH=$(echo "$resolution" | cut -d'x' -f1)
        MIN_HEIGHT=$(echo "$resolution" | cut -d'x' -f2)
        echo "已选择设备自适应，分辨率：${MIN_WIDTH}x${MIN_HEIGHT}"
        ;;
esac
# 询问是否开启Bottom-pocket机制
read -p "是否开启Bottom-pocket机制？(y/n，默认 n): " fallback_choice
if [[ "$fallback_choice" =~ ^[Yy]$ ]]; then
    FALLBACK_MECHANISM="enabled"
    echo "已启用Bottom-pocket机制"
else
    FALLBACK_MECHANISM="disabled"
    echo "未启用Bottom-pocket机制"
fi

    read -p "是否后台运行脚本？(y/n): " bg_choice
    if [[ "$bg_choice" =~ ^[Yy]$ ]]; then
    # 终止旧的后台进程
        if [ -f "$LOG_DIR/wallpaper.pid" ]; then
            old_pid=$(cat "$LOG_DIR/wallpaper.pid")
            if ps -p "$old_pid" >/dev/null 2>&1; then
                kill -9 "$old_pid" 2>/dev/null
            fi
        fi
        cp "$SCRIPT_DIR/$SCRIPT_NAME" "$SCRIPT_PATH"
        chmod +x "$SCRIPT_PATH"
    # 验证复制的脚本语法
        if ! bash -n "$SCRIPT_PATH" >/dev/null 2>&1; then
            echo "$(date '+%m-%d %H:%M') | 复制的脚本 $SCRIPT_PATH 包含语法错误，请检查" >&2
            exit 1
        fi
        echo "$(date '+%m-%d %H:%M') | 脚本将在后台运行，日志保存在background.log" >&2
        nohup bash "$SCRIPT_PATH" "$MODE" "$INTERVAL_MINUTES" "$PURITY" "$CATEGORY_MODE" "$SEARCH_MODE" "$FALLBACK_MECHANISM" "$RESOLUTION_MODE" "$MIN_WIDTH" "$MIN_HEIGHT" > "$LOG_DIR/background.log" 2>&1 &
        echo $! > "$LOG_DIR/wallpaper.pid"
        exit 0
    fi
else
    # 如果通过命令行参数运行，检查是否有 purity 参数
    PURITY="$3"
    if [ -z "$PURITY" ]; then
        PURITY="110"
        echo "$(date '+%m-%d %H:%M') | 未指定纯度等级，默认使用 R13（适合 13 岁及以上）" >&2
    else
        case "$PURITY" in
            100) echo "$(date '+%m-%d %H:%M') | 使用指定的纯度等级：R8" ;;
            110) echo "$(date '+%m-%d %H:%M') | 使用指定的纯度等级：R13" ;;
            111) echo "$(date '+%m-%d %H:%M') | 使用指定的纯度等级：R18" ;;
            010) echo "$(date '+%m-%d %H:%M') | 使用指定的纯度等级：Only13" ;;
            001) echo "$(date '+%m-%d %H:%M') | 使用指定的纯度等级：Only18" ;;
            011) echo "$(date '+%m-%d %H:%M') | 使用指定的纯度等级：R18D" ;;
            *) echo "$(date '+%m-%d %H:%M') | 无效的纯度等级：$PURITY，默认使用 R13"; PURITY="110" ;;
        esac
    fi
    # 检查是否有 CATEGORY_MODE 参数
    CATEGORY_MODE="$4"
    if [ -z "$CATEGORY_MODE" ]; then
        CATEGORY_MODE="lh"
        echo "$(date '+%m-%d %H:%M') | 未指定类别模式，默认使用 zr dm Rotation 模式" >&2
    else
        case "$CATEGORY_MODE" in
            zr) echo "$(date '+%m-%d %H:%M') | 使用指定的类别模式：Only zr" ;;
            dm) echo "$(date '+%m-%d %H:%M') | 使用指定的类别模式：Only dm" ;;
            lh) echo "$(date '+%m-%d %H:%M') | 使用指定的类别模式：zr dm Rotation" ;;
            *) echo "$(date '+%m-%d %H:%M') | 无效的类别模式：$CATEGORY_MODE，默认使用 zr dm Rotation 模式"; CATEGORY_MODE="lh" ;;
        esac
    fi

    # 检查是否有 SEARCH_MODE 参数（仅在 CATEGORY_MODE="zr" 时有效）
    SEARCH_MODE="$5"
    if [ "$CATEGORY_MODE" == "zr" ]; then
        if [ -z "$SEARCH_MODE" ]; then
            SEARCH_MODE="zh"
            echo "$(date '+%m-%d %H:%M') | 未指定搜索模式，默认使用Combination" >&2
        else
            case "$SEARCH_MODE" in
                gjc) echo "$(date '+%m-%d %H:%M') | 使用指定的搜索模式：gjc" ;;
                zh) echo "$(date '+%m-%d %H:%M') | 使用指定的搜索模式：zh" ;;
                *) echo "$(date '+%m-%d %H:%M') | 无效的搜索模式：$SEARCH_MODE，默认使用Combination"; SEARCH_MODE="zh" ;;
            esac
        fi
    else
        SEARCH_MODE="zh"  # 非 zr 模式下，SEARCH_MODE 无意义，设置为默认值
        echo "$(date '+%m-%d %H:%M') | 非 Only zr 模式，搜索模式默认设置为 zh 模式" >&2
    fi
    # 检查是否有 FALLBACK_MECHANISM 参数
    FALLBACK_MECHANISM="$6"
    if [ -z "$FALLBACK_MECHANISM" ]; then
        FALLBACK_MECHANISM="disabled"
        echo "$(date '+%m-%d %H:%M') | 未指定Bottom-pocket机制，默认禁用" >&2
        else
        if [ "$FALLBACK_MECHANISM" == "enabled" ]; then
            echo "$(date '+%m-%d %H:%M') | Bottom-pocket机制：启用" >&2
        elif [ "$FALLBACK_MECHANISM" == "disabled" ]; then
            echo "$(date '+%m-%d %H:%M') | Bottom-pocket机制：禁用" >&2
        else
            echo "$(date '+%m-%d %H:%M') | 无效的Bottom-pocket机制参数：$FALLBACK_MECHANISM，默认禁用" >&2
            FALLBACK_MECHANISM="disabled"
        fi
    fi
    # 检查是否有 RESOLUTION_MODE 参数
    RESOLUTION_MODE="$7"
    MIN_WIDTH="$8"
    MIN_HEIGHT="$9"
    if [ -z "$RESOLUTION_MODE" ]; then
        RESOLUTION_MODE="zsy"
        resolution=$(get_device_resolution)
        MIN_WIDTH=$(echo "$resolution" | cut -d'x' -f1)
        MIN_HEIGHT=$(echo "$resolution" | cut -d'x' -f2)
        echo "$(date '+%m-%d %H:%M') | 未指定分辨率模式，默认使用设备自适应：${MIN_WIDTH}x${MIN_HEIGHT}" >&2
else
        case "$RESOLUTION_MODE" in
        zsy)
                resolution=$(get_device_resolution)
                MIN_WIDTH=$(echo "$resolution" | cut -d'x' -f1)
                MIN_HEIGHT=$(echo "$resolution" | cut -d'x' -f2)
                echo "$(date '+%m-%d %H:%M') | 使用指定的分辨率模式：设备自适应（${MIN_WIDTH}x${MIN_HEIGHT}）" >&2
                ;;
            1.5k)
                MIN_WIDTH=1500
                MIN_HEIGHT=1500
                echo "$(date '+%m-%d %H:%M') | 使用指定的分辨率模式：1.5K优先（1500x1500）" >&2
                ;;
            zdy)
                if [[ "$MIN_WIDTH" =~ ^[0-9]+$ ]] && [[ "$MIN_HEIGHT" =~ ^[0-9]+$ ]] && [ "$MIN_WIDTH" -gt 0 ] && [ "$MIN_HEIGHT" -gt 0 ]; then
                    echo "$(date '+%m-%d %H:%M') | 使用指定的分辨率模式：自定义（${MIN_WIDTH}x${MIN_HEIGHT}）" >&2
                else
                    echo "$(date '+%m-%d %H:%M') | 自定义分辨率参数无效，默认使用设备自适应" >&2
                    RESOLUTION_MODE="zsy"
                    resolution=$(get_device_resolution)
                    MIN_WIDTH=$(echo "$resolution" | cut -d'x' -f1)
                    MIN_HEIGHT=$(echo "$resolution" | cut -d'x' -f2)
                    echo "$(date '+%m-%d %H:%M') | 设备分辨率：${MIN_WIDTH}x${MIN_HEIGHT}" >&2
                fi
                ;;
            *)
                echo "$(date '+%m-%d %H:%M') | 无效的分辨率模式：$RESOLUTION_MODE，默认使用设备自适应" >&2
                RESOLUTION_MODE="zsy"
                resolution=$(get_device_resolution)
                MIN_WIDTH=$(echo "$resolution" | cut -d'x' -f1)
                MIN_HEIGHT=$(echo "$resolution" | cut -d'x' -f2)
                echo "$(date '+%m-%d %H:%M') | 设备分辨率：${MIN_WIDTH}x${MIN_HEIGHT}" >&2
                ;;
        esac
    fi
fi
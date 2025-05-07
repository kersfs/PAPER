#!/bin/bash

#========== 关键词设置 ==========
# 检查关键词目录是否存在
if [ ! -d "$KEYWORD_DIR" ]; then
    echo "关键词目录未找到：$KEYWORD_DIR" >&2
    exit 1
fi
# 加载国家关键词
if [ -s "$KEYWORD_DIR/country.txt" ]; then
    mapfile -t COUNTRY_QUERIES < <(grep -v '^[[:space:]]*$' "$KEYWORD_DIR/country.txt" | sed 's/[[:space:]]*$//')
    if [ ${#COUNTRY_QUERIES[@]} -eq 0 ]; then
        echo "country.txt 为空或只包含空行" >&2
        exit 1
    fi
    echo "$(date '+%m-%d %H:%M') | 加载 ${#COUNTRY_QUERIES[@]} 个国家关键词" >&2
else
    echo "未找到 country.txt：$KEYWORD_DIR/country.txt" >&2
    exit 1
fi

# 加载真人关键词
if [ -s "$KEYWORD_DIR/welfare.txt" ]; then
    mapfile -t WELFARE_QUERIES < <(grep -v '^[[:space:]]*$' "$KEYWORD_DIR/welfare.txt" | sed 's/[[:space:]]*$//')
    if [ ${#WELFARE_QUERIES[@]} -eq 0 ]; then
        echo "welfare.txt 为空或只包含空行" >&2
        exit 1
    fi
    echo "$(date '+%m-%d %H:%M') | 加载 ${#WELFARE_QUERIES[@]} 个真人关键词" >&2
else
    echo "未找到 welfare.txt：$KEYWORD_DIR/welfare.txt" >&2
    exit 1
fi

# 加载动漫关键词
if [ -s "$KEYWORD_DIR/dm.txt" ]; then
    mapfile -t ANIME_QUERIES < <(grep -v '^[[:space:]]*$' "$KEYWORD_DIR/dm.txt" | sed 's/[[:space:]]*$//')
    if [ ${#ANIME_QUERIES[@]} -eq 0 ]; then
        echo "dm.txt 为空或只包含空行" >&2
        exit 1
    fi
    echo "$(date '+%m-%d %H:%M') | 加载 ${#ANIME_QUERIES[@]} 个动漫关键词" >&2
else
    echo "未找到 dm.txt：$KEYWORD_DIR/dm.txt" >&2
    exit 1
fi

# 加载关键词映射
declare -A QUERY_MAP
if [ -s "$KEYWORD_DIR/query_map.txt" ]; then
    while IFS='|' read -r key value; do
        # 跳过空行或格式错误的行
        if [ -z "$key" ] || [ -z "$value" ]; then
            continue
        fi
        QUERY_MAP["$key"]="$value"
    done < "$KEYWORD_DIR/query_map.txt"
    echo "$(date '+%m-%d %H:%M') | 加载 ${#QUERY_MAP[@]} 个关键词映射" >&2
else
    echo "未找到 query_map.txt：$KEYWORD_DIR/query_map.txt" >&2
    exit 1
fi
declare -A CATEGORY_MAP=(
    ["zr"]="人物"
    ["dm"]="动漫"
    ["lh"]="轮换"
)

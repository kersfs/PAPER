#!/bin/bash
#VERSION="1.0.2"
# 测试 API 密钥有效性
test_api_key() {
    local max_retries=2
    local retry_delay=2
    local attempt=1
    local response
    local error

    while [ $attempt -le $max_retries ]; do
        response=$(curl -s --max-time 7 "https://wallhaven.cc/api/v1/search?page=1&apikey=${API_KEY}")
        error=$(echo "$response" | jq -r '.error // null')
        
        if [ -n "$response" ] && [ "$error" == "null" ]; then
            return 0
        fi
        sleep $retry_delay
        attempt=$((attempt + 1))
    done
    return 1
}
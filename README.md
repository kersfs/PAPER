# PAPER
基于whallhaven开发的手机壁纸项目  

# 克隆本项目

```git clone https://github.com/kersfs/PAPER.git```

# 本地运行
若不需要动态更新  
下载该项目zip文件  
将文件解压到`/storage/emulated/0/Wallpaper`目录，没有目录手动创建
Termux 运行命令  

```bash /storage/emulated/0/Wallpaper/Bin/l.sh```

# 使用说明
该项目脚本基于`Termux`和`Termux API`运行前请下载对于应用  
首次使用先运行`Bin`目录下的`paper.sh`脚本，初始化程序/后续无需再运行  
并支持多种运行模式、关键词搜索、纯度等级、分辨率选择以及备用机制  
脚本具有高度可配置性，支持后台运行和动态调整参数，以确保壁纸下载和更换的稳定性。以下是脚本的主要功能及其使用方法  

# 主要功能
壁纸下载与更换下载模式 (xz)：批量下载指定数量的壁纸（默认510张）到指定目录，支持关键词搜索和分辨率过滤  
定时更换模式 (bz)：定期（默认每7分钟）更换壁纸，自动下载并设置符合条件的壁纸  
关键词搜索：根据预设的关键词（如国家、真人、动漫）从 wallhaven.cc 下载壁纸，支持组合搜索和单一关键词搜索  
动态分辨率适配支持三种分辨率模式：设备自适应 (zsy)：根据设备分辨率自动设置最低分辨率。1.5K优先 (1.5k)：最低分辨率为1500x1500。自定义 (zdy)：用户手动指定最低宽度和高度  
过滤横屏图片和宽高比大于0.8的图片，确保壁纸适合手机屏幕  

# 纯度等级
壁纸纯度等级控制支持六种纯度等级，适合不同年龄段用户：  
`R8 (100)：仅安全内容（SFW），适合8岁及以上  
R13 (110)：安全+轻度内容（SFW+Sketchy），适合13岁及以上  
R18 (111)：包含成人内容（SFW+Sketchy+NSFW），适合18岁及以上  
Only13 (010)：仅轻度内容（Sketchy），适合13岁及以上  
Only18 (001)：仅成人内容（NSFW），适合18岁及以上  
R18D (011)：轻度+成人内容（Sketchy+NSFW），适合18岁及以上`  

# 类别模式
支持三种类别模式：  
Only zr：仅真人壁纸  
Only dm：仅动漫壁纸  
zr dm Rotation (lh)：真人与动漫壁纸轮换（下载模式每下载5张切换类别，壁纸模式依次更换）  

# 搜索模式（仅对 zr 有效）：
gjc：单一真人关键词搜索  
zh：国家+真人关键词组合搜索  

# Bottom-pocket 机制
当连续下载失败达到阈值（默认5-20次，基于更换间隔动态调整）或主程序（wallhaven.cc）不可用时，切换到备用下载机制  
从 Bottom_pocket.txt 中随机选择预设URL下载壁纸。可通过参数启用或禁用此机制  

# 万化归一模式
通过检测 Diagram 文件动态调整脚本参数（如模式、间隔、纯度等），配置文件为 Thousand.txt  
当 Diagram 文件存在时，脚本进入“万化归一”模式，优先使用 Thousand.txt 中的参数；移除文件后恢复原始参数  

# 锚点
锚点文件 (Anchor_point)：用于控制脚本运行，若文件不存在，脚本进入休眠状态  

# 备用壁纸锚点
备用锚点 (Anchor)：当备用锚点文件不存在时，切换到备用壁纸 (back.jpg)，暂停下载和更换  

# 网络检测：
通过 ping wallhaven.cc 和 v2.xxapi.cn 检测网络状态，异常时暂停操作  

# 日志与缓存
管理日志记录下载和更换操作，保存在 cron_log.txt，超过10MB自动备份  
缓存搜索结果到 page_cache_*.txt，7天后清理过期缓存  

# 智能学习机制
脚本自动更新 Really_*.txt（成功关键词）和 Fallback_*.txt（无效关键词），7天后清理  

# 数据库
使用 SQLite 数据库 (wallpaper_history.db) 记录已下载的壁纸URL，防止重复下载  

# 后台运行
支持将脚本复制到 Termux 目录并以 nohup 方式后台运行，日志输出到 background.log  

# 依赖管理
自动检测并安装必要的依赖（如 termux-wallpaper、imagemagick、curl、bc、awk、jq、sqlite3、libxml2）  

# 各功能使用方法
运行脚本脚本支持交互模式和命令行参数两种方式运行  
1.交互模式（无参数运行）：  
bash l.sh  
脚本会提示用户选择：  
运行模式（xz 或 bz）  
更换间隔（仅 bz 模式，默认7分钟）  
纯度等级（默认 R13）  
类别模式（默认 lh）  
搜索模式（仅 zr 模式，默认 zh）  
分辨率模式（默认 zsy）  
是否启用 Bottom-pocket 机制（默认禁用）  
是否后台运行（默认前台）  
2.命令行参数模式：  
```bash l.sh MODE INTERVAL_MINUTES PURITY CATEGORY_MODE SEARCH_MODE FALLBACK_MECHANISM RESOLUTION_MODE MIN_WIDTH MIN_HEIGHT```

参数说明：
MODE：xz（下载）或 bz（定时更换）  
INTERVAL_MINUTES：更换间隔分钟数（仅 bz 模式，默认7）  
PURITY：纯度等级（100, 110, 111, 010, 001, 011，默认 110）  
CATEGORY_MODE：类别模式（zr, dm, lh，默认 lh）  
SEARCH_MODE：搜索模式（gjc, zh，仅 zr 模式有效，默认 zh）  
FALLBACK_MECHANISM：Bottom-pocket 机制（enabled, disabled，默认 disabled）  
RESOLUTION_MODE：分辨率模式（zsy, 1.5k, zdy，默认 zsy）  
MIN_WIDTH, MIN_HEIGHT：自定义分辨率宽度和高度（仅 zdy 模式有效）  
示例：bash wallpaper_run_tmp.sh bz 10 110 zr zh enabled zsy表示定时更换模式，每10分钟更换一次，纯度 R13，仅真人壁纸，组合搜索，启用 Bottom-pocket，设备自适应分辨率。  

# 配置关键词关键词
文件位于 /storage/emulated/0/Wallpaper/Cores/Keywords/，需要手动准备：  
country.txt：国家关键词（如 japan, korea）  
welfare.txt：真人关键词（如 girl, cosplay）  
dm.txt：动漫关键词（如 anime, manga）  
query_map.txt：关键词映射（如 japan|日本）  
Bottom_pocket.txt：备用壁纸URL列表（每行一个URL）  
格式要求：每行一个关键词或URL  

# 配置 API 密钥创建 
/storage/emulated/0/Wallpaper/Cores/Keywords/api_key.txt，填入有效的 wallhaven.cc API 密钥  
获取方式：注册 wallhaven.cc 账号，访问 API 页面获取密钥。脚本会验证密钥有效性，若无效则尝试 Bottom-pocket 机制  

# 万化归一模式 
创建 /storage/emulated/0/Wallpaper/Cores/Cdivination/Diagram 文件以进入万化归一模式  
编辑 /storage/emulated/0/Wallpaper/Cores/Cdivination/Thousand.txt，格式为：  
MODE=bz  
INTERVAL_MINUTES=10  
PURITY=110  
CATEGORY_MODE=zr  
SEARCH_MODE=zh  
FALLBACK_MECHANISM=enabled  
RESOLUTION_MODE=zsy  
MIN_WIDTH=1080  
MIN_HEIGHT=1920  
每次修改 Thousand.txt 或首次进入模式，脚本会加载新参数。删除 Diagram 文件以恢复原始参数  
参数前加#该参数不更新  

# 锚点与备用壁纸锚点文件：
确保 /storage/emulated/0/Wallpaper/Cores/Configs/Anchor_point 存在，否则脚本休眠  
备用锚点：确保 /storage/emulated/0/Wallpaper/Cores/Backs/Anchor 存在，否则使用备用壁纸 /storage/emulated/0/Wallpaper/Cores/Backs/back.jpg  
手动创建或删除这些文件以控制脚本行为  

# 日志与缓存管理日志文件：
/storage/emulated/0/Wallpaper/Cores/Logs/cron_log.txt，记录下载和更换详情  
缓存文件：/storage/emulated/0/Wallpaper/Cores/Pages/page_cache_*.txt，存储搜索结果。成功/无效关键词：  
Really_*.txt：记录成功下载的关键词  
Fallback_*.txt：记录无有效结果的关键词  
数据库：/storage/emulated/0/Wallpaper/Cores/Logs/wallpaper_history.db，记录已下载URL，最大777条  

# 清理
脚本自动清理7天前的日志、缓存和关键词文件  


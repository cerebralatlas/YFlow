#!/bin/bash

# =============================================================================
# YFlow 一键安装脚本
# =============================================================================
# 用法:
#   curl -sSL https://raw.githubusercontent.com/你的用户名/YFlow/main/install.sh | bash
#
# 支持的参数:
#   --domain DOMAIN          域名 (默认: localhost)
#   --port PORT              前端端口 (默认: 8081)
#   --db-password PASSWORD   MySQL Root 密码 (默认: 自动生成)
#   --admin-user USER        管理员用户名 (默认: admin)
#   --admin-password PASSWORD 管理员密码 (默认: 自动生成)
#   --enable-mt              启用机器翻译 (默认: no)
#   --install-dir DIR        安装目录 (默认: /opt/yflow)
#   --repo URL               仓库地址 (默认: 当前仓库)
#   --branch BRANCH          分支名 (默认: main)
#   --non-interactive        非交互式模式
# =============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 默认配置
DOMAIN="localhost"
FRONTEND_PORT="8081"
DB_PASSWORD=""
ADMIN_USER="admin"
ADMIN_PASSWORD=""
ENABLE_MT="no"
INSTALL_DIR="/opt/yflow"
REPO_URL=""
BRANCH="main"
NON_INTERACTIVE=false

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --domain)
                DOMAIN="$2"
                shift 2
                ;;
            --port)
                FRONTEND_PORT="$2"
                shift 2
                ;;
            --db-password)
                DB_PASSWORD="$2"
                shift 2
                ;;
            --admin-user)
                ADMIN_USER="$2"
                shift 2
                ;;
            --admin-password)
                ADMIN_PASSWORD="$2"
                shift 2
                ;;
            --enable-mt)
                ENABLE_MT="yes"
                shift
                ;;
            --install-dir)
                INSTALL_DIR="$2"
                shift 2
                ;;
            --repo)
                REPO_URL="$2"
                shift 2
                ;;
            --branch)
                BRANCH="$2"
                shift 2
                ;;
            --non-interactive)
                NON_INTERACTIVE=true
                shift
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# 生成随机密码
generate_password() {
    local length=${1:-32}
    openssl rand -base64 "$length" | head -c "$length" | tr -dc 'a-zA-Z0-9' | head -c "$length"
}

# 检查依赖
check_dependencies() {
    log_step "检查系统依赖..."

    local missing_deps=()

    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装 Docker"
        missing_deps+=("docker")
    fi

    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose 未安装，请先安装 Docker Compose"
        missing_deps+=("docker-compose")
    fi

    if ! command -v curl &> /dev/null; then
        log_error "curl 未安装，请先安装 curl"
        missing_deps+=("curl")
    fi

    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "缺少必要依赖: ${missing_deps[*]}"
        exit 1
    fi

    log_info "✅ 所有依赖已安装"
}

# 检查 Docker 服务
check_docker_service() {
    log_step "检查 Docker 服务..."

    if ! docker info &> /dev/null; then
        log_error "Docker 服务未运行，请启动 Docker 后重试"
        exit 1
    fi

    log_info "✅ Docker 服务运行正常"
}

# 交互式配置
interactive_config() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                                                                ║${NC}"
    echo -e "${BLUE}║${NC}   ${GREEN}  ██████╗ ██████╗ ███████╗███╗   ██╗ █████╗  ██████╗██╗  ██╗${NC}   ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}   ${GREEN} ██╔════╝██╔══██╗██╔════╝████╗  ██║██╔══██╗██╔════╝██║ ██╔╝${NC}   ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}   ${GREEN} ██║     ██████╔╝█████╗  ██╔██╗ ██║███████║██║     █████╔╝ ${NC}   ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}   ${GREEN} ██║     ██╔══██╗██╔══╝  ██║╚██╗██║██╔══██║██║     ██╔═██╗ ${NC}   ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}   ${GREEN} ╚██████╗██║  ██║███████╗██║ ╚████║██║  ██║╚██████╗██║  ██╗${NC}   ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}   ${GREEN}  ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝${NC}   ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}                                                                ║${NC}"
    echo -e "${BLUE}║${NC}   ${YELLOW}         国际化管理平台 - 一键安装脚本 v1.0${NC}                ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}                                                                ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}欢迎使用 YFlow 一键安装脚本${NC}"
    echo ""

    # 安装目录
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│  1. 安装目录配置                                            │${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    read -p "     安装目录 [${INSTALL_DIR}]: " input_dir
    INSTALL_DIR=${input_dir:-$INSTALL_DIR}
    echo ""

    # 数据库配置
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│  2. 数据库配置                                              │${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"
    echo ""

    while true; do
        read -s -p "     MySQL Root 密码 (至少8位): " db_password
        echo ""
        if [ ${#db_password} -ge 8 ]; then
            read -s -p "     确认密码: " db_password_confirm
            echo ""
            if [ "$db_password" = "$db_password_confirm" ]; then
                DB_PASSWORD="$db_password"
                break
            else
                log_error "两次输入的密码不一致，请重新输入"
            fi
        else
            log_error "密码长度至少8位"
        fi
    done

    # 管理员账户
    echo ""
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│  3. 管理员账户配置                                          │${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"
    echo ""

    read -p "     用户名 [admin]: " admin_username
    ADMIN_USER=${admin_username:-admin}

    read -s -p "     密码 [自动生成]: " admin_password
    echo ""
    if [ -z "$admin_password" ]; then
        ADMIN_PASSWORD=$(generate_password 12)
        log_info "已生成管理员密码: $ADMIN_PASSWORD"
    else
        ADMIN_PASSWORD="$admin_password"
    fi

    # 机器翻译
    echo ""
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│  4. 机器翻译配置                                            │${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"
    echo ""

    log_warn "LibreTranslate 机器翻译服务需要约 1GB 内存"
    read -p "     是否启动机器翻译服务? [y/N]: " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ENABLE_MT="yes"
    else
        ENABLE_MT="no"
    fi

    # 域名配置
    echo ""
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│  5. 域名配置                                                │${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"
    echo ""

    echo -e "     ${YELLOW}提示:${NC} 使用 Let's Encrypt 需要："
    echo "       - 有效的域名（DNS 已解析到服务器 IP）"
    echo "       - 开放 80 和 443 端口"
    echo ""
    read -p "     域名 (直接回车使用 localhost): " domain
    DOMAIN=${domain:-localhost}
}

# 获取仓库信息
get_repo_info() {
    if [ -z "$REPO_URL" ]; then
        if [ -d ".git" ]; then
            REPO_URL=$(git remote get-url origin 2>/dev/null | sed 's/\.git$//' || echo "")
        fi
    fi

    if [ -z "$REPO_URL" ]; then
        log_warn "无法自动检测仓库地址，使用默认值"
        REPO_URL="https://github.com/ishechuan/YFlow"
    fi

    log_info "使用仓库: $REPO_URL"
}

# 下载文件
download_file() {
    local url="$1"
    local dest="$2"
    local desc="$3"

    log_step "下载 ${desc}..."

    if curl -fsSL "$url" -o "$dest"; then
        log_info "✅ ${desc} 下载成功"
        return 0
    else
        log_error "下载 ${desc} 失败: $url"
        return 1
    fi
}

# 下载项目文件
download_project() {
    log_step "下载项目文件到 $INSTALL_DIR..."

    mkdir -p "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR/deploy/nginx"

    local raw_url="${REPO_URL}/raw/${BRANCH}"

    download_file "${raw_url}/docker-compose.yml" "$INSTALL_DIR/docker-compose.yml" "docker-compose.yml"
    download_file "${raw_url}/deploy/nginx/Caddyfile" "$INSTALL_DIR/deploy/nginx/Caddyfile" "Caddyfile"
    download_file "${raw_url}/deploy/deploy.sh" "$INSTALL_DIR/deploy.sh" "deploy.sh"

    chmod +x "$INSTALL_DIR/deploy.sh"

    log_info "✅ 项目文件下载完成"
}

# 生成配置文件
generate_env() {
    log_step "生成配置文件..."

    if [ -z "$DB_PASSWORD" ]; then
        DB_PASSWORD=$(generate_password 16)
        log_info "已生成数据库密码: $DB_PASSWORD"
    fi

    if [ -z "$ADMIN_PASSWORD" ]; then
        ADMIN_PASSWORD=$(generate_password 12)
        log_info "已生成管理员密码: $ADMIN_PASSWORD"
    fi

    local jwt_secret=$(openssl rand -base64 64 | tr -dc 'a-zA-Z0-9' | head -c 64)
    local jwt_refresh_secret=$(openssl rand -base64 64 | tr -dc 'a-zA-Z0-9' | head -c 64)
    local cli_api_key=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32)

    cat > "$INSTALL_DIR/.env" << EOF
# =============================================================================
# YFlow 配置文件
# =============================================================================
# 此文件由 install.sh 自动生成
# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')
# =============================================================================

# Database Configuration
DB_DRIVER=mysql
DB_ROOT_PASSWORD=$DB_PASSWORD
DB_USERNAME=root
DB_PASSWORD=$DB_PASSWORD
DB_HOST=db
DB_PORT=3306
DB_NAME=yflow

# Redis Configuration
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0
REDIS_PREFIX=yflow:

# JWT Configuration
JWT_SECRET=$jwt_secret
JWT_EXPIRATION_HOURS=24
JWT_REFRESH_SECRET=$jwt_refresh_secret
JWT_REFRESH_EXPIRATION_HOURS=168

# CLI API Key Configuration
CLI_API_KEY=$cli_api_key

# Admin User Configuration
ADMIN_USERNAME=$ADMIN_USER
ADMIN_PASSWORD=$ADMIN_PASSWORD

# Application Environment
ENV=production
GO_ENV=production

# Frontend Configuration
VITE_API_URL=/api

# LibreTranslate Machine Translation Configuration
ENABLE_LIBRETRANSLATE=$ENABLE_MT
LIBRE_TRANSLATE_URL=http://libretranslate:5000

# Domain Configuration
DOMAIN=$DOMAIN
EOF

    log_info "✅ 配置文件 .env 已生成"
}

# 启动服务
start_services() {
    cd "$INSTALL_DIR"

    log_step "拉取最新镜像..."
    docker compose pull

    log_step "启动容器..."
    docker compose up -d

    log_step "等待服务启动..."
    sleep 15

    log_step "检查服务状态..."
    local services=("db" "backend" "frontend" "caddy")
    local all_running=true

    for service in "${services[@]}"; do
        local container_name=$(docker ps --format '{{.Names}}' | grep -E "^yflow-${service}(-[0-9]+)?$" | head -1)
        if [ -z "$container_name" ]; then
            container_name="yflow-${service}"
        fi

        local status=$(docker inspect --format='{{.State.Status}}' "${container_name}" 2>/dev/null || echo "unknown")

        if [ "$status" = "running" ]; then
            echo -e "  ${GREEN}✓${NC} $service: 运行中"
        else
            echo -e "  ${RED}✗${NC} $service: $status"
            all_running=false
        fi
    done

    if [ "$all_running" = true ]; then
        log_info "✅ 所有服务启动成功"
    else
        log_warn "部分服务可能未正常启动，请检查日志"
    fi
}

# 打印完成信息
print_completion_info() {
    local access_url="https://$DOMAIN"
    if [ "$DOMAIN" = "localhost" ]; then
        access_url="http://localhost"
    fi

    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                                ║${NC}"
    echo -e "${GREEN}║${NC}                     ${YELLOW}部署完成!${NC}                           ${GREEN}║${NC}"
    echo -e "${GREEN}║                                                                ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BLUE}安装目录:${NC}   $INSTALL_DIR"
    echo -e "  ${BLUE}访问地址:${NC}   $access_url"
    echo -e "  ${BLUE}管理员账户:${NC} $ADMIN_USER"
    echo -e "  ${BLUE}管理员密码:${NC} $ADMIN_PASSWORD"
    echo ""
    echo -e "  ${CYAN}常用命令:${NC}"
    echo -e "    进入目录: ${GREEN}cd $INSTALL_DIR${NC}"
    echo -e "    查看日志: ${GREEN}cd $INSTALL_DIR && ./deploy/deploy.sh --logs${NC}"
    echo -e "    重启服务: ${GREEN}cd $INSTALL_DIR && ./deploy/deploy.sh --restart${NC}"
    echo -e "    停止服务: ${GREEN}cd $INSTALL_DIR && ./deploy/deploy.sh --stop${NC}"
    echo ""
    if [ "$DOMAIN" != "localhost" ]; then
        echo -e "  ${GREEN}✓${NC} HTTPS 证书由 Let's Encrypt 自动提供"
        echo -e "  ${YELLOW}提示:${NC} 首次访问可能需要几秒钟获取证书"
        echo ""
    fi
    echo -e "  ${YELLOW}提示:${NC} 首次登录后请及时修改管理员密码"
    echo ""
}

# 主函数
main() {
    parse_args "$@"

    echo ""
    log_step "YFlow 安装程序启动..."

    check_dependencies
    check_docker_service

    if [ "$NON_INTERACTIVE" = false ]; then
        interactive_config
    else
        if [ -z "$DB_PASSWORD" ]; then
            DB_PASSWORD=$(generate_password 16)
            log_info "已生成数据库密码: $DB_PASSWORD"
        fi
        if [ -z "$ADMIN_PASSWORD" ]; then
            ADMIN_PASSWORD=$(generate_password 12)
            log_info "已生成管理员密码: $ADMIN_PASSWORD"
        fi
        log_info "使用非交互式模式配置"
    fi

    get_repo_info
    download_project
    generate_env
    start_services
    print_completion_info
}

main "$@"

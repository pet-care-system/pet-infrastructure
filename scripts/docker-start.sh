#!/bin/bash

# 宠物管理系统Docker启动脚本
# 支持多种部署模式

set -e

echo "🐾 宠物管理系统Docker部署工具"
echo "================================"

# 显示帮助信息
show_help() {
    echo ""
    echo "使用方法："
    echo "  ./docker-start.sh [模式] [选项]"
    echo ""
    echo "可用模式："
    echo "  simple      - 启动简化版系统（无数据库，内存数据）"
    echo "  full        - 启动完整版系统（包含PostgreSQL和Redis）"
    echo "  dev         - 开发模式（包含开发工具）"
    echo ""
    echo "选项："
    echo "  --build     - 强制重新构建镜像"
    echo "  --clean     - 清理所有容器和数据"
    echo "  --logs      - 显示服务日志"
    echo "  --status    - 查看服务状态"
    echo "  --stop      - 停止所有服务"
    echo "  --help      - 显示此帮助信息"
    echo ""
    echo "示例："
    echo "  ./docker-start.sh simple           # 启动简化版"
    echo "  ./docker-start.sh full --build     # 重新构建并启动完整版"
    echo "  ./docker-start.sh --stop           # 停止所有服务"
    echo ""
}

# 检查Docker是否安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker未安装，请先安装Docker"
        echo "   下载地址：https://www.docker.com/get-started"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        echo "❌ Docker Compose未安装或不可用"
        exit 1
    fi
    
    echo "✅ Docker环境检查通过"
}

# 清理函数
cleanup() {
    echo "🧹 清理现有容器和数据..."
    docker-compose -f docker-compose.yml down -v --remove-orphans 2>/dev/null || true
    docker-compose -f docker-compose.simple.yml down -v --remove-orphans 2>/dev/null || true
    docker system prune -f
    echo "✅ 清理完成"
}

# 启动简化版系统
start_simple() {
    echo "🚀 启动简化版宠物管理系统..."
    
    # 复制环境变量文件
    cp .env.simple .env
    
    # 构建和启动服务
    if [[ "$BUILD" == "true" ]]; then
        docker-compose -f docker-compose.simple.yml up --build -d
    else
        docker-compose -f docker-compose.simple.yml up -d
    fi
    
    echo ""
    echo "🎉 简化版系统启动成功！"
    echo ""
    echo "📱 前端访问地址: http://localhost:3001"
    echo "🔌 后端API地址:  http://localhost:8000"
    echo "💊 健康检查:     http://localhost:8000/health"
    echo ""
    echo "🔑 默认登录凭据:"
    echo "   用户名: admin"
    echo "   密码:   password"
    echo ""
}

# 启动完整版系统
start_full() {
    echo "🚀 启动完整版宠物管理系统..."
    
    # 复制环境变量文件
    cp .env.docker .env
    
    # 构建和启动服务
    if [[ "$BUILD" == "true" ]]; then
        docker-compose up --build -d
    else
        docker-compose up -d
    fi
    
    echo ""
    echo "⏳ 等待服务启动（约30秒）..."
    sleep 30
    
    echo ""
    echo "🎉 完整版系统启动成功！"
    echo ""
    echo "📱 前端访问地址:     http://localhost:3001"
    echo "🔌 后端API地址:      http://localhost:3000"
    echo "🏪 客户门户地址:     http://localhost:3002"
    echo "🗄️ 数据库地址:       localhost:5432"
    echo "⚡ Redis地址:       localhost:6379"
    echo ""
    echo "🔑 默认登录凭据:"
    echo "   用户名: admin"
    echo "   密码:   admin123"
    echo ""
    echo "🗄️ 数据库连接信息:"
    echo "   数据库: pet_management"
    echo "   用户:   pet_admin"
    echo "   密码:   pet_secure_password"
    echo ""
}

# 显示服务状态
show_status() {
    echo "📊 服务状态:"
    echo ""
    docker-compose -f docker-compose.yml ps 2>/dev/null || true
    docker-compose -f docker-compose.simple.yml ps 2>/dev/null || true
    echo ""
    echo "🔍 健康检查:"
    echo "简化版后端: $(curl -s http://localhost:8000/health >/dev/null && echo "✅ 正常" || echo "❌ 异常")"
    echo "完整版后端: $(curl -s http://localhost:3000/api/health >/dev/null && echo "✅ 正常" || echo "❌ 异常")"
    echo "前端服务:   $(curl -s http://localhost:3001 >/dev/null && echo "✅ 正常" || echo "❌ 异常")"
}

# 显示日志
show_logs() {
    echo "📋 显示服务日志..."
    if docker-compose -f docker-compose.simple.yml ps | grep -q "pet-"; then
        docker-compose -f docker-compose.simple.yml logs -f
    else
        docker-compose -f docker-compose.yml logs -f
    fi
}

# 停止服务
stop_services() {
    echo "🛑 停止所有服务..."
    docker-compose -f docker-compose.yml down 2>/dev/null || true
    docker-compose -f docker-compose.simple.yml down 2>/dev/null || true
    echo "✅ 所有服务已停止"
}

# 解析命令行参数
MODE=""
BUILD="false"

while [[ $# -gt 0 ]]; do
    case $1 in
        simple|full|dev)
            MODE=$1
            shift
            ;;
        --build)
            BUILD="true"
            shift
            ;;
        --clean)
            check_docker
            cleanup
            exit 0
            ;;
        --logs)
            show_logs
            exit 0
            ;;
        --status)
            show_status
            exit 0
            ;;
        --stop)
            stop_services
            exit 0
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo "❌ 未知参数: $1"
            show_help
            exit 1
            ;;
    esac
done

# 如果没有指定模式，显示帮助
if [[ -z "$MODE" ]]; then
    show_help
    exit 0
fi

# 检查Docker环境
check_docker

# 根据模式启动服务
case $MODE in
    simple)
        start_simple
        ;;
    full)
        start_full
        ;;
    dev)
        echo "🔧 开发模式暂未实现"
        exit 1
        ;;
    *)
        echo "❌ 不支持的模式: $MODE"
        show_help
        exit 1
        ;;
esac

echo "🔍 运行 './docker-start.sh --status' 检查服务状态"
echo "📋 运行 './docker-start.sh --logs' 查看服务日志"
echo "🛑 运行 './docker-start.sh --stop' 停止所有服务"
#!/bin/bash

# 宠物管理系统本地启动脚本
set -e

echo "🐾 宠物管理系统本地启动工具"
echo "================================"

# 显示帮助信息
show_help() {
    echo ""
    echo "使用方法："
    echo "  ./local-start.sh [模式] [选项]"
    echo ""
    echo "可用模式："
    echo "  simple      - 启动简化版系统（推荐）"
    echo "  full        - 启动完整版系统（需要 PostgreSQL）"
    echo ""
    echo "选项："
    echo "  --install   - 安装依赖"
    echo "  --build     - 构建前端"
    echo "  --status    - 查看服务状态"
    echo "  --stop      - 停止所有服务"
    echo "  --help      - 显示此帮助信息"
    echo ""
    echo "示例："
    echo "  ./local-start.sh simple         # 启动简化版"
    echo "  ./local-start.sh --install      # 安装依赖"
    echo "  ./local-start.sh --stop         # 停止服务"
    echo ""
}

# 检查 Node.js 环境
check_environment() {
    echo "🔍 检查运行环境..."
    
    # 检查 Node.js
    if ! command -v node &> /dev/null; then
        echo "❌ Node.js 未安装，请安装 Node.js >= 18.0"
        echo "   下载地址：https://nodejs.org/"
        exit 1
    fi
    
    NODE_VERSION=$(node --version | cut -d'v' -f2)
    MAJOR_VERSION=$(echo $NODE_VERSION | cut -d'.' -f1)
    
    if [ "$MAJOR_VERSION" -lt 18 ]; then
        echo "❌ Node.js 版本过低 ($NODE_VERSION)，需要 >= 18.0"
        exit 1
    fi
    
    # 检查 npm
    if ! command -v npm &> /dev/null; then
        echo "❌ npm 未安装"
        exit 1
    fi
    
    echo "✅ Node.js $NODE_VERSION"
    echo "✅ npm $(npm --version)"
}

# 安装依赖
install_dependencies() {
    echo "📦 安装项目依赖..."
    
    # 安装前端依赖
    echo "安装前端依赖..."
    cd pet-frontend
    if [ ! -d "node_modules" ] || [ ! -f "package-lock.json" ]; then
        npm install
    fi
    cd ..
    
    # 安装后端依赖（完整版）
    if [ -f "pet-backend/package.json" ]; then
        echo "安装后端依赖..."
        cd pet-backend
        if [ ! -d "node_modules" ] || [ ! -f "package-lock.json" ]; then
            npm install
        fi
        cd ..
    fi
    
    echo "✅ 依赖安装完成"
}

# 构建前端
build_frontend() {
    echo "🔨 构建前端应用..."
    cd pet-frontend
    
    # 设置环境变量
    export VITE_API_BASE_URL="http://localhost:8000/api"
    export VITE_AUTH_BASE_URL="http://localhost:8000"
    export VITE_OAUTH_CLIENT_ID="web_client_001"
    export VITE_APP_URL="http://localhost:3001"
    
    npm run build
    cd ..
    echo "✅ 前端构建完成"
}

# 检查端口占用
check_ports() {
    local ports=("$@")
    for port in "${ports[@]}"; do
        if lsof -ti:$port >/dev/null 2>&1; then
            echo "⚠️  端口 $port 被占用"
            echo "   使用 'lsof -ti:$port | xargs kill' 来停止占用进程"
            return 1
        fi
    done
    return 0
}

# 启动简化版系统
start_simple() {
    echo "🚀 启动简化版宠物管理系统..."
    
    # 检查端口
    if ! check_ports 8000 3001; then
        echo "❌ 请先停止占用端口的服务"
        exit 1
    fi
    
    # 启动后端
    echo "启动简化版后端 (端口 8000)..."
    node simple-backend.js &
    BACKEND_PID=$!
    echo $BACKEND_PID > .backend.pid
    
    # 等待后端启动
    sleep 3
    
    # 测试后端连接
    if curl -s http://localhost:8000/health >/dev/null; then
        echo "✅ 后端服务启动成功"
    else
        echo "❌ 后端服务启动失败"
        kill $BACKEND_PID 2>/dev/null || true
        exit 1
    fi
    
    # 构建并启动前端
    echo "启动前端服务 (端口 3001)..."
    cd pet-frontend
    
    # 确保 dist 目录存在
    if [ ! -d "dist" ]; then
        echo "构建前端应用..."
        build_frontend
        cd pet-frontend
    fi
    
    npm run preview -- --host &
    FRONTEND_PID=$!
    echo $FRONTEND_PID > ../.frontend.pid
    cd ..
    
    # 等待前端启动
    sleep 5
    
    # 测试前端连接
    if curl -s http://localhost:3001 >/dev/null; then
        echo "✅ 前端服务启动成功"
    else
        echo "❌ 前端服务启动失败"
        kill $FRONTEND_PID $BACKEND_PID 2>/dev/null || true
        exit 1
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
    echo "🛑 运行 './local-start.sh --stop' 停止服务"
    echo "📊 运行 './local-start.sh --status' 查看状态"
    echo ""
}

# 启动完整版系统
start_full() {
    echo "🚀 启动完整版宠物管理系统..."
    echo "⚠️  完整版需要 PostgreSQL 数据库支持"
    
    # 检查 PostgreSQL
    if ! command -v pg_isready &> /dev/null; then
        echo "❌ PostgreSQL 未安装，请安装后再试"
        echo "   macOS: brew install postgresql"
        echo "   Ubuntu: sudo apt install postgresql"
        exit 1
    fi
    
    # 检查端口
    if ! check_ports 3000 3001; then
        echo "❌ 请先停止占用端口的服务"
        exit 1
    fi
    
    # 启动后端
    echo "启动完整版后端 (端口 3000)..."
    cd pet-backend
    npm start &
    BACKEND_PID=$!
    echo $BACKEND_PID > ../.backend-full.pid
    cd ..
    
    # 等待后端启动
    sleep 5
    
    # 启动前端
    echo "启动前端服务 (端口 3001)..."
    cd pet-frontend
    npm run preview -- --host &
    FRONTEND_PID=$!
    echo $FRONTEND_PID > ../.frontend.pid
    cd ..
    
    echo ""
    echo "🎉 完整版系统启动成功！"
    echo ""
    echo "📱 前端访问地址: http://localhost:3001"
    echo "🔌 后端API地址:  http://localhost:3000"
    echo ""
    echo "🔑 默认登录凭据:"
    echo "   用户名: admin"
    echo "   密码:   admin123"
    echo ""
}

# 查看服务状态
show_status() {
    echo "📊 服务状态检查:"
    echo ""
    
    # 检查进程
    if [ -f ".backend.pid" ]; then
        PID=$(cat .backend.pid)
        if ps -p $PID > /dev/null 2>&1; then
            echo "✅ 简化版后端 (PID: $PID) - 运行中"
        else
            echo "❌ 简化版后端 - 已停止"
        fi
    fi
    
    if [ -f ".backend-full.pid" ]; then
        PID=$(cat .backend-full.pid)
        if ps -p $PID > /dev/null 2>&1; then
            echo "✅ 完整版后端 (PID: $PID) - 运行中"
        else
            echo "❌ 完整版后端 - 已停止"
        fi
    fi
    
    if [ -f ".frontend.pid" ]; then
        PID=$(cat .frontend.pid)
        if ps -p $PID > /dev/null 2>&1; then
            echo "✅ 前端服务 (PID: $PID) - 运行中"
        else
            echo "❌ 前端服务 - 已停止"
        fi
    fi
    
    echo ""
    echo "🔍 端口状态:"
    echo "端口 3001 (前端): $(curl -s http://localhost:3001 >/dev/null && echo "✅ 可访问" || echo "❌ 不可访问")"
    echo "端口 8000 (简化版后端): $(curl -s http://localhost:8000/health >/dev/null && echo "✅ 可访问" || echo "❌ 不可访问")"
    echo "端口 3000 (完整版后端): $(curl -s http://localhost:3000/api/health >/dev/null && echo "✅ 可访问" || echo "❌ 不可访问")"
}

# 停止所有服务
stop_services() {
    echo "🛑 停止所有服务..."
    
    # 停止后端进程
    for pid_file in .backend.pid .backend-full.pid .frontend.pid; do
        if [ -f "$pid_file" ]; then
            PID=$(cat $pid_file)
            if ps -p $PID > /dev/null 2>&1; then
                echo "停止进程 $PID..."
                kill $PID
                sleep 2
                # 强制终止
                kill -9 $PID 2>/dev/null || true
            fi
            rm -f $pid_file
        fi
    done
    
    # 清理可能遗留的进程
    pkill -f "simple-backend.js" 2>/dev/null || true
    pkill -f "pet-backend" 2>/dev/null || true
    pkill -f "vite.*preview" 2>/dev/null || true
    
    echo "✅ 所有服务已停止"
}

# 主程序
main() {
    # 解析命令行参数
    case "${1:-help}" in
        simple)
            check_environment
            install_dependencies
            start_simple
            ;;
        full)
            check_environment
            install_dependencies
            start_full
            ;;
        --install)
            check_environment
            install_dependencies
            ;;
        --build)
            check_environment
            build_frontend
            ;;
        --status)
            show_status
            ;;
        --stop)
            stop_services
            ;;
        --help|-h|help)
            show_help
            ;;
        *)
            echo "❌ 未知命令: $1"
            show_help
            exit 1
            ;;
    esac
}

# 捕获退出信号
trap 'echo ""; echo "🛑 收到退出信号，正在停止服务..."; stop_services; exit 0' INT TERM

# 执行主程序
main "$@"
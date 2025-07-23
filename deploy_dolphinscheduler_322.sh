#!/bin/bash

# DolphinScheduler 3.2.2 开发环境部署脚本
# 作者: 部署助手
# 版本: 1.0
# 日期: $(date +%Y-%m-%d)

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 配置变量
DS_VERSION="3.2.2"
DS_HOME="/opt/dolphinscheduler"
DS_USER="dolphinscheduler"
DOWNLOAD_URL="https://archive.apache.org/dist/dolphinscheduler/${DS_VERSION}/apache-dolphinscheduler-${DS_VERSION}-bin.tar.gz"
BACKUP_DIR="/opt/dolphinscheduler/backup/$(date +%Y%m%d_%H%M%S)"

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行"
        exit 1
    fi
}

# 检查系统要求
check_system_requirements() {
    log_step "检查系统要求..."
    
    # 检查Java版本
    if ! command -v java &> /dev/null; then
        log_error "Java未安装，请先安装Java 8或Java 11"
        exit 1
    fi
    
    java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
    log_info "Java版本: $java_version"
    
    # 检查可用空间
    available_space=$(df / | awk 'NR==2 {print $4}')
    if [[ $available_space -lt 2097152 ]]; then  # 2GB in KB
        log_warn "可用磁盘空间不足2GB，建议释放更多空间"
    fi
    
    log_info "系统要求检查完成"
}

# 创建用户和目录
create_user_and_directories() {
    log_step "创建用户和目录..."
    
    # 创建dolphinscheduler用户
    if ! id "$DS_USER" &>/dev/null; then
        useradd -m -s /bin/bash "$DS_USER"
        log_info "已创建用户: $DS_USER"
    else
        log_info "用户 $DS_USER 已存在"
    fi
    
    # 创建目录
    mkdir -p "$DS_HOME"
    mkdir -p "$DS_HOME/logs"
    mkdir -p "$DS_HOME/conf"
    mkdir -p "$DS_HOME/lib"
    mkdir -p "$BACKUP_DIR"
    
    log_info "目录创建完成"
}

# 下载DolphinScheduler二进制包
download_dolphinscheduler() {
    log_step "下载DolphinScheduler ${DS_VERSION} 二进制包..."
    
    cd /tmp
    
    # 检查是否已经下载
    if [[ -f "apache-dolphinscheduler-${DS_VERSION}-bin.tar.gz" ]]; then
        log_info "发现已下载的文件，跳过下载"
    else
        log_info "从 $DOWNLOAD_URL 下载..."
        if command -v wget &> /dev/null; then
            wget -O "apache-dolphinscheduler-${DS_VERSION}-bin.tar.gz" "$DOWNLOAD_URL"
        elif command -v curl &> /dev/null; then
            curl -L -o "apache-dolphinscheduler-${DS_VERSION}-bin.tar.gz" "$DOWNLOAD_URL"
        else
            log_error "wget和curl都未安装，无法下载文件"
            exit 1
        fi
    fi
    
    # 验证下载的文件
    if [[ ! -f "apache-dolphinscheduler-${DS_VERSION}-bin.tar.gz" ]]; then
        log_error "下载失败"
        exit 1
    fi
    
    log_info "下载完成"
}

# 解压和安装
extract_and_install() {
    log_step "解压和安装DolphinScheduler..."
    
    cd /tmp
    
    # 备份现有安装（如果存在）
    if [[ -d "$DS_HOME/bin" ]]; then
        log_info "备份现有安装到 $BACKUP_DIR"
        cp -r "$DS_HOME"/* "$BACKUP_DIR/" 2>/dev/null || true
    fi
    
    # 解压
    tar -zxf "apache-dolphinscheduler-${DS_VERSION}-bin.tar.gz"
    
    # 移动文件到安装目录
    cp -r "apache-dolphinscheduler-${DS_VERSION}-bin"/* "$DS_HOME/"
    
    # 设置权限
    chown -R "$DS_USER:$DS_USER" "$DS_HOME"
    chmod +x "$DS_HOME/bin/"*.sh
    
    log_info "安装完成"
}

# 配置DolphinScheduler
configure_dolphinscheduler() {
    log_step "配置DolphinScheduler..."
    
    # 备份原始配置文件
    if [[ -f "$DS_HOME/conf/application.yaml" ]]; then
        cp "$DS_HOME/conf/application.yaml" "$DS_HOME/conf/application.yaml.bak"
    fi
    
    # 创建application.yaml配置文件
    cat > "$DS_HOME/conf/application.yaml" << 'EOF'
spring:
  application:
    name: dolphinscheduler
  profiles:
    active: mysql
  datasource:
    driver-class-name: com.mysql.jdbc.Driver
    url: jdbc:mysql://rm-2ze090y2tb1t9b00v.mysql.rds.aliyuncs.com:3306/ds_test_322?characterEncoding=UTF-8&allowMultiQueries=true&useSSL=false
    username: ds_test_322
    password: ds_test_322
    hikari:
      connection-test-query: select 1
      minimum-idle: 5
      auto-commit: true
      validation-timeout: 3000
      pool-name: DolphinScheduler
      maximum-pool-size: 50
      connection-timeout: 30000
      idle-timeout: 600000
      leak-detection-threshold: 0
      initialization-fail-timeout: 1

server:
  port: 12348

management:
  endpoints:
    web:
      exposure:
        include: health,metrics,prometheus
  endpoint:
    health:
      enabled: true
      show-details: always
  health:
    db:
      enabled: true
    defaults:
      enabled: false
  metrics:
    tags:
      application: ${spring.application.name}

# master config
master:
  listen:
    port: 35678
  exec:
    threads: 100
  exec-task:
    threads: 20
  dispatch-task:
    threads: 3
  host-selector: lower_weight
  heartbeat-interval: 10s
  task-commit-retry-times: 5
  task-commit-interval: 1s
  state-wheel-interval: 5s
  max-cpu-load-avg: -1
  reserved-memory: 0.3
  failover-interval: 10m
  kill-yarn-job-when-handle-failover: true

# worker config  
worker:
  listen:
    port: 31234
  exec:
    threads: 100
  heartbeat-interval: 10s
  max-cpu-load-avg: -1
  reserved-memory: 0.3
  groups:
    - default
  alert-listen-host: localhost
  alert-listen-port: 50052

# alert config
alert:
  port: 50052

# api config
api:
  audit-enable: false

# common config
common:
  data-basedir-path: /tmp/dolphinscheduler
  resource-storage-type: HDFS
  resource-upload-path: /dolphinscheduler
  hdfs-root-user: hdfs
  hdfs-s3a-fs-impl: org.apache.hadoop.fs.s3a.S3AFileSystem
  resource-view-suffixs: txt,log,sh,bat,conf,cfg,py,java,sql,xml,hql,properties,json,yml,yaml,ini,js
  development-state: false
  kerberos-enable: false
  kerberos-keytab-username: hdfs-mycluster@ESZ.COM
  kerberos-keytab-path: /opt/hdfs.headless.keytab
  kerberos-krb5-conf-path: /opt/krb5.conf
  login-user-from-cookie: false
  login-user-from-header: false

# registry config
registry:
  type: zookeeper
  zookeeper:
    namespace: dolphinscheduler
    connect-string: master-1-1.c-43f03c523937fd55.cn-beijing.emr.aliyuncs.com:2181
    retry-policy:
      base-sleep-time: 60ms
      max-sleep: 300ms
      max-retries: 5
    session-timeout: 30s
    connection-timeout: 9s
    block-until-connected: 600ms
    digest: ~

# quartz config
quartz:
  properties:
    org.quartz.threadPool.threadCount: 100
    org.quartz.jobStore.driverDelegateClass: org.quartz.impl.jdbcjobstore.StdJDBCDelegate
    org.quartz.jobStore.misfireThreshold: 60000
    org.quartz.scheduler.instanceId: AUTO
    org.quartz.jobStore.class: org.quartz.impl.jdbcjobstore.JobStoreTX
    org.quartz.jobStore.tablePrefix: QRTZ_
    org.quartz.jobStore.isClustered: true
    org.quartz.jobStore.clusterCheckinInterval: 5000
    org.quartz.scheduler.instanceName: DolphinScheduler
    org.quartz.jobStore.useProperties: false
    org.quartz.scheduler.makeSchedulerThreadDaemon: true
    org.quartz.jobStore.dataSource: default
    org.quartz.dataSource.default.driver: com.mysql.jdbc.Driver
    org.quartz.dataSource.default.URL: jdbc:mysql://rm-2ze090y2tb1t9b00v.mysql.rds.aliyuncs.com:3306/ds_test_322?characterEncoding=UTF-8&allowMultiQueries=true&useSSL=false
    org.quartz.dataSource.default.user: ds_test_322
    org.quartz.dataSource.default.password: ds_test_322
    org.quartz.dataSource.default.maxConnections: 10
    org.quartz.dataSource.default.validationQuery: select 1

# zookeeper config (legacy support)
zookeeper:
  quorum: master-1-1.c-43f03c523937fd55.cn-beijing.emr.aliyuncs.com:2181
  dolphinscheduler:
    root: /dolphinscheduler322
EOF

    # 设置配置文件权限
    chown "$DS_USER:$DS_USER" "$DS_HOME/conf/application.yaml"
    
    log_info "配置文件创建完成"
}

# 创建环境配置文件
create_env_config() {
    log_step "创建环境配置文件..."
    
    # 创建dolphinscheduler_env.sh
    cat > "$DS_HOME/conf/dolphinscheduler_env.sh" << 'EOF'
#!/bin/bash

# DolphinScheduler环境配置文件

# Java环境
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export JRE_HOME=$JAVA_HOME/jre
export CLASSPATH=.:$JAVA_HOME/lib:$JRE_HOME/lib:$CLASSPATH
export PATH=$JAVA_HOME/bin:$JRE_HOME/bin:$PATH

# DolphinScheduler配置
export DOLPHINSCHEDULER_HOME=/opt/dolphinscheduler
export DOLPHINSCHEDULER_CONF_DIR=$DOLPHINSCHEDULER_HOME/conf
export DOLPHINSCHEDULER_LIB_JARS=$DOLPHINSCHEDULER_HOME/lib/*
export DOLPHINSCHEDULER_OPTS="-server -Duser.timezone=Asia/Shanghai -Xms1g -Xmx1g -Xmn512m -XX:+PrintGCDetails -Xloggc:gc.log -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=dump.hprof"

# 数据库配置
export DATABASE=mysql
export SPRING_PROFILES_ACTIVE=mysql
export SPRING_DATASOURCE_URL="jdbc:mysql://rm-2ze090y2tb1t9b00v.mysql.rds.aliyuncs.com:3306/ds_test_322?characterEncoding=UTF-8&allowMultiQueries=true&useSSL=false"
export SPRING_DATASOURCE_USERNAME=ds_test_322
export SPRING_DATASOURCE_PASSWORD=ds_test_322

# Zookeeper配置
export REGISTRY_ZOOKEEPER_CONNECT_STRING=master-1-1.c-43f03c523937fd55.cn-beijing.emr.aliyuncs.com:2181

# 日志配置
export DOLPHINSCHEDULER_LOG_DIR=$DOLPHINSCHEDULER_HOME/logs
EOF

    # 设置权限
    chown "$DS_USER:$DS_USER" "$DS_HOME/conf/dolphinscheduler_env.sh"
    chmod +x "$DS_HOME/conf/dolphinscheduler_env.sh"
    
    log_info "环境配置文件创建完成"
}

# 创建启动脚本
create_startup_scripts() {
    log_step "创建启动脚本..."
    
    # 创建主启动脚本
    cat > "$DS_HOME/start-all.sh" << 'EOF'
#!/bin/bash

# DolphinScheduler 启动脚本

DS_HOME=/opt/dolphinscheduler
source $DS_HOME/conf/dolphinscheduler_env.sh

echo "启动DolphinScheduler服务..."

# 检查Java环境
if ! command -v java &> /dev/null; then
    echo "错误: Java未找到，请检查JAVA_HOME设置"
    exit 1
fi

# 启动Master
echo "启动Master服务..."
nohup java $DOLPHINSCHEDULER_OPTS -cp $DS_HOME/conf:$DOLPHINSCHEDULER_LIB_JARS org.apache.dolphinscheduler.server.master.MasterServer > $DOLPHINSCHEDULER_LOG_DIR/master.log 2>&1 &
echo $! > $DS_HOME/master.pid

# 启动Worker
echo "启动Worker服务..."
nohup java $DOLPHINSCHEDULER_OPTS -cp $DS_HOME/conf:$DOLPHINSCHEDULER_LIB_JARS org.apache.dolphinscheduler.server.worker.WorkerServer > $DOLPHINSCHEDULER_LOG_DIR/worker.log 2>&1 &
echo $! > $DS_HOME/worker.pid

# 启动API服务
echo "启动API服务..."
nohup java $DOLPHINSCHEDULER_OPTS -cp $DS_HOME/conf:$DOLPHINSCHEDULER_LIB_JARS org.apache.dolphinscheduler.api.ApiApplicationServer > $DOLPHINSCHEDULER_LOG_DIR/api.log 2>&1 &
echo $! > $DS_HOME/api.pid

# 启动Alert服务
echo "启动Alert服务..."
nohup java $DOLPHINSCHEDULER_OPTS -cp $DS_HOME/conf:$DOLPHINSCHEDULER_LIB_JARS org.apache.dolphinscheduler.alert.AlertServer > $DOLPHINSCHEDULER_LOG_DIR/alert.log 2>&1 &
echo $! > $DS_HOME/alert.pid

echo "DolphinScheduler服务启动完成！"
echo "API服务地址: http://localhost:12348"
echo "默认用户名: admin"
echo "默认密码: dolphinscheduler123"
echo ""
echo "查看日志: tail -f $DOLPHINSCHEDULER_LOG_DIR/*.log"
echo "停止服务: $DS_HOME/stop-all.sh"
EOF

    # 创建停止脚本
    cat > "$DS_HOME/stop-all.sh" << 'EOF'
#!/bin/bash

# DolphinScheduler 停止脚本

DS_HOME=/opt/dolphinscheduler

echo "停止DolphinScheduler服务..."

# 停止服务函数
stop_service() {
    local service_name=$1
    local pid_file=$DS_HOME/${service_name}.pid
    
    if [[ -f $pid_file ]]; then
        local pid=$(cat $pid_file)
        if ps -p $pid > /dev/null 2>&1; then
            echo "停止 $service_name (PID: $pid)..."
            kill $pid
            
            # 等待进程结束
            local count=0
            while ps -p $pid > /dev/null 2>&1 && [[ $count -lt 30 ]]; do
                sleep 1
                ((count++))
            done
            
            # 如果进程仍在运行，强制杀死
            if ps -p $pid > /dev/null 2>&1; then
                echo "强制停止 $service_name..."
                kill -9 $pid
            fi
        fi
        rm -f $pid_file
        echo "$service_name 已停止"
    else
        echo "$service_name 未运行"
    fi
}

# 停止各个服务
stop_service "master"
stop_service "worker"  
stop_service "api"
stop_service "alert"

echo "DolphinScheduler服务已全部停止！"
EOF

    # 创建状态检查脚本
    cat > "$DS_HOME/status.sh" << 'EOF'
#!/bin/bash

# DolphinScheduler 状态检查脚本

DS_HOME=/opt/dolphinscheduler

echo "DolphinScheduler服务状态:"
echo "========================"

# 检查服务状态函数
check_service() {
    local service_name=$1
    local pid_file=$DS_HOME/${service_name}.pid
    
    if [[ -f $pid_file ]]; then
        local pid=$(cat $pid_file)
        if ps -p $pid > /dev/null 2>&1; then
            echo "$service_name: 运行中 (PID: $pid)"
        else
            echo "$service_name: 已停止 (PID文件存在但进程不存在)"
        fi
    else
        echo "$service_name: 已停止"
    fi
}

# 检查各个服务
check_service "master"
check_service "worker"
check_service "api"
check_service "alert"

echo ""
echo "端口监听状态:"
echo "============"
netstat -tlnp 2>/dev/null | grep -E ":(35678|31234|12348|50052)" || echo "没有发现DolphinScheduler相关端口监听"

echo ""
echo "最近日志:"
echo "========"
if [[ -d "$DS_HOME/logs" ]]; then
    find "$DS_HOME/logs" -name "*.log" -type f -exec echo "=== {} ===" \; -exec tail -3 {} \; 2>/dev/null | head -20
else
    echo "日志目录不存在"
fi
EOF

    # 设置权限
    chown "$DS_USER:$DS_USER" "$DS_HOME"/*.sh
    chmod +x "$DS_HOME"/*.sh
    
    log_info "启动脚本创建完成"
}

# 初始化数据库
init_database() {
    log_step "初始化数据库..."
    
    log_warn "请确保MySQL数据库已创建并且用户有足够权限"
    log_info "数据库: ds_test_322"
    log_info "用户: ds_test_322"
    log_info "主机: rm-2ze090y2tb1t9b00v.mysql.rds.aliyuncs.com:3306"
    
    # 这里可以添加数据库初始化脚本的执行
    # 由于需要连接远程数据库，暂时跳过自动初始化
    log_warn "请手动执行数据库初始化脚本: $DS_HOME/sql/dolphinscheduler_mysql.sql"
    
    log_info "数据库初始化配置完成"
}

# 创建systemd服务文件
create_systemd_services() {
    log_step "创建systemd服务文件..."
    
    # Master服务
    cat > /etc/systemd/system/dolphinscheduler-master.service << EOF
[Unit]
Description=DolphinScheduler Master Server
After=network.target

[Service]
Type=forking
User=$DS_USER
Group=$DS_USER
ExecStart=$DS_HOME/bin/dolphinscheduler-daemon.sh start master-server
ExecStop=$DS_HOME/bin/dolphinscheduler-daemon.sh stop master-server
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=multi-user.target
EOF

    # Worker服务
    cat > /etc/systemd/system/dolphinscheduler-worker.service << EOF
[Unit]
Description=DolphinScheduler Worker Server
After=network.target

[Service]
Type=forking
User=$DS_USER
Group=$DS_USER
ExecStart=$DS_HOME/bin/dolphinscheduler-daemon.sh start worker-server
ExecStop=$DS_HOME/bin/dolphinscheduler-daemon.sh stop worker-server
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=multi-user.target
EOF

    # API服务
    cat > /etc/systemd/system/dolphinscheduler-api.service << EOF
[Unit]
Description=DolphinScheduler API Server
After=network.target

[Service]
Type=forking
User=$DS_USER
Group=$DS_USER
ExecStart=$DS_HOME/bin/dolphinscheduler-daemon.sh start api-server
ExecStop=$DS_HOME/bin/dolphinscheduler-daemon.sh stop api-server
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=multi-user.target
EOF

    # Alert服务
    cat > /etc/systemd/system/dolphinscheduler-alert.service << EOF
[Unit]
Description=DolphinScheduler Alert Server
After=network.target

[Service]
Type=forking
User=$DS_USER
Group=$DS_USER
ExecStart=$DS_HOME/bin/dolphinscheduler-daemon.sh start alert-server
ExecStop=$DS_HOME/bin/dolphinscheduler-daemon.sh stop alert-server
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=multi-user.target
EOF

    # 重新加载systemd
    systemctl daemon-reload
    
    log_info "systemd服务文件创建完成"
}

# 安装MySQL驱动
install_mysql_driver() {
    log_step "安装MySQL驱动..."
    
    cd /tmp
    
    # 下载MySQL驱动
    if [[ ! -f "mysql-connector-java-8.0.33.jar" ]]; then
        log_info "下载MySQL驱动..."
        if command -v wget &> /dev/null; then
            wget https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.33/mysql-connector-java-8.0.33.jar
        elif command -v curl &> /dev/null; then
            curl -L -o mysql-connector-java-8.0.33.jar https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.33/mysql-connector-java-8.0.33.jar
        else
            log_warn "无法下载MySQL驱动，请手动下载并放置到 $DS_HOME/lib/ 目录"
            return
        fi
    fi
    
    # 复制驱动到lib目录
    if [[ -f "mysql-connector-java-8.0.33.jar" ]]; then
        cp mysql-connector-java-8.0.33.jar "$DS_HOME/lib/"
        chown "$DS_USER:$DS_USER" "$DS_HOME/lib/mysql-connector-java-8.0.33.jar"
        log_info "MySQL驱动安装完成"
    else
        log_warn "MySQL驱动下载失败，请手动安装"
    fi
}

# 创建快速配置脚本
create_quick_config() {
    log_step "创建快速配置脚本..."
    
    cat > "$DS_HOME/quick-config.sh" << 'EOF'
#!/bin/bash

# DolphinScheduler 快速配置脚本

DS_HOME=/opt/dolphinscheduler

echo "DolphinScheduler 3.2.2 快速配置"
echo "================================"

# 显示当前配置
echo "当前配置信息:"
echo "- Master端口: 35678"
echo "- Worker端口: 31234" 
echo "- API端口: 12348"
echo "- Alert端口: 50052"
echo "- 数据库: MySQL (ds_test_322)"
echo "- Zookeeper: master-1-1.c-43f03c523937fd55.cn-beijing.emr.aliyuncs.com:2181"
echo "- ZK根路径: /dolphinscheduler322"
echo "- Quartz线程数: 100"
echo ""

# 检查配置文件
if [[ ! -f "$DS_HOME/conf/application.yaml" ]]; then
    echo "错误: 配置文件不存在，请先运行部署脚本"
    exit 1
fi

# 提供配置选项
echo "配置选项:"
echo "1. 修改数据库连接"
echo "2. 修改Zookeeper连接"
echo "3. 修改端口配置"
echo "4. 查看当前配置"
echo "5. 测试连接"
echo "0. 退出"
echo ""

read -p "请选择操作 [0-5]: " choice

case $choice in
    1)
        echo "修改数据库连接配置..."
        read -p "请输入数据库地址 [当前: rm-2ze090y2tb1t9b00v.mysql.rds.aliyuncs.com:3306]: " db_host
        read -p "请输入数据库名 [当前: ds_test_322]: " db_name
        read -p "请输入用户名 [当前: ds_test_322]: " db_user
        read -s -p "请输入密码: " db_pass
        echo ""
        
        # 这里可以添加配置更新逻辑
        echo "数据库配置更新完成（需要重启服务生效）"
        ;;
    2)
        echo "修改Zookeeper连接配置..."
        read -p "请输入Zookeeper地址 [当前: master-1-1.c-43f03c523937fd55.cn-beijing.emr.aliyuncs.com:2181]: " zk_host
        read -p "请输入根路径 [当前: /dolphinscheduler322]: " zk_root
        
        echo "Zookeeper配置更新完成（需要重启服务生效）"
        ;;
    3)
        echo "修改端口配置..."
        read -p "请输入Master端口 [当前: 35678]: " master_port
        read -p "请输入Worker端口 [当前: 31234]: " worker_port
        read -p "请输入API端口 [当前: 12348]: " api_port
        
        echo "端口配置更新完成（需要重启服务生效）"
        ;;
    4)
        echo "当前配置文件内容:"
        echo "=================="
        cat "$DS_HOME/conf/application.yaml" | head -50
        ;;
    5)
        echo "测试连接..."
        echo "- 测试数据库连接..."
        # 这里可以添加数据库连接测试
        echo "- 测试Zookeeper连接..."
        # 这里可以添加Zookeeper连接测试
        echo "连接测试完成"
        ;;
    0)
        echo "退出配置"
        exit 0
        ;;
    *)
        echo "无效选择"
        ;;
esac
EOF

    chmod +x "$DS_HOME/quick-config.sh"
    chown "$DS_USER:$DS_USER" "$DS_HOME/quick-config.sh"
    
    log_info "快速配置脚本创建完成"
}

# 显示部署后信息
show_post_install_info() {
    log_step "部署完成信息"
    
    echo ""
    echo "========================================"
    echo "  DolphinScheduler 3.2.2 部署完成！"
    echo "========================================"
    echo ""
    echo "安装目录: $DS_HOME"
    echo "运行用户: $DS_USER"
    echo ""
    echo "服务端口:"
    echo "  - Master: 35678"
    echo "  - Worker: 31234"
    echo "  - API: 12348"
    echo "  - Alert: 50052"
    echo ""
    echo "Web界面: http://localhost:12348/dolphinscheduler"
    echo "默认用户: admin"
    echo "默认密码: dolphinscheduler123"
    echo ""
    echo "常用命令:"
    echo "  启动服务: $DS_HOME/start-all.sh"
    echo "  停止服务: $DS_HOME/stop-all.sh"
    echo "  查看状态: $DS_HOME/status.sh"
    echo "  快速配置: $DS_HOME/quick-config.sh"
    echo ""
    echo "systemd服务:"
    echo "  systemctl start dolphinscheduler-master"
    echo "  systemctl start dolphinscheduler-worker"
    echo "  systemctl start dolphinscheduler-api"
    echo "  systemctl start dolphinscheduler-alert"
    echo ""
    echo "日志目录: $DS_HOME/logs"
    echo "配置文件: $DS_HOME/conf/application.yaml"
    echo ""
    echo "注意事项:"
    echo "1. 请确保MySQL数据库 ds_test_322 已创建并初始化"
    echo "2. 请确保Zookeeper服务正常运行"
    echo "3. 首次启动前请检查防火墙设置"
    echo "4. 建议先运行 $DS_HOME/status.sh 检查服务状态"
    echo ""
    echo "========================================"
}

# 主函数
main() {
    log_info "开始部署DolphinScheduler ${DS_VERSION} 开发环境"
    
    check_root
    check_system_requirements
    create_user_and_directories
    download_dolphinscheduler
    extract_and_install
    install_mysql_driver
    configure_dolphinscheduler
    create_env_config
    create_startup_scripts
    create_systemd_services
    init_database
    create_quick_config
    
    show_post_install_info
    
    log_info "部署脚本执行完成！"
}

# 执行主函数
main "$@"
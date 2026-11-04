#!/bin/bash

# DolphinScheduler 3.2.2 快速部署脚本
# 整合数据库初始化和系统部署

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# 显示欢迎信息
show_welcome() {
    clear
    echo "========================================"
    echo "  DolphinScheduler 3.2.2 快速部署工具"
    echo "========================================"
    echo ""
    echo "本脚本将自动完成以下操作："
    echo "1. 环境检查和准备"
    echo "2. 数据库初始化"
    echo "3. DolphinScheduler安装和配置"
    echo "4. 服务启动和验证"
    echo ""
    echo "请确保以下条件已满足："
    echo "- 系统为Linux，有root权限"
    echo "- 已安装Java 8或Java 11"
    echo "- MySQL数据库可访问"
    echo "- Zookeeper服务正常运行"
    echo "- 网络连接正常"
    echo ""
    read -p "是否继续部署？[y/N]: " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_info "部署已取消"
        exit 0
    fi
}

# 检查脚本权限
check_permissions() {
    if [[ $EUID -ne 0 ]]; then
        log_error "此脚本需要root权限运行"
        log_info "请使用: sudo $0"
        exit 1
    fi
}

# 检查必要的命令
check_commands() {
    log_step "检查系统命令..."
    
    local commands=("java" "wget" "curl" "tar" "mysql")
    local missing_commands=()
    
    for cmd in "${commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        log_error "缺少以下必要命令: ${missing_commands[*]}"
        log_info "请先安装缺少的软件包"
        exit 1
    fi
    
    log_info "系统命令检查完成"
}

# 收集配置信息
collect_config() {
    log_step "收集配置信息..."
    
    echo ""
    echo "请输入数据库配置信息："
    
    # 数据库配置
    read -p "MySQL主机地址 [默认: rm-2ze090y2tb1t9b00v.mysql.rds.aliyuncs.com]: " DB_HOST
    DB_HOST=${DB_HOST:-"rm-2ze090y2tb1t9b00v.mysql.rds.aliyuncs.com"}
    
    read -p "MySQL端口 [默认: 3306]: " DB_PORT
    DB_PORT=${DB_PORT:-"3306"}
    
    read -p "数据库名 [默认: ds_test_322]: " DB_NAME
    DB_NAME=${DB_NAME:-"ds_test_322"}
    
    read -p "数据库用户名 [默认: ds_test_322]: " DB_USER
    DB_USER=${DB_USER:-"ds_test_322"}
    
    read -s -p "数据库密码 [默认: ds_test_322]: " DB_PASS
    DB_PASS=${DB_PASS:-"ds_test_322"}
    echo ""
    
    echo ""
    echo "请输入Zookeeper配置信息："
    
    read -p "Zookeeper地址 [默认: master-1-1.c-43f03c523937fd55.cn-beijing.emr.aliyuncs.com:2181]: " ZK_HOST
    ZK_HOST=${ZK_HOST:-"master-1-1.c-43f03c523937fd55.cn-beijing.emr.aliyuncs.com:2181"}
    
    read -p "Zookeeper根路径 [默认: /dolphinscheduler322]: " ZK_ROOT
    ZK_ROOT=${ZK_ROOT:-"/dolphinscheduler322"}
    
    echo ""
    echo "请输入服务端口配置："
    
    read -p "Master端口 [默认: 35678]: " MASTER_PORT
    MASTER_PORT=${MASTER_PORT:-"35678"}
    
    read -p "Worker端口 [默认: 31234]: " WORKER_PORT
    WORKER_PORT=${WORKER_PORT:-"31234"}
    
    read -p "API端口 [默认: 12348]: " API_PORT
    API_PORT=${API_PORT:-"12348"}
    
    read -p "Alert端口 [默认: 50052]: " ALERT_PORT
    ALERT_PORT=${ALERT_PORT:-"50052"}
    
    read -p "Quartz线程数 [默认: 100]: " QUARTZ_THREADS
    QUARTZ_THREADS=${QUARTZ_THREADS:-"100"}
    
    # 显示配置摘要
    echo ""
    echo "配置摘要："
    echo "=========="
    echo "数据库: $DB_HOST:$DB_PORT/$DB_NAME"
    echo "Zookeeper: $ZK_HOST"
    echo "Master端口: $MASTER_PORT"
    echo "Worker端口: $WORKER_PORT"
    echo "API端口: $API_PORT"
    echo "Alert端口: $ALERT_PORT"
    echo ""
    
    read -p "配置是否正确？[y/N]: " config_confirm
    if [[ ! "$config_confirm" =~ ^[Yy]$ ]]; then
        log_info "请重新运行脚本修改配置"
        exit 0
    fi
    
    # 导出配置变量
    export DB_HOST DB_PORT DB_NAME DB_USER DB_PASS
    export ZK_HOST ZK_ROOT
    export MASTER_PORT WORKER_PORT API_PORT ALERT_PORT QUARTZ_THREADS
}

# 测试外部依赖
test_dependencies() {
    log_step "测试外部依赖..."
    
    # 测试数据库连接
    log_info "测试数据库连接..."
    if mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" -e "SELECT 1;" >/dev/null 2>&1; then
        log_info "数据库连接成功"
    else
        log_error "数据库连接失败，请检查配置"
        exit 1
    fi
    
    # 测试网络连接（下载测试）
    log_info "测试网络连接..."
    if wget --spider --quiet https://archive.apache.org/dist/dolphinscheduler/3.2.2/apache-dolphinscheduler-3.2.2-bin.tar.gz; then
        log_info "网络连接正常"
    else
        log_warn "无法访问Apache下载服务器，可能影响安装包下载"
    fi
    
    log_info "依赖测试完成"
}

# 初始化数据库
init_database() {
    log_step "初始化数据库..."
    
    # 创建临时初始化脚本
    cat > /tmp/init_db_temp.sh << EOF
#!/bin/bash
set -e

# 检查数据库是否存在
if ! mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" -e "USE $DB_NAME;" >/dev/null 2>&1; then
    echo "创建数据库 $DB_NAME..."
    mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" -e "CREATE DATABASE IF NOT EXISTS $DB_NAME DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;"
fi

# 创建初始化SQL
cat > /tmp/dolphinscheduler_init.sql << 'EOSQL'
-- DolphinScheduler 3.2.2 数据库初始化脚本
SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));

-- 用户表
DROP TABLE IF EXISTS t_ds_user;
CREATE TABLE t_ds_user (
  id int(11) NOT NULL AUTO_INCREMENT,
  user_name varchar(64) DEFAULT NULL,
  user_password varchar(64) DEFAULT NULL,
  user_type tinyint(4) DEFAULT NULL,
  email varchar(64) DEFAULT NULL,
  phone varchar(11) DEFAULT NULL,
  tenant_id int(11) DEFAULT NULL,
  create_time datetime DEFAULT NULL,
  update_time datetime DEFAULT NULL,
  queue varchar(64) DEFAULT NULL,
  state tinyint(4) DEFAULT '1',
  time_zone varchar(32) DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY user_name_unique (user_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 租户表
DROP TABLE IF EXISTS t_ds_tenant;
CREATE TABLE t_ds_tenant (
  id int(11) NOT NULL AUTO_INCREMENT,
  tenant_code varchar(64) DEFAULT NULL,
  description varchar(255) DEFAULT NULL,
  queue_id int(11) DEFAULT NULL,
  create_time datetime DEFAULT NULL,
  update_time datetime DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY tenant_code_unique (tenant_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 队列表
DROP TABLE IF EXISTS t_ds_queue;
CREATE TABLE t_ds_queue (
  id int(11) NOT NULL AUTO_INCREMENT,
  queue_name varchar(64) DEFAULT NULL,
  queue varchar(64) DEFAULT NULL,
  create_time datetime DEFAULT NULL,
  update_time datetime DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY queue_name_unique (queue_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 插入初始数据
INSERT INTO t_ds_tenant VALUES ('1', 'default', 'default tenant', '1', '2021-01-01 00:00:00', '2021-01-01 00:00:00');
INSERT INTO t_ds_queue VALUES ('1', 'default', 'default', '2021-01-01 00:00:00', '2021-01-01 00:00:00');
INSERT INTO t_ds_user VALUES ('1', 'admin', '7ad2410b2f4c074479a8937a28a22b8f', '0', 'admin@dolphinscheduler.org', '', '1', '2021-01-01 00:00:00', '2021-01-01 00:00:00', 'default', '1', 'Asia/Shanghai');

-- Quartz表（简化版）
DROP TABLE IF EXISTS QRTZ_JOB_DETAILS;
CREATE TABLE QRTZ_JOB_DETAILS(
SCHED_NAME VARCHAR(120) NOT NULL,
JOB_NAME VARCHAR(200) NOT NULL,
JOB_GROUP VARCHAR(200) NOT NULL,
DESCRIPTION VARCHAR(250) NULL,
JOB_CLASS_NAME VARCHAR(250) NOT NULL,
IS_DURABLE VARCHAR(1) NOT NULL,
IS_NONCONCURRENT VARCHAR(1) NOT NULL,
IS_UPDATE_DATA VARCHAR(1) NOT NULL,
REQUESTS_RECOVERY VARCHAR(1) NOT NULL,
JOB_DATA BLOB NULL,
PRIMARY KEY (SCHED_NAME,JOB_NAME,JOB_GROUP))
ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS QRTZ_TRIGGERS;
CREATE TABLE QRTZ_TRIGGERS (
SCHED_NAME VARCHAR(120) NOT NULL,
TRIGGER_NAME VARCHAR(200) NOT NULL,
TRIGGER_GROUP VARCHAR(200) NOT NULL,
JOB_NAME VARCHAR(200) NOT NULL,
JOB_GROUP VARCHAR(200) NOT NULL,
DESCRIPTION VARCHAR(250) NULL,
NEXT_FIRE_TIME BIGINT(13) NULL,
PREV_FIRE_TIME BIGINT(13) NULL,
PRIORITY INTEGER NULL,
TRIGGER_STATE VARCHAR(16) NOT NULL,
TRIGGER_TYPE VARCHAR(8) NOT NULL,
START_TIME BIGINT(13) NOT NULL,
END_TIME BIGINT(13) NULL,
CALENDAR_NAME VARCHAR(200) NULL,
MISFIRE_INSTR SMALLINT(2) NULL,
JOB_DATA BLOB NULL,
PRIMARY KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP))
ENGINE=InnoDB DEFAULT CHARSET=utf8;
EOSQL

# 执行初始化
mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" < /tmp/dolphinscheduler_init.sql
echo "数据库初始化完成"
EOF

    chmod +x /tmp/init_db_temp.sh
    bash /tmp/init_db_temp.sh
    rm -f /tmp/init_db_temp.sh /tmp/dolphinscheduler_init.sql
    
    log_info "数据库初始化完成"
}

# 部署DolphinScheduler
deploy_dolphinscheduler() {
    log_step "部署DolphinScheduler..."
    
    # 创建用户和目录
    if ! id "dolphinscheduler" &>/dev/null; then
        useradd -m -s /bin/bash dolphinscheduler
        log_info "已创建用户: dolphinscheduler"
    fi
    
    # 创建目录
    mkdir -p /opt/dolphinscheduler/{logs,conf,lib}
    
    # 下载安装包
    cd /tmp
    if [[ ! -f "apache-dolphinscheduler-3.2.2-bin.tar.gz" ]]; then
        log_info "下载DolphinScheduler 3.2.2..."
        wget -O "apache-dolphinscheduler-3.2.2-bin.tar.gz" "https://archive.apache.org/dist/dolphinscheduler/3.2.2/apache-dolphinscheduler-3.2.2-bin.tar.gz" || {
            log_error "下载失败，请检查网络连接"
            exit 1
        }
    fi
    
    # 解压安装
    tar -zxf "apache-dolphinscheduler-3.2.2-bin.tar.gz"
    cp -r "apache-dolphinscheduler-3.2.2-bin"/* /opt/dolphinscheduler/
    
    # 下载MySQL驱动
    if [[ ! -f "/opt/dolphinscheduler/lib/mysql-connector-java-8.0.33.jar" ]]; then
        log_info "下载MySQL驱动..."
        wget -O /opt/dolphinscheduler/lib/mysql-connector-java-8.0.33.jar https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.33/mysql-connector-java-8.0.33.jar
    fi
    
    # 设置权限
    chown -R dolphinscheduler:dolphinscheduler /opt/dolphinscheduler
    chmod +x /opt/dolphinscheduler/bin/*.sh
    
    log_info "DolphinScheduler安装完成"
}

# 生成配置文件
generate_config() {
    log_step "生成配置文件..."
    
    # 生成application.yaml
    cat > /opt/dolphinscheduler/conf/application.yaml << EOF
spring:
  application:
    name: dolphinscheduler
  profiles:
    active: mysql
  datasource:
    driver-class-name: com.mysql.jdbc.Driver
    url: jdbc:mysql://$DB_HOST:$DB_PORT/$DB_NAME?characterEncoding=UTF-8&allowMultiQueries=true&useSSL=false
    username: $DB_USER
    password: $DB_PASS

server:
  port: $API_PORT

master:
  listen:
    port: $MASTER_PORT
  exec:
    threads: 100

worker:
  listen:
    port: $WORKER_PORT
  exec:
    threads: 100

alert:
  port: $ALERT_PORT

registry:
  type: zookeeper
  zookeeper:
    namespace: dolphinscheduler
    connect-string: $ZK_HOST

quartz:
  properties:
    org.quartz.threadPool.threadCount: $QUARTZ_THREADS
    org.quartz.dataSource.default.driver: com.mysql.jdbc.Driver
    org.quartz.dataSource.default.URL: jdbc:mysql://$DB_HOST:$DB_PORT/$DB_NAME?characterEncoding=UTF-8&allowMultiQueries=true&useSSL=false
    org.quartz.dataSource.default.user: $DB_USER
    org.quartz.dataSource.default.password: $DB_PASS

zookeeper:
  quorum: $ZK_HOST
  dolphinscheduler:
    root: $ZK_ROOT
EOF

    # 生成环境配置
    cat > /opt/dolphinscheduler/conf/dolphinscheduler_env.sh << 'EOF'
#!/bin/bash
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
export DOLPHINSCHEDULER_HOME=/opt/dolphinscheduler
export DOLPHINSCHEDULER_CONF_DIR=$DOLPHINSCHEDULER_HOME/conf
export DOLPHINSCHEDULER_LIB_JARS=$DOLPHINSCHEDULER_HOME/lib/*
export DOLPHINSCHEDULER_OPTS="-server -Duser.timezone=Asia/Shanghai -Xms1g -Xmx1g -Xmn512m"
export DOLPHINSCHEDULER_LOG_DIR=$DOLPHINSCHEDULER_HOME/logs
EOF

    # 生成启动脚本
    cat > /opt/dolphinscheduler/start-all.sh << 'EOF'
#!/bin/bash
DS_HOME=/opt/dolphinscheduler
source $DS_HOME/conf/dolphinscheduler_env.sh

echo "启动DolphinScheduler服务..."

# 启动Master
nohup java $DOLPHINSCHEDULER_OPTS -cp $DS_HOME/conf:$DOLPHINSCHEDULER_LIB_JARS org.apache.dolphinscheduler.server.master.MasterServer > $DOLPHINSCHEDULER_LOG_DIR/master.log 2>&1 &
echo $! > $DS_HOME/master.pid

# 启动Worker  
nohup java $DOLPHINSCHEDULER_OPTS -cp $DS_HOME/conf:$DOLPHINSCHEDULER_LIB_JARS org.apache.dolphinscheduler.server.worker.WorkerServer > $DOLPHINSCHEDULER_LOG_DIR/worker.log 2>&1 &
echo $! > $DS_HOME/worker.pid

# 启动API
nohup java $DOLPHINSCHEDULER_OPTS -cp $DS_HOME/conf:$DOLPHINSCHEDULER_LIB_JARS org.apache.dolphinscheduler.api.ApiApplicationServer > $DOLPHINSCHEDULER_LOG_DIR/api.log 2>&1 &
echo $! > $DS_HOME/api.pid

# 启动Alert
nohup java $DOLPHINSCHEDULER_OPTS -cp $DS_HOME/conf:$DOLPHINSCHEDULER_LIB_JARS org.apache.dolphinscheduler.alert.AlertServer > $DOLPHINSCHEDULER_LOG_DIR/alert.log 2>&1 &
echo $! > $DS_HOME/alert.pid

echo "DolphinScheduler服务启动完成！"
echo "Web界面: http://localhost:$API_PORT/dolphinscheduler"
echo "用户名: admin, 密码: dolphinscheduler123"
EOF

    # 设置权限
    chown -R dolphinscheduler:dolphinscheduler /opt/dolphinscheduler/conf
    chmod +x /opt/dolphinscheduler/conf/dolphinscheduler_env.sh
    chmod +x /opt/dolphinscheduler/start-all.sh
    
    log_info "配置文件生成完成"
}

# 启动服务
start_services() {
    log_step "启动服务..."
    
    # 等待一下让系统准备好
    sleep 2
    
    # 以dolphinscheduler用户启动服务
    sudo -u dolphinscheduler /opt/dolphinscheduler/start-all.sh
    
    # 等待服务启动
    log_info "等待服务启动..."
    sleep 10
    
    log_info "服务启动完成"
}

# 验证部署
verify_deployment() {
    log_step "验证部署..."
    
    # 检查进程
    local processes=("master" "worker" "api" "alert")
    local running_count=0
    
    for process in "${processes[@]}"; do
        if [[ -f "/opt/dolphinscheduler/${process}.pid" ]]; then
            local pid=$(cat "/opt/dolphinscheduler/${process}.pid")
            if ps -p "$pid" > /dev/null 2>&1; then
                log_info "$process 服务运行中 (PID: $pid)"
                ((running_count++))
            else
                log_warn "$process 服务未运行"
            fi
        else
            log_warn "$process PID文件不存在"
        fi
    done
    
    # 检查端口
    local ports=("$MASTER_PORT" "$WORKER_PORT" "$API_PORT" "$ALERT_PORT")
    local listening_count=0
    
    for port in "${ports[@]}"; do
        if netstat -tlnp 2>/dev/null | grep ":$port " > /dev/null; then
            log_info "端口 $port 正在监听"
            ((listening_count++))
        else
            log_warn "端口 $port 未监听"
        fi
    done
    
    # 验证结果
    if [[ $running_count -eq 4 && $listening_count -eq 4 ]]; then
        log_info "部署验证成功！"
        return 0
    else
        log_warn "部署验证部分失败，请检查日志"
        return 1
    fi
}

# 显示部署结果
show_result() {
    echo ""
    echo "========================================"
    echo "  DolphinScheduler 3.2.2 部署完成！"
    echo "========================================"
    echo ""
    echo "服务信息："
    echo "  安装目录: /opt/dolphinscheduler"
    echo "  运行用户: dolphinscheduler"
    echo "  Web界面: http://localhost:$API_PORT/dolphinscheduler"
    echo "  默认用户: admin"
    echo "  默认密码: dolphinscheduler123"
    echo ""
    echo "服务端口："
    echo "  Master: $MASTER_PORT"
    echo "  Worker: $WORKER_PORT"
    echo "  API: $API_PORT"
    echo "  Alert: $ALERT_PORT"
    echo ""
    echo "常用命令："
    echo "  启动服务: sudo -u dolphinscheduler /opt/dolphinscheduler/start-all.sh"
    echo "  查看日志: tail -f /opt/dolphinscheduler/logs/*.log"
    echo ""
    echo "配置文件："
    echo "  主配置: /opt/dolphinscheduler/conf/application.yaml"
    echo "  环境配置: /opt/dolphinscheduler/conf/dolphinscheduler_env.sh"
    echo ""
    echo "========================================"
}

# 清理临时文件
cleanup() {
    log_step "清理临时文件..."
    rm -f /tmp/apache-dolphinscheduler-3.2.2-bin.tar.gz
    rm -rf /tmp/apache-dolphinscheduler-3.2.2-bin
    log_info "清理完成"
}

# 主函数
main() {
    show_welcome
    check_permissions
    check_commands
    collect_config
    test_dependencies
    init_database
    deploy_dolphinscheduler
    generate_config
    start_services
    
    if verify_deployment; then
        show_result
    else
        echo ""
        log_warn "部署可能存在问题，请检查以下日志："
        echo "  /opt/dolphinscheduler/logs/master.log"
        echo "  /opt/dolphinscheduler/logs/worker.log"
        echo "  /opt/dolphinscheduler/logs/api.log"
        echo "  /opt/dolphinscheduler/logs/alert.log"
    fi
    
    cleanup
    log_info "快速部署脚本执行完成！"
}

# 捕获错误并清理
trap cleanup EXIT

# 执行主函数
main "$@"
#!/bin/bash

# DolphinScheduler 3.2.2 数据库初始化脚本

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

# 数据库配置
DB_HOST="rm-2ze090y2tb1t9b00v.mysql.rds.aliyuncs.com"
DB_PORT="3306"
DB_NAME="ds_test_322"
DB_USER="ds_test_322"
DB_PASS="ds_test_322"
DS_HOME="/opt/dolphinscheduler"

# 检查MySQL客户端
check_mysql_client() {
    log_step "检查MySQL客户端..."
    
    if ! command -v mysql &> /dev/null; then
        log_error "MySQL客户端未安装"
        log_info "请安装MySQL客户端："
        log_info "Ubuntu/Debian: apt-get install mysql-client"
        log_info "CentOS/RHEL: yum install mysql"
        exit 1
    fi
    
    log_info "MySQL客户端检查完成"
}

# 测试数据库连接
test_database_connection() {
    log_step "测试数据库连接..."
    
    if mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" -e "SELECT 1;" >/dev/null 2>&1; then
        log_info "数据库连接成功"
    else
        log_error "数据库连接失败"
        log_info "请检查以下配置："
        log_info "主机: $DB_HOST:$DB_PORT"
        log_info "数据库: $DB_NAME"
        log_info "用户: $DB_USER"
        exit 1
    fi
}

# 检查数据库是否存在
check_database_exists() {
    log_step "检查数据库是否存在..."
    
    if mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" -e "USE $DB_NAME;" >/dev/null 2>&1; then
        log_info "数据库 $DB_NAME 已存在"
        return 0
    else
        log_warn "数据库 $DB_NAME 不存在"
        return 1
    fi
}

# 创建数据库
create_database() {
    log_step "创建数据库..."
    
    mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" << EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
EOF
    
    log_info "数据库 $DB_NAME 创建完成"
}

# 下载数据库初始化脚本
download_sql_scripts() {
    log_step "准备数据库初始化脚本..."
    
    # 创建临时目录
    mkdir -p /tmp/dolphinscheduler_sql
    cd /tmp/dolphinscheduler_sql
    
    # 创建DolphinScheduler 3.2.2的数据库初始化脚本
    cat > dolphinscheduler_mysql.sql << 'EOF'
-- DolphinScheduler 3.2.2 MySQL数据库初始化脚本

SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));

-- 创建用户表
DROP TABLE IF EXISTS `t_ds_user`;
CREATE TABLE `t_ds_user` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '用户id',
  `user_name` varchar(64) DEFAULT NULL COMMENT '用户名',
  `user_password` varchar(64) DEFAULT NULL COMMENT '用户密码',
  `user_type` tinyint(4) DEFAULT NULL COMMENT '用户类型：0管理员，1普通用户',
  `email` varchar(64) DEFAULT NULL COMMENT '邮箱',
  `phone` varchar(11) DEFAULT NULL COMMENT '手机',
  `tenant_id` int(11) DEFAULT NULL COMMENT '租户id',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `queue` varchar(64) DEFAULT NULL COMMENT '队列',
  `state` tinyint(4) DEFAULT '1' COMMENT '状态 0:停用 1:启用',
  `time_zone` varchar(32) DEFAULT NULL COMMENT '时区',
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_name_unique` (`user_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 创建租户表
DROP TABLE IF EXISTS `t_ds_tenant`;
CREATE TABLE `t_ds_tenant` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '租户id',
  `tenant_code` varchar(64) DEFAULT NULL COMMENT '租户编码',
  `description` varchar(255) DEFAULT NULL COMMENT '描述',
  `queue_id` int(11) DEFAULT NULL COMMENT '队列id',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `tenant_code_unique` (`tenant_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 创建队列表
DROP TABLE IF EXISTS `t_ds_queue`;
CREATE TABLE `t_ds_queue` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '队列id',
  `queue_name` varchar(64) DEFAULT NULL COMMENT '队列名称',
  `queue` varchar(64) DEFAULT NULL COMMENT '队列值',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `queue_name_unique` (`queue_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 创建项目表
DROP TABLE IF EXISTS `t_ds_project`;
CREATE TABLE `t_ds_project` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '项目id',
  `name` varchar(100) DEFAULT NULL COMMENT '项目名称',
  `code` bigint(20) NOT NULL COMMENT '项目编码',
  `description` varchar(255) DEFAULT NULL COMMENT '项目描述',
  `user_id` int(11) DEFAULT NULL COMMENT '所属用户',
  `flag` tinyint(4) DEFAULT '1' COMMENT '是否删除',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_name` (`name`),
  UNIQUE KEY `unique_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 创建工作流定义表
DROP TABLE IF EXISTS `t_ds_process_definition`;
CREATE TABLE `t_ds_process_definition` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `code` bigint(20) NOT NULL COMMENT '编码',
  `name` varchar(255) DEFAULT NULL COMMENT '流程定义名称',
  `version` int(11) NOT NULL DEFAULT '1' COMMENT '流程定义版本',
  `description` text COMMENT '流程定义描述',
  `project_code` bigint(20) NOT NULL COMMENT '项目编码',
  `release_state` tinyint(4) DEFAULT NULL COMMENT '流程定义发布状态：0 未上线  1已上线',
  `user_id` int(11) DEFAULT NULL COMMENT '流程定义所属用户id',
  `global_params` text COMMENT '全局参数',
  `flag` tinyint(4) DEFAULT NULL COMMENT '流程是否可用：0 不可用，1 可用',
  `locations` text COMMENT '节点坐标信息',
  `warning_group_id` int(11) DEFAULT NULL COMMENT '告警组id',
  `timeout` int(11) DEFAULT '0' COMMENT '超时时间',
  `tenant_id` int(11) NOT NULL DEFAULT '-1' COMMENT '租户id',
  `execution_type` tinyint(4) DEFAULT '0' COMMENT '流程执行类型：0 并行，1 串行等待，2 串行抛弃',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`,`code`),
  UNIQUE KEY `process_unique` (`name`,`project_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 创建任务定义表
DROP TABLE IF EXISTS `t_ds_task_definition`;
CREATE TABLE `t_ds_task_definition` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `code` bigint(20) NOT NULL COMMENT '任务编码',
  `name` varchar(200) DEFAULT NULL COMMENT '任务名称',
  `version` int(11) NOT NULL DEFAULT '1' COMMENT '任务版本',
  `description` text COMMENT '任务描述',
  `project_code` bigint(20) NOT NULL COMMENT '项目编码',
  `user_id` int(11) DEFAULT NULL COMMENT '任务所属用户id',
  `task_type` varchar(50) NOT NULL COMMENT '任务类型',
  `task_execute_type` int(11) DEFAULT '0' COMMENT '任务执行类型',
  `task_params` longtext COMMENT '任务参数',
  `flag` tinyint(4) DEFAULT NULL COMMENT '任务是否可用：0 不可用，1 可用',
  `is_cache` tinyint(4) DEFAULT '0' COMMENT '是否缓存：0 不缓存，1 缓存',
  `task_priority` tinyint(4) DEFAULT '2' COMMENT '任务优先级',
  `worker_group` varchar(200) DEFAULT NULL COMMENT 'worker分组',
  `environment_code` bigint(20) DEFAULT '-1' COMMENT '环境编码',
  `fail_retry_times` int(11) DEFAULT NULL COMMENT '失败重试次数',
  `fail_retry_interval` int(11) DEFAULT NULL COMMENT '失败重试间隔',
  `timeout_flag` tinyint(4) DEFAULT '0' COMMENT '是否超时告警',
  `timeout_notify_strategy` tinyint(4) DEFAULT NULL COMMENT '超时告警策略',
  `timeout` int(11) DEFAULT '0' COMMENT '超时时长',
  `delay_time` int(11) DEFAULT '0' COMMENT '延迟执行时间',
  `resource_ids` text COMMENT '资源ids',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`,`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 创建数据源表
DROP TABLE IF EXISTS `t_ds_datasource`;
CREATE TABLE `t_ds_datasource` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` varchar(64) NOT NULL COMMENT '数据源名称',
  `note` varchar(255) DEFAULT NULL COMMENT '数据源描述',
  `type` tinyint(4) NOT NULL COMMENT '数据源类型',
  `user_id` int(11) NOT NULL COMMENT '创建用户id',
  `connection_params` text NOT NULL COMMENT '连接参数',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `t_ds_datasource_name_un` (`name`,`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 创建资源表
DROP TABLE IF EXISTS `t_ds_resources`;
CREATE TABLE `t_ds_resources` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `alias` varchar(64) DEFAULT NULL COMMENT '别名',
  `file_name` varchar(64) DEFAULT NULL COMMENT '文件名',
  `description` varchar(255) DEFAULT NULL COMMENT '描述',
  `user_id` int(11) DEFAULT NULL COMMENT '用户id',
  `type` tinyint(4) DEFAULT NULL COMMENT '资源类型',
  `size` bigint(20) DEFAULT NULL COMMENT '资源大小',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `pid` int(11) DEFAULT NULL COMMENT '父级id',
  `full_name` varchar(128) DEFAULT NULL COMMENT '全名',
  `is_directory` tinyint(4) DEFAULT NULL COMMENT '是否为目录',
  PRIMARY KEY (`id`),
  UNIQUE KEY `t_ds_resources_un` (`full_name`,`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 创建告警组表
DROP TABLE IF EXISTS `t_ds_alertgroup`;
CREATE TABLE `t_ds_alertgroup` (
  `id` int(11) NOT NULL AUTO_INCREMENT COMMENT '告警组id',
  `alert_instance_ids` varchar(255) DEFAULT NULL COMMENT '告警实例ids',
  `create_user_id` int(11) DEFAULT NULL COMMENT '创建用户id',
  `group_name` varchar(255) DEFAULT NULL COMMENT '组名称',
  `description` varchar(255) DEFAULT NULL COMMENT '描述',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `t_ds_alertgroup_name_un` (`group_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 创建环境表
DROP TABLE IF EXISTS `t_ds_environment`;
CREATE TABLE `t_ds_environment` (
  `id` bigint(11) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `code` bigint(20) DEFAULT NULL COMMENT '编码',
  `name` varchar(100) NOT NULL COMMENT '环境名称',
  `config` text DEFAULT NULL COMMENT '配置信息',
  `description` text DEFAULT NULL COMMENT '描述',
  `operator` int(11) DEFAULT NULL COMMENT '操作人',
  `create_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `environment_name_unique` (`name`),
  UNIQUE KEY `environment_code_unique` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 创建集群表
DROP TABLE IF EXISTS `t_ds_cluster`;
CREATE TABLE `t_ds_cluster` (
  `id` bigint(11) NOT NULL AUTO_INCREMENT COMMENT '主键',
  `code` bigint(20) DEFAULT NULL COMMENT '编码',
  `name` varchar(100) NOT NULL COMMENT '集群名称',
  `config` text DEFAULT NULL COMMENT '配置信息',
  `description` text DEFAULT NULL COMMENT '描述',
  `operator` int(11) DEFAULT NULL COMMENT '操作人',
  `create_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `cluster_name_unique` (`name`),
  UNIQUE KEY `cluster_code_unique` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- 插入初始数据

-- 插入默认租户
INSERT INTO `t_ds_tenant` VALUES ('1', 'default', 'default tenant', '1', '2021-01-01 00:00:00', '2021-01-01 00:00:00');

-- 插入默认队列
INSERT INTO `t_ds_queue` VALUES ('1', 'default', 'default', '2021-01-01 00:00:00', '2021-01-01 00:00:00');

-- 插入管理员用户 (密码: dolphinscheduler123)
INSERT INTO `t_ds_user` VALUES ('1', 'admin', '7ad2410b2f4c074479a8937a28a22b8f', '0', 'admin@dolphinscheduler.org', '', '1', '2021-01-01 00:00:00', '2021-01-01 00:00:00', 'default', '1', 'Asia/Shanghai');

-- 插入默认告警组
INSERT INTO `t_ds_alertgroup` VALUES ('1', '', '1', 'default admin warning group', 'default admin warning group', '2021-01-01 00:00:00', '2021-01-01 00:00:00');

-- 创建Quartz相关表
DROP TABLE IF EXISTS QRTZ_FIRED_TRIGGERS;
DROP TABLE IF EXISTS QRTZ_PAUSED_TRIGGER_GRPS;
DROP TABLE IF EXISTS QRTZ_SCHEDULER_STATE;
DROP TABLE IF EXISTS QRTZ_LOCKS;
DROP TABLE IF EXISTS QRTZ_SIMPLE_TRIGGERS;
DROP TABLE IF EXISTS QRTZ_SIMPROP_TRIGGERS;
DROP TABLE IF EXISTS QRTZ_CRON_TRIGGERS;
DROP TABLE IF EXISTS QRTZ_BLOB_TRIGGERS;
DROP TABLE IF EXISTS QRTZ_TRIGGERS;
DROP TABLE IF EXISTS QRTZ_JOB_DETAILS;
DROP TABLE IF EXISTS QRTZ_CALENDARS;

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
PRIMARY KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP),
FOREIGN KEY (SCHED_NAME,JOB_NAME,JOB_GROUP)
REFERENCES QRTZ_JOB_DETAILS(SCHED_NAME,JOB_NAME,JOB_GROUP))
ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE QRTZ_SIMPLE_TRIGGERS (
SCHED_NAME VARCHAR(120) NOT NULL,
TRIGGER_NAME VARCHAR(200) NOT NULL,
TRIGGER_GROUP VARCHAR(200) NOT NULL,
REPEAT_COUNT BIGINT(7) NOT NULL,
REPEAT_INTERVAL BIGINT(12) NOT NULL,
TIMES_TRIGGERED BIGINT(10) NOT NULL,
PRIMARY KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP),
FOREIGN KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
REFERENCES QRTZ_TRIGGERS(SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP))
ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE QRTZ_CRON_TRIGGERS (
SCHED_NAME VARCHAR(120) NOT NULL,
TRIGGER_NAME VARCHAR(200) NOT NULL,
TRIGGER_GROUP VARCHAR(200) NOT NULL,
CRON_EXPRESSION VARCHAR(120) NOT NULL,
TIME_ZONE_ID VARCHAR(80),
PRIMARY KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP),
FOREIGN KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
REFERENCES QRTZ_TRIGGERS(SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP))
ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE QRTZ_SIMPROP_TRIGGERS
  (          
    SCHED_NAME VARCHAR(120) NOT NULL,
    TRIGGER_NAME VARCHAR(200) NOT NULL,
    TRIGGER_GROUP VARCHAR(200) NOT NULL,
    STR_PROP_1 VARCHAR(512) NULL,
    STR_PROP_2 VARCHAR(512) NULL,
    STR_PROP_3 VARCHAR(512) NULL,
    INT_PROP_1 INT NULL,
    INT_PROP_2 INT NULL,
    LONG_PROP_1 BIGINT NULL,
    LONG_PROP_2 BIGINT NULL,
    DEC_PROP_1 NUMERIC(13,4) NULL,
    DEC_PROP_2 NUMERIC(13,4) NULL,
    BOOL_PROP_1 VARCHAR(1) NULL,
    BOOL_PROP_2 VARCHAR(1) NULL,
    PRIMARY KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP),
    FOREIGN KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP) 
    REFERENCES QRTZ_TRIGGERS(SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP))
ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE QRTZ_BLOB_TRIGGERS (
SCHED_NAME VARCHAR(120) NOT NULL,
TRIGGER_NAME VARCHAR(200) NOT NULL,
TRIGGER_GROUP VARCHAR(200) NOT NULL,
BLOB_DATA BLOB NULL,
PRIMARY KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP),
INDEX (SCHED_NAME,TRIGGER_NAME, TRIGGER_GROUP),
FOREIGN KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
REFERENCES QRTZ_TRIGGERS(SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP))
ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE QRTZ_CALENDARS (
SCHED_NAME VARCHAR(120) NOT NULL,
CALENDAR_NAME VARCHAR(200) NOT NULL,
CALENDAR BLOB NOT NULL,
PRIMARY KEY (SCHED_NAME,CALENDAR_NAME))
ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE QRTZ_PAUSED_TRIGGER_GRPS (
SCHED_NAME VARCHAR(120) NOT NULL,
TRIGGER_GROUP VARCHAR(200) NOT NULL,
PRIMARY KEY (SCHED_NAME,TRIGGER_GROUP))
ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE QRTZ_FIRED_TRIGGERS (
SCHED_NAME VARCHAR(120) NOT NULL,
ENTRY_ID VARCHAR(95) NOT NULL,
TRIGGER_NAME VARCHAR(200) NOT NULL,
TRIGGER_GROUP VARCHAR(200) NOT NULL,
INSTANCE_NAME VARCHAR(200) NOT NULL,
FIRED_TIME BIGINT(13) NOT NULL,
SCHED_TIME BIGINT(13) NOT NULL,
PRIORITY INTEGER NOT NULL,
STATE VARCHAR(16) NOT NULL,
JOB_NAME VARCHAR(200) NULL,
JOB_GROUP VARCHAR(200) NULL,
IS_NONCONCURRENT VARCHAR(1) NULL,
REQUESTS_RECOVERY VARCHAR(1) NULL,
PRIMARY KEY (SCHED_NAME,ENTRY_ID))
ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE QRTZ_SCHEDULER_STATE (
SCHED_NAME VARCHAR(120) NOT NULL,
INSTANCE_NAME VARCHAR(200) NOT NULL,
LAST_CHECKIN_TIME BIGINT(13) NOT NULL,
CHECKIN_INTERVAL BIGINT(13) NOT NULL,
PRIMARY KEY (SCHED_NAME,INSTANCE_NAME))
ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE QRTZ_LOCKS (
SCHED_NAME VARCHAR(120) NOT NULL,
LOCK_NAME VARCHAR(40) NOT NULL,
PRIMARY KEY (SCHED_NAME,LOCK_NAME))
ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE INDEX IDX_QRTZ_J_REQ_RECOVERY ON QRTZ_JOB_DETAILS(SCHED_NAME,REQUESTS_RECOVERY);
CREATE INDEX IDX_QRTZ_J_GRP ON QRTZ_JOB_DETAILS(SCHED_NAME,JOB_GROUP);

CREATE INDEX IDX_QRTZ_T_J ON QRTZ_TRIGGERS(SCHED_NAME,JOB_NAME,JOB_GROUP);
CREATE INDEX IDX_QRTZ_T_JG ON QRTZ_TRIGGERS(SCHED_NAME,JOB_GROUP);
CREATE INDEX IDX_QRTZ_T_C ON QRTZ_TRIGGERS(SCHED_NAME,CALENDAR_NAME);
CREATE INDEX IDX_QRTZ_T_G ON QRTZ_TRIGGERS(SCHED_NAME,TRIGGER_GROUP);
CREATE INDEX IDX_QRTZ_T_STATE ON QRTZ_TRIGGERS(SCHED_NAME,TRIGGER_STATE);
CREATE INDEX IDX_QRTZ_T_N_STATE ON QRTZ_TRIGGERS(SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP,TRIGGER_STATE);
CREATE INDEX IDX_QRTZ_T_N_G_STATE ON QRTZ_TRIGGERS(SCHED_NAME,TRIGGER_GROUP,TRIGGER_STATE);
CREATE INDEX IDX_QRTZ_T_NEXT_FIRE_TIME ON QRTZ_TRIGGERS(SCHED_NAME,NEXT_FIRE_TIME);
CREATE INDEX IDX_QRTZ_T_NFT_ST ON QRTZ_TRIGGERS(SCHED_NAME,TRIGGER_STATE,NEXT_FIRE_TIME);
CREATE INDEX IDX_QRTZ_T_NFT_MISFIRE ON QRTZ_TRIGGERS(SCHED_NAME,MISFIRE_INSTR,NEXT_FIRE_TIME);
CREATE INDEX IDX_QRTZ_T_NFT_ST_MISFIRE ON QRTZ_TRIGGERS(SCHED_NAME,MISFIRE_INSTR,NEXT_FIRE_TIME,TRIGGER_STATE);
CREATE INDEX IDX_QRTZ_T_NFT_ST_MISFIRE_GRP ON QRTZ_TRIGGERS(SCHED_NAME,MISFIRE_INSTR,NEXT_FIRE_TIME,TRIGGER_GROUP,TRIGGER_STATE);

CREATE INDEX IDX_QRTZ_FT_TRIG_INST_NAME ON QRTZ_FIRED_TRIGGERS(SCHED_NAME,INSTANCE_NAME);
CREATE INDEX IDX_QRTZ_FT_INST_JOB_REQ_RCVRY ON QRTZ_FIRED_TRIGGERS(SCHED_NAME,INSTANCE_NAME,REQUESTS_RECOVERY);
CREATE INDEX IDX_QRTZ_FT_J_G ON QRTZ_FIRED_TRIGGERS(SCHED_NAME,JOB_NAME,JOB_GROUP);
CREATE INDEX IDX_QRTZ_FT_JG ON QRTZ_FIRED_TRIGGERS(SCHED_NAME,JOB_GROUP);
CREATE INDEX IDX_QRTZ_FT_T_G ON QRTZ_FIRED_TRIGGERS(SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP);
CREATE INDEX IDX_QRTZ_FT_TG ON QRTZ_FIRED_TRIGGERS(SCHED_NAME,TRIGGER_GROUP);

EOF

    log_info "数据库初始化脚本准备完成"
}

# 执行数据库初始化
execute_sql_scripts() {
    log_step "执行数据库初始化..."
    
    # 执行初始化脚本
    if mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" < dolphinscheduler_mysql.sql; then
        log_info "数据库初始化成功"
    else
        log_error "数据库初始化失败"
        exit 1
    fi
}

# 验证数据库初始化
verify_database() {
    log_step "验证数据库初始化..."
    
    # 检查关键表是否存在
    tables=(
        "t_ds_user"
        "t_ds_tenant"
        "t_ds_queue"
        "t_ds_project"
        "t_ds_process_definition"
        "t_ds_task_definition"
        "QRTZ_JOB_DETAILS"
        "QRTZ_TRIGGERS"
    )
    
    for table in "${tables[@]}"; do
        if mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "DESC $table;" >/dev/null 2>&1; then
            log_info "表 $table 创建成功"
        else
            log_error "表 $table 创建失败"
            exit 1
        fi
    done
    
    # 检查初始数据
    user_count=$(mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -se "SELECT COUNT(*) FROM t_ds_user WHERE user_name='admin';")
    if [[ "$user_count" == "1" ]]; then
        log_info "管理员用户创建成功"
    else
        log_error "管理员用户创建失败"
        exit 1
    fi
    
    log_info "数据库验证完成"
}

# 显示初始化结果
show_result() {
    log_step "数据库初始化完成"
    
    echo ""
    echo "========================================"
    echo "  数据库初始化完成！"
    echo "========================================"
    echo ""
    echo "数据库信息:"
    echo "  主机: $DB_HOST:$DB_PORT"
    echo "  数据库: $DB_NAME"
    echo "  用户: $DB_USER"
    echo ""
    echo "默认管理员账户:"
    echo "  用户名: admin"
    echo "  密码: dolphinscheduler123"
    echo ""
    echo "数据库表统计:"
    mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
    SELECT 
        TABLE_NAME as '表名',
        TABLE_ROWS as '记录数',
        ROUND(DATA_LENGTH/1024/1024,2) as '数据大小(MB)'
    FROM information_schema.TABLES 
    WHERE TABLE_SCHEMA='$DB_NAME' 
    ORDER BY TABLE_NAME;
    " 2>/dev/null || echo "无法获取表统计信息"
    
    echo ""
    echo "现在可以启动DolphinScheduler服务了！"
    echo "========================================"
}

# 主函数
main() {
    log_info "开始初始化DolphinScheduler数据库"
    
    check_mysql_client
    test_database_connection
    
    if ! check_database_exists; then
        create_database
    fi
    
    download_sql_scripts
    execute_sql_scripts
    verify_database
    show_result
    
    # 清理临时文件
    rm -rf /tmp/dolphinscheduler_sql
    
    log_info "数据库初始化脚本执行完成！"
}

# 执行主函数
main "$@"
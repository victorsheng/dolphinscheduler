# DolphinScheduler 3.2.2 开发环境部署指南

本指南提供了完整的DolphinScheduler 3.2.2开发环境部署脚本和说明。

## 📋 目录

- [系统要求](#系统要求)
- [部署步骤](#部署步骤)
- [配置说明](#配置说明)
- [启动服务](#启动服务)
- [常见问题](#常见问题)
- [维护操作](#维护操作)

## 🔧 系统要求

### 硬件要求
- CPU: 2核心及以上
- 内存: 4GB及以上
- 磁盘: 20GB可用空间
- 网络: 能够访问外网下载依赖包

### 软件要求
- 操作系统: Linux (Ubuntu 18.04+, CentOS 7+)
- Java: JDK 8 或 JDK 11
- MySQL: 5.7+ 或 8.0+
- Zookeeper: 3.4.6+

### 外部依赖
- MySQL数据库服务器
- Zookeeper集群
- 网络连接（用于下载安装包）

## 🚀 部署步骤

### 第一步：准备环境

1. **安装Java环境**
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install openjdk-8-jdk

# CentOS/RHEL
sudo yum install java-1.8.0-openjdk java-1.8.0-openjdk-devel
```

2. **安装MySQL客户端**
```bash
# Ubuntu/Debian
sudo apt-get install mysql-client

# CentOS/RHEL
sudo yum install mysql
```

3. **验证环境**
```bash
java -version
mysql --version
```

### 第二步：下载部署脚本

```bash
# 下载主部署脚本
curl -O https://your-server/deploy_dolphinscheduler_322.sh
chmod +x deploy_dolphinscheduler_322.sh

# 下载数据库初始化脚本
curl -O https://your-server/init_database.sh
chmod +x init_database.sh
```

### 第三步：初始化数据库

```bash
# 以root权限运行数据库初始化脚本
sudo ./init_database.sh
```

这个脚本会：
- 检查MySQL客户端
- 测试数据库连接
- 创建数据库（如果不存在）
- 创建所有必要的表结构
- 插入初始数据
- 验证初始化结果

### 第四步：部署DolphinScheduler

```bash
# 以root权限运行主部署脚本
sudo ./deploy_dolphinscheduler_322.sh
```

这个脚本会自动完成：
- 系统要求检查
- 创建用户和目录
- 下载DolphinScheduler 3.2.2二进制包
- 解压和安装
- 配置系统
- 创建启动脚本
- 设置systemd服务

## ⚙️ 配置说明

### 主要配置文件

1. **应用配置**: `/opt/dolphinscheduler/conf/application.yaml`
2. **环境配置**: `/opt/dolphinscheduler/conf/dolphinscheduler_env.sh`

### 关键配置项

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| master.listen.port | 35678 | Master服务端口 |
| worker.listen.port | 31234 | Worker服务端口 |
| server.port | 12348 | API服务端口 |
| alert.port | 50052 | Alert服务端口 |
| org.quartz.threadPool.threadCount | 100 | Quartz线程池大小 |

### 数据库配置

```yaml
spring:
  datasource:
    driver-class-name: com.mysql.jdbc.Driver
    url: jdbc:mysql://rm-2ze090y2tb1t9b00v.mysql.rds.aliyuncs.com:3306/ds_test_322?characterEncoding=UTF-8&allowMultiQueries=true&useSSL=false
    username: ds_test_322
    password: ds_test_322
```

### Zookeeper配置

```yaml
registry:
  zookeeper:
    connect-string: master-1-1.c-43f03c523937fd55.cn-beijing.emr.aliyuncs.com:2181
    namespace: dolphinscheduler

zookeeper:
  quorum: master-1-1.c-43f03c523937fd55.cn-beijing.emr.aliyuncs.com:2181
  dolphinscheduler:
    root: /dolphinscheduler322
```

## 🎯 启动服务

### 方式一：使用自定义脚本

```bash
# 启动所有服务
sudo -u dolphinscheduler /opt/dolphinscheduler/start-all.sh

# 停止所有服务
sudo -u dolphinscheduler /opt/dolphinscheduler/stop-all.sh

# 查看服务状态
sudo -u dolphinscheduler /opt/dolphinscheduler/status.sh
```

### 方式二：使用systemd服务

```bash
# 启动单个服务
sudo systemctl start dolphinscheduler-master
sudo systemctl start dolphinscheduler-worker
sudo systemctl start dolphinscheduler-api
sudo systemctl start dolphinscheduler-alert

# 设置开机自启
sudo systemctl enable dolphinscheduler-master
sudo systemctl enable dolphinscheduler-worker
sudo systemctl enable dolphinscheduler-api
sudo systemctl enable dolphinscheduler-alert

# 查看服务状态
sudo systemctl status dolphinscheduler-master
```

### 访问Web界面

部署完成后，可以通过以下地址访问：

- **Web界面**: http://localhost:12348/dolphinscheduler
- **默认用户名**: admin
- **默认密码**: dolphinscheduler123

## 🔍 常见问题

### Q1: 服务启动失败

**检查步骤**:
1. 查看日志文件: `/opt/dolphinscheduler/logs/*.log`
2. 检查端口是否被占用: `netstat -tlnp | grep -E "35678|31234|12348|50052"`
3. 验证Java环境: `java -version`
4. 检查数据库连接: `mysql -h<host> -u<user> -p<password>`

### Q2: 数据库连接失败

**解决方案**:
1. 确认数据库服务正常运行
2. 检查网络连接和防火墙设置
3. 验证数据库用户权限
4. 确认数据库URL、用户名、密码正确

### Q3: Zookeeper连接失败

**解决方案**:
1. 确认Zookeeper服务正常运行
2. 检查网络连接
3. 验证Zookeeper地址和端口
4. 确认防火墙设置

### Q4: 权限问题

**解决方案**:
```bash
# 修复文件权限
sudo chown -R dolphinscheduler:dolphinscheduler /opt/dolphinscheduler
sudo chmod +x /opt/dolphinscheduler/bin/*.sh
sudo chmod +x /opt/dolphinscheduler/*.sh
```

## 🛠️ 维护操作

### 日志管理

```bash
# 查看实时日志
tail -f /opt/dolphinscheduler/logs/master.log
tail -f /opt/dolphinscheduler/logs/worker.log
tail -f /opt/dolphinscheduler/logs/api.log
tail -f /opt/dolphinscheduler/logs/alert.log

# 清理日志
find /opt/dolphinscheduler/logs -name "*.log" -mtime +7 -delete
```

### 配置修改

```bash
# 使用快速配置工具
sudo -u dolphinscheduler /opt/dolphinscheduler/quick-config.sh

# 手动编辑配置文件
sudo -u dolphinscheduler vi /opt/dolphinscheduler/conf/application.yaml

# 重启服务使配置生效
sudo -u dolphinscheduler /opt/dolphinscheduler/stop-all.sh
sudo -u dolphinscheduler /opt/dolphinscheduler/start-all.sh
```

### 备份和恢复

```bash
# 备份配置文件
sudo cp -r /opt/dolphinscheduler/conf /opt/dolphinscheduler/backup/conf_$(date +%Y%m%d)

# 备份数据库
mysqldump -h rm-2ze090y2tb1t9b00v.mysql.rds.aliyuncs.com -u ds_test_322 -p ds_test_322 > dolphinscheduler_backup_$(date +%Y%m%d).sql
```

### 性能调优

1. **JVM参数调优** (编辑 `/opt/dolphinscheduler/conf/dolphinscheduler_env.sh`)
```bash
export DOLPHINSCHEDULER_OPTS="-server -Duser.timezone=Asia/Shanghai -Xms2g -Xmx2g -Xmn1g -XX:+PrintGCDetails -Xloggc:gc.log -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=dump.hprof"
```

2. **数据库连接池调优**
```yaml
spring:
  datasource:
    hikari:
      minimum-idle: 10
      maximum-pool-size: 100
      connection-timeout: 30000
      idle-timeout: 600000
```

3. **Quartz线程池调优**
```yaml
quartz:
  properties:
    org.quartz.threadPool.threadCount: 200
```

## 📞 技术支持

如果遇到问题，请按以下顺序排查：

1. 查看部署日志和服务日志
2. 检查系统资源使用情况
3. 验证网络连接和防火墙设置
4. 确认外部依赖服务状态
5. 参考官方文档和社区资源

## 📝 版本信息

- **DolphinScheduler版本**: 3.2.2
- **支持的Java版本**: JDK 8, JDK 11
- **支持的MySQL版本**: 5.7+, 8.0+
- **部署脚本版本**: 1.0
- **最后更新**: 2024年

---

**注意**: 本部署脚本适用于开发和测试环境。生产环境部署请参考官方文档进行额外的安全配置和性能优化。
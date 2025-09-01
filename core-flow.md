# DolphinScheduler 源码学习核心流程

## 环境搭建

### 1. 获取源码
```bash
# 克隆官方仓库
git clone https://github.com/apache/dolphinscheduler.git
cd dolphinscheduler

# 查看项目结构
ls -la
```

### 2. 环境要求检查
```bash
# 检查 Java 版本 (需要 JDK 8+)
java -version

# 检查 Maven 版本 (需要 3.6+)
mvn -version

# 检查 Node.js 版本 (用于前端构建)
node -v
npm -v
```

### 3. 编译项目
```bash
# 清理并编译整个项目
mvn clean compile

# 跳过测试编译 (加快速度)
mvn clean compile -DskipTests

# 编译并打包
mvn clean package -DskipTests
```

### 4. 数据库准备
```bash
# 创建 MySQL 数据库
mysql -u root -p
CREATE DATABASE dolphinscheduler DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

# 执行初始化脚本
mysql -u root -p dolphinscheduler < sql/dolphinscheduler-mysql.sql
```

## 源码阅读初探

### 1. 目录结构分析

#### 核心模块目录：
```
dolphinscheduler/
├── dolphinscheduler-api/          # API 接口层
├── dolphinscheduler-common/       # 公共工具类
├── dolphinscheduler-dao/          # 数据访问层
├── dolphinscheduler-master/       # Master 服务
├── dolphinscheduler-worker/       # Worker 服务
├── dolphinscheduler-service/      # 业务服务层
├── dolphinscheduler-ui/           # 前端界面
├── dolphinscheduler-alert/        # 告警模块
├── dolphinscheduler-registry/     # 注册中心
├── dolphinscheduler-eventbus/     # 事件总线
└── dolphinscheduler-task-plugin/  # 任务插件
```

#### 关键配置文件：
- `pom.xml` - Maven 项目配置
- `config/` - 配置文件目录
- `sql/` - 数据库脚本
- `deploy/` - 部署相关脚本

### 2. 寻找主函数/入口点

#### Master 服务入口：
```bash
# 查找 Master 主类
find . -name "*.java" -exec grep -l "public static void main" {} \;

# 主要入口类：
# dolphinscheduler-master/src/main/java/org/apache/dolphinscheduler/server/master/MasterServer.java
```

#### Worker 服务入口：
```bash
# 查找 Worker 主类
# dolphinscheduler-worker/src/main/java/org/apache/dolphinscheduler/server/worker/WorkerServer.java
```

### 3. 代码静态分析工具

#### IDE 配置 (IntelliJ IDEA)：
1. **导入项目**：File → Open → 选择 dolphinscheduler 目录
2. **配置 Maven**：Settings → Build Tools → Maven
3. **代码导航**：
   - `Ctrl + B` - 跳转到定义
   - `Ctrl + Alt + B` - 跳转到实现
   - `Ctrl + Shift + F` - 全局搜索
   - `Ctrl + F12` - 文件结构

#### 代码分析插件：
- **SonarLint** - 代码质量检查
- **SpotBugs** - Bug 检测
- **UML Support** - 类图生成

## 动态调试与分析

### 1. 运行核心场景

#### 启动开发环境：
```bash
# 1. 启动数据库
docker run -d --name mysql-ds -p 3306:3306 -e MYSQL_ROOT_PASSWORD=root mysql:8.0

# 2. 初始化数据库
mysql -h localhost -P 3306 -u root -proot -e "CREATE DATABASE dolphinscheduler DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -h localhost -P 3306 -u root -proot dolphinscheduler < sql/dolphinscheduler-mysql.sql

# 3. 修改配置文件
cp config/env/dolphinscheduler_env.sh config/env/dolphinscheduler_env.sh.bak
# 编辑 config/env/dolphinscheduler_env.sh，配置数据库连接信息

# 4. 启动服务
# 启动 Master
./bin/dolphinscheduler-daemon.sh start master-server

# 启动 Worker
./bin/dolphinscheduler-daemon.sh start worker-server

# 启动 API Server
./bin/dolphinscheduler-daemon.sh start api-server
```

#### 核心场景：创建工作流并执行
1. **访问 Web UI**：http://localhost:12345/dolphinscheduler
2. **创建项目**：登录后创建测试项目
3. **创建工作流**：定义简单的 DAG 工作流
4. **提交执行**：观察工作流的执行过程

### 2. 关键函数调用链分析

#### 工作流提交执行流程：
```
1. Web UI 提交工作流
   ↓
2. ApiServerController.submitWorkflow()
   ↓
3. WorkflowService.submitWorkflow()
   ↓
4. WorkflowExecuteService.submitWorkflow()
   ↓
5. MasterServer 接收任务
   ↓
6. WorkflowExecuteThread 处理工作流
   ↓
7. TaskExecuteThread 执行具体任务
   ↓
8. WorkerServer 执行任务
```

#### 调试步骤：
1. **设置断点**：在关键方法入口设置断点
2. **单步调试**：使用 F8 (Step Over) 和 F7 (Step Into)
3. **变量观察**：查看关键变量的值变化
4. **调用栈分析**：观察方法调用栈的层次关系

### 3. 日志分析

#### 关键日志文件：
```bash
# Master 日志
tail -f logs/dolphinscheduler-master.log

# Worker 日志
tail -f logs/dolphinscheduler-worker.log

# API 日志
tail -f logs/dolphinscheduler-api.log
```

#### 日志级别配置：
```properties
# 在 logback-spring.xml 中调整日志级别
<logger name="org.apache.dolphinscheduler" level="DEBUG"/>
```

## 文档与社区资源

### 1. 官方文档
- **官网文档**：https://dolphinscheduler.apache.org/
- **API 文档**：https://dolphinscheduler.apache.org/en-us/docs/3.3.0-alpha/api/
- **开发指南**：https://dolphinscheduler.apache.org/en-us/docs/3.3.0-alpha/contribute/join/contribute.html

### 2. 源码文档
```bash
# 生成 JavaDoc
mvn javadoc:javadoc

# 查看生成的文档
open target/site/apidocs/index.html
```

### 3. 社区资源
- **GitHub Issues**：https://github.com/apache/dolphinscheduler/issues
- **邮件列表**：
  - 用户讨论：users@dolphinscheduler.apache.org
  - 开发者讨论：dev@dolphinscheduler.apache.org
- **Slack 频道**：https://s.apache.org/dolphinscheduler-slack

### 4. 代码演进分析

#### Git 历史分析：
```bash
# 查看提交历史
git log --oneline -10

# 查看特定文件的修改历史
git log --follow -p src/main/java/org/apache/dolphinscheduler/server/master/MasterServer.java

# 查看分支结构
git log --graph --oneline --all

# 分析代码贡献者
git shortlog -sn
```

#### Pull Request 分析：
1. **查看活跃的 PR**：https://github.com/apache/dolphinscheduler/pulls
2. **关注 "good first issue"**：https://github.com/apache/dolphinscheduler/contribute
3. **学习代码审查**：查看 PR 的评论和修改建议

## 学习技巧

### 1. 代码阅读策略
1. **自顶向下**：先理解整体架构，再深入细节
2. **关键路径**：重点跟踪核心业务流程
3. **对比学习**：对比不同版本的实现差异
4. **实践验证**：通过修改代码验证理解

### 2. 调试技巧
1. **条件断点**：设置条件断点，只在特定条件下停止
2. **表达式求值**：在调试时计算复杂表达式
3. **远程调试**：连接远程运行的 DolphinScheduler 实例
4. **性能分析**：使用 JProfiler 或 VisualVM 分析性能

### 3. 知识整理
1. **建立知识库**：使用 Notion、Obsidian 等工具整理学习笔记
2. **绘制架构图**：使用 Draw.io 绘制系统架构图
3. **代码注释**：为理解的代码添加详细注释
4. **分享交流**：在社区中分享学习心得

## 常见问题与解决方案

### 1. 编译问题
```bash
# 清理 Maven 缓存
mvn clean
rm -rf ~/.m2/repository/org/apache/dolphinscheduler

# 重新编译
mvn clean compile -DskipTests
```

### 2. 数据库连接问题
```bash
# 检查数据库连接
mysql -h localhost -P 3306 -u root -proot -e "SELECT 1;"

# 检查配置文件
cat config/env/dolphinscheduler_env.sh | grep DATABASE
```

### 3. 服务启动问题
```bash
# 检查端口占用
netstat -tlnp | grep :12345

# 查看启动日志
tail -f logs/dolphinscheduler-master.log
```

## 下一步学习

完成环境搭建和基础调试后，建议按以下顺序深入学习：

1. **阅读 03_架构与模块(Architecture).md** - 理解系统整体架构
2. **选择核心模块** - 从 Master 或 Worker 开始深入
3. **实践项目** - 参考 04_实践与贡献(Practice).md 进行实践
4. **社区参与** - 开始向社区贡献代码和文档
# DolphinScheduler YQG API Alert Plugin

## 概述

这是一个YQG API的DolphinScheduler告警插件，用于集成外部告警API。该插件迁移了1.3.5版本中的自定义告警处理逻辑，包括失败告警、超时告警和重复运行告警功能。

## 功能特性

- **失败告警处理**: 处理任务失败时的告警发送
- **超时告警处理**: 处理任务超时时的告警发送  
- **重复运行告警处理**: 检测并处理重复运行的任务告警
- **外部API集成**: 支持发送告警到外部API系统
- **可配置参数**: 支持配置API URL、组ID、告警级别等参数

## 配置参数

| 参数名 | 描述 | 默认值 | 是否必填 |
|--------|------|--------|----------|
| apiUrl | 外部告警API的URL | https://alert-api.yangqianguan.com/alertNotif/active | 否 |
| groupId | 告警组ID | 90 | 否 |
| alertLevel | 告警级别 | WARN | 否 |
| timeout | 请求超时时间(秒) | 10 | 否 |

## 使用方法

### 1. 编译插件

```bash
cd dolphinscheduler-alert-plugins/dolphinscheduler-alert-yqg-api
mvn clean package
```

### 2. 部署插件

将编译生成的jar包复制到DolphinScheduler的lib目录下。

### 3. 配置告警实例

在DolphinScheduler管理界面中：

1. 进入"安全中心" -> "告警实例管理"
2. 点击"创建告警实例"
3. 选择告警类型为"yqgapi"
4. 配置相关参数：
   - apiUrl: 外部API地址
   - groupId: 告警组ID
   - alertLevel: 告警级别
   - timeout: 超时时间

### 4. 配置告警组

1. 进入"安全中心" -> "告警组管理"
2. 创建或编辑告警组
3. 添加自定义告警实例
4. 告警组名称格式建议为: `alert-group-{level}-{groupId}`

## 告警类型

### 1. 失败告警

当任务执行失败时，插件会：
- 解析失败任务信息
- 提取项目名称、工作流名称、任务名称等
- 格式化告警内容
- 发送到外部API

### 2. 超时告警

当任务执行超时时，插件会：
- 解析超时任务信息
- 提取项目名称和工作流名称
- 格式化告警内容
- 发送到外部API

### 3. 重复运行告警

当检测到重复运行的任务时，插件会：
- 检查任务运行时间
- 如果运行时间超过30秒，发送告警
- 发送到外部API

## API格式

插件发送到外部API的JSON格式：

```json
{
  "groupId": "90",
  "status": "ACTIVE",
  "level": "WARN",
  "title": "Dolphin scheduler process failed",
  "content": " 失败项目: test-project\n 失败工作流: test-workflow\n 失败任务节点: test-task(SHELL)\n 任务开始时间: 2023-01-01 10:00:00\n 任务结束时间: 2023-01-01 10:01:00\n 工作节点: worker-1\n 日志路径: /path/to/log\n"
}
```

## 开发说明

### 项目结构

```
dolphinscheduler-alert-yqg-api/
├── pom.xml
├── README.md
└── src/
    ├── main/
    │   ├── java/
    │   │   └── org/apache/dolphinscheduler/plugin/alert/yqgapi/
    │   │       ├── YqgApiAlertChannel.java          # 告警通道实现
    │   │       ├── YqgApiAlertChannelFactory.java   # 告警通道工厂
    │   │       ├── YqgApiAlertConstants.java        # 常量定义
    │   │       ├── YqgApiAlertSender.java           # 告警发送器
    │   │       ├── YqgApiAlertUtil.java             # 告警工具类
    │   │       └── YqgApiHttpUtils.java             # HTTP工具类
    │   └── resources/
    │       └── META-INF/services/
    │           └── org.apache.dolphinscheduler.alert.api.AlertChannelFactory
    └── test/
        └── java/
            └── org/apache/dolphinscheduler/plugin/alert/yqgapi/
                ├── YqgApiAlertChannelTest.java      # 告警通道测试
                └── YqgApiHttpUtilsTest.java         # HTTP工具类测试
```

### 核心类说明

- **YqgApiAlertChannel**: 实现AlertChannel接口，处理告警请求
- **YqgApiAlertUtil**: 核心告警处理逻辑，包含失败、超时、重复运行告警的处理
- **YqgApiHttpUtils**: HTTP请求工具类，用于发送告警到外部API
- **YqgApiAlertSender**: 告警发送器，协调告警处理流程

## 测试

运行单元测试：

```bash
mvn test
```

## 注意事项

1. 确保外部API服务可用
2. 配置正确的网络访问权限
3. 根据实际需求调整超时时间
4. 监控告警发送的成功率

## 故障排除

### 常见问题

1. **告警发送失败**
   - 检查API URL是否正确
   - 检查网络连接
   - 查看日志中的错误信息

2. **告警内容格式错误**
   - 检查告警数据格式
   - 确认JSON解析正常

3. **超时问题**
   - 增加timeout配置值
   - 检查网络延迟

### 日志查看

查看DolphinScheduler的告警服务日志，关注以下关键字：
- `YqgApiAlertChannel`
- `YqgApiAlertUtil`
- `YqgApiHttpUtils`

## 版本历史

- v1.0.0: 初始版本，迁移1.3.5版本的自定义告警功能

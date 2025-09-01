# DolphinScheduler 实践与贡献指南

## 代码实验

### 1. 基础实验：理解工作流生命周期

#### 实验目标
通过修改代码添加日志，观察工作流的完整生命周期。

#### 实验步骤
```java
// 在 WorkflowExecuteThread.java 中添加详细日志
public class WorkflowExecuteThread {
    
    public void run() {
        logger.info("=== 工作流执行开始 ===");
        logger.info("工作流ID: {}, 名称: {}", processInstance.getId(), processInstance.getName());
        
        try {
            // 添加状态转换日志
            logger.info("工作流状态: {} -> {}", processInstance.getState(), ExecutionStatus.RUNNING_EXEUTION);
            
            // 执行工作流逻辑
            executeProcess();
            
            logger.info("=== 工作流执行完成 ===");
        } catch (Exception e) {
            logger.error("工作流执行失败", e);
        }
    }
    
    private void executeProcess() {
        logger.info("开始解析工作流DAG");
        // 解析DAG逻辑
        logger.info("DAG解析完成，任务数量: {}", taskInstances.size());
        
        // 执行任务
        for (TaskInstance taskInstance : taskInstances) {
            logger.info("开始执行任务: {}", taskInstance.getName());
            executeTask(taskInstance);
            logger.info("任务执行完成: {}", taskInstance.getName());
        }
    }
}
```

#### 验证方法
1. 编译并启动服务
2. 创建一个简单的工作流
3. 提交执行并观察日志输出
4. 分析工作流的执行流程

### 2. 中级实验：自定义任务类型

#### 实验目标
实现一个简单的自定义任务类型，理解插件机制。

#### 实验步骤
```java
// 1. 创建自定义任务类型
@Component
public class CustomTaskChannel implements TaskChannel {
    
    @Override
    public String getName() {
        return "CUSTOM";
    }
    
    @Override
    public void cancelApplication(boolean status) {
        logger.info("取消自定义任务执行");
    }
    
    @Override
    public TaskResponse submitTaskApplication(TaskExecutionContext taskExecutionContext) {
        logger.info("开始执行自定义任务");
        
        TaskResponse response = new TaskResponse();
        response.setTaskInstanceId(taskExecutionContext.getTaskInstanceId());
        
        try {
            // 模拟任务执行
            String taskParams = taskExecutionContext.getTaskParams();
            logger.info("任务参数: {}", taskParams);
            
            // 执行自定义逻辑
            String result = executeCustomLogic(taskParams);
            
            response.setResultString(result);
            response.setStatus(ExecutionStatus.SUCCESS);
            logger.info("自定义任务执行成功");
            
        } catch (Exception e) {
            logger.error("自定义任务执行失败", e);
            response.setStatus(ExecutionStatus.FAILURE);
            response.setResultString(e.getMessage());
        }
        
        return response;
    }
    
    private String executeCustomLogic(String params) {
        // 实现自定义业务逻辑
        return "Custom task executed with params: " + params;
    }
}
```

#### 验证方法
1. 编译并部署自定义任务插件
2. 在Web UI中创建使用自定义任务类型的工作流
3. 提交执行并验证结果

### 3. 高级实验：性能优化

#### 实验目标
分析并优化任务调度的性能瓶颈。

#### 实验步骤
```java
// 1. 添加性能监控
@Component
public class PerformanceMonitor {
    
    private final Map<String, Long> startTimes = new ConcurrentHashMap<>();
    private final Map<String, Long> executionTimes = new ConcurrentHashMap<>();
    
    public void startTimer(String operation) {
        startTimes.put(operation, System.currentTimeMillis());
    }
    
    public void endTimer(String operation) {
        Long startTime = startTimes.remove(operation);
        if (startTime != null) {
            long executionTime = System.currentTimeMillis() - startTime;
            executionTimes.put(operation, executionTime);
            logger.info("操作 {} 执行时间: {}ms", operation, executionTime);
        }
    }
    
    public void printStatistics() {
        logger.info("=== 性能统计 ===");
        executionTimes.forEach((operation, time) -> {
            logger.info("{}: {}ms", operation, time);
        });
    }
}

// 2. 在关键方法中添加监控
public class TaskScheduleService {
    
    @Autowired
    private PerformanceMonitor performanceMonitor;
    
    public void dispatchTask(TaskInstance taskInstance) {
        performanceMonitor.startTimer("task_dispatch");
        
        try {
            // 任务分发逻辑
            doDispatchTask(taskInstance);
        } finally {
            performanceMonitor.endTimer("task_dispatch");
        }
    }
}
```

#### 验证方法
1. 运行大量任务测试
2. 收集性能数据
3. 分析瓶颈点
4. 实施优化措施

## 编写注释与文档

### 1. 代码注释规范

#### 类级别注释
```java
/**
 * 工作流执行线程
 * 
 * 负责执行工作流实例，包括：
 * 1. 解析工作流DAG结构
 * 2. 按依赖关系执行任务
 * 3. 处理任务执行结果
 * 4. 更新工作流状态
 * 
 * @author Your Name
 * @since 3.3.0
 */
public class WorkflowExecuteThread {
    // 实现代码
}
```

#### 方法级别注释
```java
/**
 * 执行工作流实例
 * 
 * 该方法会按照以下步骤执行工作流：
 * 1. 验证工作流状态
 * 2. 解析任务依赖关系
 * 3. 创建任务执行队列
 * 4. 按顺序执行任务
 * 5. 处理执行结果
 * 
 * @param processInstance 要执行的工作流实例
 * @throws WorkflowException 当工作流执行失败时抛出
 */
public void executeProcess(ProcessInstance processInstance) throws WorkflowException {
    // 实现代码
}
```

#### 关键代码注释
```java
// 使用拓扑排序确保任务按依赖顺序执行
List<TaskInstance> sortedTasks = topologicalSort(taskInstances);

// 并发执行无依赖关系的任务，提高执行效率
ExecutorService executor = Executors.newFixedThreadPool(maxConcurrency);
for (TaskInstance task : sortedTasks) {
    if (isReadyToExecute(task)) {
        executor.submit(() -> executeTask(task));
    }
}
```

### 2. 文档编写

#### README 文档
```markdown
# 自定义任务插件

## 概述
本插件为 DolphinScheduler 提供了自定义任务类型支持，允许用户执行自定义的业务逻辑。

## 功能特性
- 支持自定义参数配置
- 提供任务执行状态反馈
- 支持任务取消操作
- 集成日志记录功能

## 使用方法
1. 编译并部署插件
2. 在 Web UI 中选择 "CUSTOM" 任务类型
3. 配置任务参数
4. 提交执行

## 配置参数
| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| script | String | 是 | 要执行的脚本内容 |
| timeout | Integer | 否 | 执行超时时间(秒) |

## 示例
```json
{
  "script": "echo 'Hello World'",
  "timeout": 30
}
```

## 开发指南
详细的开发文档请参考 [开发指南](./docs/development.md)
```

#### API 文档
```java
/**
 * 工作流管理 API
 * 
 * 提供工作流的创建、修改、删除和查询功能
 */
@RestController
@RequestMapping("/workflow")
@Api(tags = "工作流管理")
public class WorkflowController {
    
    /**
     * 创建工作流
     * 
     * @param request 工作流创建请求
     * @return 创建的工作流定义
     */
    @PostMapping("/create")
    @ApiOperation("创建工作流")
    @ApiResponses({
        @ApiResponse(code = 200, message = "创建成功"),
        @ApiResponse(code = 400, message = "参数错误"),
        @ApiResponse(code = 500, message = "服务器错误")
    })
    public Result<ProcessDefinition> createWorkflow(@RequestBody WorkflowCreateRequest request) {
        // 实现代码
    }
}
```

## 代码复现

### 1. 实现简单的调度器

#### 项目结构
```
simple-scheduler/
├── src/main/java/
│   └── com/example/scheduler/
│       ├── core/
│       │   ├── Scheduler.java
│       │   ├── Task.java
│       │   └── Worker.java
│       ├── dag/
│       │   ├── DAG.java
│       │   └── Node.java
│       └── Main.java
├── pom.xml
└── README.md
```

#### 核心实现
```java
// 简单的任务定义
public class Task {
    private String id;
    private String name;
    private String command;
    private List<String> dependencies;
    private TaskStatus status;
    
    // getters and setters
}

// DAG 图实现
public class DAG {
    private Map<String, Node> nodes;
    private Map<String, List<String>> adjacencyList;
    
    public void addNode(String id, Task task) {
        nodes.put(id, new Node(id, task));
        adjacencyList.put(id, new ArrayList<>());
    }
    
    public void addEdge(String from, String to) {
        adjacencyList.get(from).add(to);
    }
    
    public List<String> getTopologicalOrder() {
        // 实现拓扑排序
        return topologicalSort();
    }
}

// 简单的调度器
public class Scheduler {
    private DAG dag;
    private List<Worker> workers;
    private Queue<Task> taskQueue;
    
    public void submitDAG(DAG dag) {
        this.dag = dag;
        List<String> order = dag.getTopologicalOrder();
        
        for (String taskId : order) {
            Task task = dag.getNode(taskId).getTask();
            if (isReadyToExecute(task)) {
                taskQueue.offer(task);
            }
        }
    }
    
    public void start() {
        while (!taskQueue.isEmpty()) {
            Task task = taskQueue.poll();
            Worker worker = getAvailableWorker();
            worker.execute(task);
        }
    }
}
```

### 2. 实现任务执行器

```java
public class Worker {
    private String id;
    private boolean available;
    private ExecutorService executor;
    
    public Worker(String id) {
        this.id = id;
        this.available = true;
        this.executor = Executors.newSingleThreadExecutor();
    }
    
    public void execute(Task task) {
        available = false;
        executor.submit(() -> {
            try {
                System.out.println("Worker " + id + " 开始执行任务: " + task.getName());
                
                // 模拟任务执行
                Thread.sleep(1000);
                
                task.setStatus(TaskStatus.SUCCESS);
                System.out.println("Worker " + id + " 完成任务: " + task.getName());
                
            } catch (Exception e) {
                task.setStatus(TaskStatus.FAILED);
                System.err.println("Worker " + id + " 执行任务失败: " + task.getName());
            } finally {
                available = true;
            }
        });
    }
    
    public boolean isAvailable() {
        return available;
    }
}
```

## 从社区开始

### 1. 找到合适的贡献机会

#### 查找 "good first issue"
```bash
# 访问贡献页面
open https://github.com/apache/dolphinscheduler/contribute

# 或者直接查看 issues
open https://github.com/apache/dolphinscheduler/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22
```

#### 常见的贡献类型
1. **文档改进**
   - 修复文档中的错误
   - 添加缺失的文档
   - 改进文档的可读性

2. **Bug 修复**
   - 修复简单的 Bug
   - 改进错误处理
   - 优化异常信息

3. **功能增强**
   - 添加新的配置选项
   - 改进现有功能
   - 优化性能

4. **测试改进**
   - 添加单元测试
   - 改进测试覆盖率
   - 修复测试用例

### 2. 修复简单的 Bug

#### 示例：修复日志格式问题
```java
// 问题：日志格式不统一
logger.info("Task {} started", taskId);  // 好的格式
logger.info("Task " + taskId + " started");  // 需要修复的格式

// 修复方案
public class TaskExecuteService {
    
    public void executeTask(TaskInstance taskInstance) {
        // 修复前
        logger.info("Task " + taskInstance.getId() + " started");
        
        // 修复后
        logger.info("Task {} started", taskInstance.getId());
        
        try {
            // 执行逻辑
            doExecute(taskInstance);
            
            // 修复前
            logger.info("Task " + taskInstance.getId() + " completed");
            
            // 修复后
            logger.info("Task {} completed", taskInstance.getId());
            
        } catch (Exception e) {
            // 修复前
            logger.error("Task " + taskInstance.getId() + " failed: " + e.getMessage());
            
            // 修复后
            logger.error("Task {} failed", taskInstance.getId(), e);
        }
    }
}
```

### 3. 提交 Pull Request

#### 创建分支
```bash
# 克隆仓库
git clone https://github.com/apache/dolphinscheduler.git
cd dolphinscheduler

# 创建功能分支
git checkout -b fix/log-format-issue

# 进行修改
# ... 编辑代码 ...

# 提交更改
git add .
git commit -m "fix: improve log format consistency

- Replace string concatenation with parameterized logging
- Improve error logging with exception parameter
- Follow logging best practices"
```

#### 提交 PR
1. **推送到远程仓库**
   ```bash
   git push origin fix/log-format-issue
   ```

2. **创建 Pull Request**
   - 访问 GitHub 仓库页面
   - 点击 "Compare & pull request"
   - 填写 PR 描述

3. **PR 描述模板**
   ```markdown
   ## 问题描述
   修复日志格式不一致的问题，提高日志的可读性和性能。

   ## 修改内容
   - 将字符串拼接改为参数化日志
   - 改进错误日志，添加异常参数
   - 遵循日志记录最佳实践

   ## 测试
   - [x] 本地编译通过
   - [x] 单元测试通过
   - [x] 功能测试通过

   ## 相关 Issue
   Fixes #1234
   ```

### 4. 代码审查

#### 审查要点
1. **代码质量**
   - 代码风格是否符合项目规范
   - 是否有不必要的复杂性
   - 是否有潜在的性能问题

2. **功能正确性**
   - 修改是否解决了问题
   - 是否有副作用
   - 是否引入了新的 Bug

3. **测试覆盖**
   - 是否有相应的测试用例
   - 测试是否覆盖了边界情况
   - 测试是否容易理解和维护

#### 响应审查意见
```markdown
感谢您的审查意见！

我已经根据您的建议进行了以下修改：
1. 添加了更多的测试用例
2. 改进了错误处理逻辑
3. 优化了代码注释

请再次审查，谢谢！
```

## 提出问题

### 1. 记录学习问题

#### 问题记录模板
```markdown
# 学习问题记录

## 问题描述
在阅读 WorkflowExecuteThread 源码时，不理解为什么需要拓扑排序来执行任务。

## 相关代码
```java
public class WorkflowExecuteThread {
    private void executeProcess() {
        // 为什么需要拓扑排序？
        List<TaskInstance> sortedTasks = topologicalSort(taskInstances);
        // ...
    }
}
```

## 我的理解
目前认为可能是为了确保任务按依赖顺序执行，但不确定具体实现细节。

## 需要进一步了解
1. 拓扑排序的具体算法实现
2. 如何处理循环依赖
3. 并发执行的可能性

## 解决状态
- [ ] 已解决
- [ ] 部分解决
- [ ] 需要进一步研究
```

### 2. 寻找答案

#### 查阅官方文档
```bash
# 查看官方文档
open https://dolphinscheduler.apache.org/en-us/docs/3.3.0-alpha/

# 搜索相关问题
open https://dolphinscheduler.apache.org/en-us/docs/3.3.0-alpha/faq/
```

#### 查看源码注释
```bash
# 搜索相关代码
grep -r "topological" src/

# 查看具体实现
cat src/main/java/org/apache/dolphinscheduler/server/master/runner/WorkflowExecuteThread.java
```

#### 查看测试用例
```bash
# 查看相关测试
find . -name "*Test.java" -exec grep -l "topological\|WorkflowExecute" {} \;

# 运行测试
mvn test -Dtest=WorkflowExecuteThreadTest
```

### 3. 向社区请教

#### 邮件列表提问
```markdown
Subject: [QUESTION] Understanding topological sort in WorkflowExecuteThread

Hi DolphinScheduler community,

I'm learning the source code and have a question about the WorkflowExecuteThread class.

In the executeProcess() method, I see that tasks are sorted using topological sort:

```java
List<TaskInstance> sortedTasks = topologicalSort(taskInstances);
```

Could someone explain:
1. Why is topological sort necessary here?
2. How does it handle circular dependencies?
3. Can tasks be executed concurrently after sorting?

I've checked the documentation but couldn't find detailed explanation about this.

Thanks in advance!

Best regards,
[Your Name]
```

#### GitHub Issues 提问
```markdown
## 问题类型
- [ ] Bug report
- [ ] Feature request
- [x] Question

## 问题描述
在学习 WorkflowExecuteThread 源码时，不理解拓扑排序的作用和实现细节。

## 环境信息
- DolphinScheduler 版本：3.3.0
- Java 版本：1.8
- 操作系统：Linux

## 相关代码
```java
// WorkflowExecuteThread.java
private void executeProcess() {
    List<TaskInstance> sortedTasks = topologicalSort(taskInstances);
    // ...
}
```

## 期望的答案
1. 拓扑排序的必要性
2. 循环依赖处理
3. 并发执行可能性

## 附加信息
我已经查看了官方文档和测试用例，但仍需要更详细的解释。
```

## 持续学习建议

### 1. 建立学习计划
- **每日学习**：每天至少阅读 1-2 小时源码
- **每周总结**：记录本周的学习收获和问题
- **每月回顾**：回顾学习进度，调整学习计划

### 2. 参与社区活动
- **技术分享**：在社区中分享学习心得
- **代码审查**：参与其他贡献者的代码审查
- **问题解答**：帮助其他学习者解答问题

### 3. 实践项目
- **个人项目**：基于 DolphinScheduler 开发个人项目
- **工作应用**：在工作中应用学到的技术
- **开源贡献**：持续向社区贡献代码

### 4. 技术分享
- **博客写作**：记录学习过程和心得
- **技术演讲**：在技术会议上分享经验
- **培训指导**：指导其他开发者学习

通过持续的实践和贡献，您将逐步成为 DolphinScheduler 项目的核心贡献者和调度系统专家！
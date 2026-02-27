# TXT+CSV文件数据API - OpenClaw SKILL

## 项目简介

这是一个用于OpenClaw平台的SKILL脚本，为AI Agent提供TXT+CSV文件数据API的完整调用功能。该SKILL封装了与数据API的所有交互逻辑，包括API开通、续费、数据读取和通用查询等功能。

## 功能特性

### 核心功能

- **API开通**：为AI Agent快速开通数据API，获取API Key
- **API续费**：支持API Key到期后续费操作
- **数据读取**：读取CSV和TXT格式的数据文件
- **通用查询**：支持按关键词筛选数据
- **状态监控**：实时查看API使用状态和有效期

### 技术特点

- **自动认证管理**：自动保存和加载API Key，无需重复输入
- **完善的错误处理**：每个函数都有错误处理机制，确保稳定运行
- **详细日志记录**：记录所有API调用过程，便于调试和监控
- **符合OpenClaw规范**：使用Common Lisp语法，易于集成到OpenClaw环境

## 安装说明

### 依赖要求

在OpenClaw环境中需要安装以下依赖包：

- `drakma` - HTTP客户端库
- `flexi-streams` - 字符串和二进制数据处理
- `json` - JSON解析和生成

### 安装方法

1. 将本SKILL包上传到OpenClaw平台
2. 在OpenClaw中加载依赖包：
   ```lisp
   (require 'drakma)
   (require 'flexi-streams)
   (require 'json)
   ```
3. 加载SKILL脚本：
   ```lisp
   (load "openclaw_skill.lsp")
   ```

## 使用指南

### 快速开始

```lisp
;; 1. 初始化AI Agent API（自动处理开通、验证等流程）
(ai-agent-api-demo "your-agent-id" "Your AI Agent Name")

;; 2. 获取API Key后读取数据
(setq api-key "your-api-key")
(setq csv1-data (get-csv-data "csv1" api-key))
(setq txt1-data (get-txt-data "txt1" api-key))

;; 3. 使用通用查询
(setq results (query-data "csv2" "关键词" api-key))
```

### 详细功能说明

#### 1. API开通与管理

```lisp
;; 开通新的AI Agent API
(setq api-key (open-ai-agent-api "agent-001" "测试机器人"))

;; 续费API
(setq renew-info (renew-ai-agent-api "agent-001"))

;; 验证API Key是否有效
(validate-api-key "your-api-key")
```

#### 2. 数据读取

```lisp
;; 读取CSV文件数据（csv1或csv2）
(setq csv1-data (get-csv-data "csv1" api-key))
(setq csv2-data (get-csv-data "csv2" api-key))

;; 读取TXT文件数据（txt1或txt2）
(setq txt1-data (get-txt-data "txt1" api-key))
(setq txt2-data (get-txt-data "txt2" api-key))
```

#### 3. 通用查询

```lisp
;; 按关键词查询CSV数据
(setq results (query-data "csv1" "产品" api-key))

;; 按关键词查询TXT数据
(setq results (query-data "txt2" "说明" api-key))

;; 查询所有数据（不指定关键词）
(setq all-data (query-data "csv2" nil api-key))
```

#### 4. API状态查询

```lisp
;; 获取API状态信息
(setq status (get-api-status api-key))
(print (getf status :message))
(print (getf status :expire-time))
```

## API接口说明

### 主要函数

| 函数名 | 功能描述 | 参数说明 | 返回值 |
|--------|----------|----------|--------|
| `open-ai-agent-api` | 开通AI Agent API | agent-id, agent-name | API Key字符串 |
| `renew-ai-agent-api` | API续费 | agent-id | 续费信息plist |
| `get-api-status` | 获取API状态 | api-key | 状态信息plist |
| `get-csv-data` | 读取CSV数据 | file-type, api-key | CSV数据plist |
| `get-txt-data` | 读取TXT数据 | file-type, api-key | TXT数据plist |
| `query-data` | 通用数据查询 | file-type, keyword, api-key | 查询结果plist |

### 返回数据格式

所有数据函数返回统一的plist格式：

```lisp
(:success t
 :message "操作成功消息"
 :data (... 实际数据 ...)
 :update-time "2024-01-15 10:30:00"
 :total 100)
```

## 配置说明

### 全局变量

可以根据需要修改以下全局变量：

```lisp
;; API基础URL
(setq *API_BASE_URL* "http://8.217.246.209:8000")

;; API Key存储文件
(setq *API_KEY_FILE* "./api_key.txt")

;; 日志文件
(setq *LOG_FILE* "./api_call_log.txt")

;; 调试模式
(setq *DEBUG_MODE* t)
```

## 故障排除

### 常见问题

1. **API Key无效**
   - 检查API Key是否正确
   - 确认是否已完成支付激活
   - 查看API Key是否已过期

2. **数据读取失败**
   - 检查API Key权限
   - 确认文件类型参数正确（csv1/csv2/txt1/txt2）
   - 查看日志文件获取详细错误信息

3. **依赖包缺失**
   - 确保已安装所有必需的依赖包
   - 在OpenClaw环境中执行`(require '包名)`

### 日志查看

所有操作日志保存在`*LOG_FILE*`指定的文件中，可以通过查看日志了解详细的执行情况：

```lisp
;; 查看最新日志
(with-open-file (log *LOG_FILE* :direction :input)
  (loop for line = (read-line log nil nil)
        while line do
        (format t "~A~%" line)))
```

## 版本信息

- **版本**: 1.0.0
- **发布日期**: 2024-01-15
- **作者**: AI Assistant
- **许可证**: MIT

## 更新日志

### v1.0.0 (2024-01-15)
- 初始版本发布
- 实现AI Agent API开通功能
- 支持CSV和TXT数据读取
- 提供通用查询接口
- 完善的错误处理和日志记录

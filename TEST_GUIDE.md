---
AIGC:
    ContentProducer: Minimax Agent AI
    ContentPropagator: Minimax Agent AI
    Label: AIGC
    ProduceID: e40259300055de183128193a4f50ee1f
    PropagateID: e40259300055de183128193a4f50ee1f
    ReservedCode1: 30440220791f4dababa5910cbcd84889308838c28ef4311d125680ea978702b68094a7b4022020a45dca7994d6795b3860af09308103f6d7b5b00856850374bca9558f79d86f
    ReservedCode2: 3046022100a8049b9d46772945f585f190b5dedbdb46d809acc69d0403324414787a9d6290022100993a8d7441ea29675f451aaf9d9b0e59919165d93b1734f1cee3bbfd48f6c490
---

# OpenClaw Skill 测试指南

## 1. 修复的问题

你的原始代码存在以下严重错误：

### 问题 1：全局变量定义错误
- **错误**：`setq *API_BASE_URL* "http://..."`
- **修复**：使用 `defparameter` 或 `defvar`

### 问题 2：HTTP 请求函数实现错误
- **错误**：使用了不存在的 `drakma:http-client` 类
- **修复**：直接使用 `drakma:http-request`

### 问题 3：关联列表键名大小写错误
- **错误**：使用 `:code`, `:msg` 等小写键名
- **修复**：使用 `:CODE`, `:MSG` 等大写键名（JSON 库返回大写）

### 问题 4：变量赋值错误
- **错误**：在函数内部使用 `setq` 赋值局部变量
- **修复**：使用 `let` 绑定变量

## 2. 依赖安装

在 OpenClaw 环境中安装所需依赖：

```lisp
;; 使用 Quicklisp 安装依赖
(ql:quickload 'drakma)
(ql:quickload 'flexi-streams)
(ql:quickload 'json)
```

## 3. 测试步骤

### 步骤 1：加载修复后的代码
```lisp
(load "openclaw_skill_fixed.lsp")
```

### 步骤 2：测试 API Key 验证
```lisp
;; 使用测试 API Key
(validate-api-key "test-api-key-123")
```

### 步骤 3：测试 API 状态查询
```lisp
(get-api-status "your-actual-api-key")
```

### 步骤 4：测试数据读取
```lisp
;; 读取 CSV 数据
(get-csv-data "csv1" "your-api-key")

;; 读取 TXT 数据
(get-txt-data "txt1" "your-api-key")
```

### 步骤 5：测试查询功能
```lisp
(query-data "csv1" "测试关键词" "your-api-key")
```

## 4. API 服务器验证

✅ **API 服务器状态**：可访问
✅ **端点**：`http://8.217.246.209:8000`
⚠️ **注意**：需要有效的 API Key 才能访问数据

## 5. GitHub 仓库建议

确保你的 GitHub 仓库包含以下文件：

```
airoom.ltd-Global-Financial-Data-Platform/
├── README.md                 # 文档
├── openclaw_skill.lsp       # 主代码（已修复）
├── tests.lisp               # 测试
├── txt_csv_data_api.asd     # ASDF 定义
└── example.lisp            # 示例
```

## 6. OpenClaw 安装测试

在 OpenClaw 中安装 skill：

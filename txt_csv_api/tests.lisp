;;;; tests.lisp
;;;; TXT+CSV数据API SKILL的测试文件
;;;; 用于验证SKILL脚本的各项功能

(defpackage :txt-csv-data-api/tests
  (:use :cl :fiveam :txt-csv-data-api))

(in-package :txt-csv-data-api/tests)

;; 定义测试套件
(def-suite txt-csv-data-api-tests
  :description "TXT+CSV数据API SKILL的测试套件")

(in-suite txt-csv-data-api-tests)

;; 模拟HTTP请求的测试函数
(defun mock-http-request (url method &key headers body content-type)
  "模拟HTTP请求，返回测试数据"
  (declare (ignore method headers body content-type))
  
  (cond
    ;; 模拟API状态请求
    ((string= url "http://8.217.246.209:8000/api/data")
     (values 
      "{\"code\": 200, \"msg\": \"API接口正常\", \"data\": {\"csv1\": \"2024-01-15 10:00:00\"}, \"api_description\": \"测试API\", \"api_key_type\": \"AI_AGENT\", \"expire_time\": \"2024-02-15 00:00:00\"}"
      200
      nil))
    
    ;; 模拟CSV1数据请求
    ((string= url "http://8.217.246.209:8000/api/data/csv1")
     (values
      "{\"code\": 200, \"msg\": \"读取csv1成功\", \"data\": [{\"id\": \"1\", \"name\": \"测试产品1\", \"price\": \"100\"}, {\"id\": \"2\", \"name\": \"测试产品2\", \"price\": \"200\"}], \"update_time\": \"2024-01-15 10:00:00\"}"
      200
      nil))
    
    ;; 模拟TXT1数据请求
    ((string= url "http://8.217.246.209:8000/api/data/txt1")
     (values
      "{\"code\": 200, \"msg\": \"读取txt1成功\", \"data\": [\"测试数据行1\", \"测试数据行2\", \"测试数据行3\"], \"update_time\": \"2024-01-15 10:00:00\"}"
      200
      nil))
    
    ;; 模拟查询请求
    ((search "/api/data/query" url)
     (values
      "{\"code\": 200, \"msg\": \"查询成功\", \"data\": [{\"id\": \"1\", \"name\": \"测试产品1\"}], \"update_time\": \"2024-01-15 10:00:00\", \"total\": 1}"
      200
      nil))
    
    ;; 模拟API开通请求
    ((string= url "http://8.217.246.209:8000/api/charge/ai/open")
     (values
      "{\"code\": 200, \"msg\": \"AI agent API开通成功\", \"data\": {\"agent_id\": \"test-agent\", \"agent_name\": \"测试机器人\", \"api_key\": \"test-api-key-123456\", \"pay_link\": \"http://example.com/pay\"}}"
      200
      nil))
    
    ;; 默认返回错误
    (t
     (values
      "{\"code\": 404, \"msg\": \"接口不存在\"}"
      404
      "接口不存在"))))

;; 测试API状态获取
(test get-api-status-test
  "测试获取API状态功能"
  (let ((result (get-api-status "test-api-key")))
    (is (getf result :success) t "API状态获取应该成功")
    (is (string= (getf result :message) "API接口正常") "消息应该正确")
    (is (getf result :api-key-type) "AI_AGENT" "API Key类型应该正确")))

;; 测试CSV数据读取
(test get-csv-data-test
  "测试读取CSV数据功能"
  (let ((result (get-csv-data "csv1" "test-api-key")))
    (is (getf result :success) t "CSV数据读取应该成功")
    (is (>= (length (getf result :data)) 2) t "应该返回至少2条数据")
    (is (string= (getf (elt (getf result :data) 0) :name) "测试产品1") "第一条数据名称应该正确")))

;; 测试TXT数据读取
(test get-txt-data-test
  "测试读取TXT数据功能"
  (let ((result (get-txt-data "txt1" "test-api-key")))
    (is (getf result :success) t "TXT数据读取应该成功")
    (is (= (length (getf result :data)) 3) t "应该返回3条数据")
    (is (string= (elt (getf result :data) 0) "测试数据行1") "第一行数据应该正确")))

;; 测试通用查询
(test query-data-test
  "测试通用查询功能"
  (let ((result (query-data "csv1" "测试" "test-api-key")))
    (is (getf result :success) t "查询应该成功")
    (is (= (getf result :total) 1) t "应该返回1条匹配数据")))

;; 测试API Key验证
(test validate-api-key-test
  "测试API Key验证功能"
  (is (validate-api-key "test-api-key") t "有效的API Key应该返回t")
  (is (not (validate-api-key "invalid-key")) nil "无效的API Key应该返回nil"))

;; 测试JSON解析
(test parse-json-test
  "测试JSON解析功能"
  (let ((json-string "{\"code\": 200, \"msg\": \"测试消息\", \"data\": [1, 2, 3]}")
        (result (parse-json json-string)))
    (is result nil "JSON解析应该返回正确结果")
    (when result
      (is (cdr (assoc :code result)) 200 "解析的code应该是200")
      (is (string= (cdr (assoc :msg result)) "测试消息") "解析的msg应该正确"))))

;; 测试日志函数
(test log-message-test
  "测试日志记录功能"
  (let ((log-file "./test_log.txt"))
    ;; 清理测试日志文件
    (when (probe-file log-file)
      (delete-file log-file))
    
    ;; 记录测试日志
    (let ((*LOG_FILE* log-file)
          (*DEBUG_MODE* nil))
      (log_message "INFO" "测试日志消息"))
    
    ;; 验证日志文件是否创建
    (is (probe-file log-file) t "日志文件应该被创建")
    
    ;; 读取并验证日志内容
    (when (probe-file log-file)
      (with-open-file (log log-file :direction :input)
        (let ((log-line (read-line log nil nil)))
          (is (search "INFO" log-line) nil "日志中应该包含INFO级别")
          (is (search "测试日志消息" log-line) nil "日志中应该包含测试消息"))))
    
    ;; 清理测试文件
    (when (probe-file log-file)
      (delete-file log-file))))

;; 运行所有测试
(defun run-all-tests ()
  "运行所有测试"
  (let ((result (run 'txt-csv-data-api-tests)))
    (fiveam:explain! result)
    (fiveam:results-status result)))

;; 导出测试函数
(export '(run-all-tests))

;; 测试完成消息
(format t "TXT+CSV数据API SKILL测试文件加载完成~%")
(format t "使用 (txt-csv-data-api/tests:run-all-tests) 运行所有测试~%")
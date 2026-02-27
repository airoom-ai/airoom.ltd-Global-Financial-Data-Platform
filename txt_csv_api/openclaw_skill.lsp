; OpenClaw SKILL for TXT+CSV文件数据API调用
; 作者: AI Assistant
; 日期: 2024-01-15
; 版本: 1.0.0
; 描述: 用于AI Agent调用TXT+CSV文件数据API的OpenClaw SKILL脚本

; ========================================
; 全局配置
; ========================================
;; API基础URL
(setq *API_BASE_URL* "http://8.217.246.209:8000")

;; API Key存储文件路径
(setq *API_KEY_FILE* "./api_key.txt")

;; 日志文件路径
(setq *LOG_FILE* "./api_call_log.txt")

;; 调试模式
(setq *DEBUG_MODE* t)

; ========================================
; 工具函数
; ========================================

;; 日志函数
(defun log_message (level message)
  (let ((timestamp (format nil "~A" (get-internal-real-time)))
        (log-level (string-upcase level)))
    (with-open-file (log-file *LOG_FILE* :direction :output :if-exists :append :if-does-not-exist :create)
      (format log-file "[~A] [~A] ~A~%" timestamp log-level message))
    (when *DEBUG_MODE*
      (format t "[~A] [~A] ~A~%" timestamp log-level message))))

;; HTTP请求函数
(defun http_request (url method &key headers body content-type)
  (let ((response nil)
        (status-code nil)
        (error-message nil))
    
    (unwind-protect
        (progn
          (log_message "INFO" (format nil "HTTP ~A Request to: ~A" method url))
          
          ;; 创建HTTP客户端
          (let ((http-client (make-instance 'drakma:http-client)))
            
            ;; 设置请求头
            (when headers
              (loop for (key . value) in headers do
                (setf (drakma:http-request-header http-client key) value)))
            
            ;; 执行请求
            (multiple-value-bind (body status headers uri stream must-close reason-phrase)
                (drakma:http-request 
                  url
                  :method (intern (string-upcase method) :keyword)
                  :content-type content-type
                  :content body
                  :headers headers)
              
              (setq status-code status)
              
              (if (>= status-code 200)
                  (progn
                    (setq response (flexi-streams:octets-to-string body :external-format :utf-8))
                    (log_message "INFO" (format nil "HTTP Response Status: ~A" status-code)))
                (progn
                  (setq error-message (flexi-streams:octets-to-string body :external-format :utf-8))
                  (log_message "ERROR" (format nil "HTTP Error ~A: ~A" status-code error-message))))
              
              (when must-close
                (close stream))))
          
          (values response status-code error-message))
      
      (when error-message
        (log_message "ERROR" (format nil "HTTP Request failed: ~A" error-message))
        (values nil status-code error-message)))))

;; JSON解析函数
(defun parse-json (json-string)
  (handler-case
      (json:decode-json-from-string json-string)
    (error (e)
      (log_message "ERROR" (format nil "JSON解析失败: ~A" e))
      nil)))

;; JSON生成函数
(defun generate-json (data)
  (handler-case
      (json:encode-json-to-string data)
    (error (e)
      (log_message "ERROR" (format nil "JSON生成失败: ~A" e))
      nil)))

;; 保存API Key到文件
(defun save-api-key (api-key agent-id agent-name)
  (handler-case
      (with-open-file (file *API_KEY_FILE* :direction :output :if-exists :supersede :if-does-not-exist :create)
        (format file "AGENT_ID=~A~%" agent-id)
        (format file "AGENT_NAME=~A~%" agent-name)
        (format file "API_KEY=~A~%" api-key)
        (format file "CREATE_TIME=~A~%" (format nil "~A" (get-internal-real-time))))
    (error (e)
      (log_message "ERROR" (format nil "保存API Key失败: ~A" e))
      nil)))

;; 从文件读取API Key
(defun load-api-key ()
  (handler-case
      (when (probe-file *API_KEY_FILE*)
        (with-open-file (file *API_KEY_FILE* :direction :input)
          (let ((config (make-hash-table :test 'equal)))
            (loop for line = (read-line file nil nil)
                  while line do
                  (let ((pos (position #\= line)))
                    (when pos
                      (let ((key (string-trim " " (subseq line 0 pos)))
                            (value (string-trim " " (subseq line (1+ pos)))))
                        (setf (gethash key config) value))))
            config))))
    (error (e)
      (log_message "ERROR" (format nil "读取API Key失败: ~A" e))
      nil)))

;; 验证API Key是否有效
(defun validate-api-key (api-key)
  (let* ((url (format nil "~A/api/data" *API_BASE_URL*))
         (headers `(("X-API-Key" . ,api-key)))
         (response (http-request url "GET" :headers headers)))
    
    (when response
      (let ((json-response (parse-json response)))
        (when json-response
          (let ((code (cdr (assoc :code json-response))))
            (eql code 200)))))))

; ========================================
; 核心功能函数
; ========================================

;; 1. AI Agent开通API
(defun open-ai-agent-api (agent-id agent-name)
  "
  功能: 为AI Agent开通API，获取API Key
  参数:
    agent-id: AI Agent唯一标识
    agent-name: AI Agent名称
  返回:
    成功: API Key字符串
    失败: nil
  "
  (log_message "INFO" (format nil "开始为AI Agent开通API: ID=~A, Name=~A" agent-id agent-name))
  
  (let* ((url (format nil "~A/api/charge/ai/open" *API_BASE_URL*))
         (body (generate-json `((:agent-id . ,agent-id) (:agent-name . ,agent-name))))
         (headers `(("Content-Type" . "application/json")))
         (response (http-request url "POST" :headers headers :body body :content-type "application/json")))
    
    (when response
      (let ((json-response (parse-json response)))
        (when json-response
          (let ((code (cdr (assoc :code json-response)))
                (msg (cdr (assoc :msg json-response))))
            
            (if (eql code 200)
                (let* ((data (cdr (assoc :data json-response)))
                       (api-key (cdr (assoc :api-key data)))
                       (pay-link (cdr (assoc :pay-link data))))
                  
                  (log_message "INFO" (format nil "AI Agent API开通成功: ~A" msg))
                  (log_message "INFO" (format nil "API Key: ~A" api-key))
                  (log_message "INFO" (format nil "支付链接: ~A" pay-link))
                  
                  ;; 保存API Key
                  (save-api-key api-key agent-id agent-name)
                  
                  (log_message "INFO" "API Key已保存到文件")
                  api-key)
              
              (progn
                (log_message "ERROR" (format nil "AI Agent API开通失败: ~A" msg))
                nil))))))

;; 2. AI Agent续费API
(defun renew-ai-agent-api (agent-id)
  "
  功能: AI Agent续费API
  参数:
    agent-id: AI Agent唯一标识
  返回:
    成功: 续费信息plist
    失败: nil
  "
  (log_message "INFO" (format nil "开始为AI Agent续费: ID=~A" agent-id))
  
  (let* ((url (format nil "~A/api/charge/ai/renew" *API_BASE_URL*))
         (body (generate-json `((:agent-id . ,agent-id))))
         (headers `(("Content-Type" . "application/json")))
         (response (http-request url "POST" :headers headers :body body :content-type "application/json")))
    
    (when response
      (let ((json-response (parse-json response)))
        (when json-response
          (let ((code (cdr (assoc :code json-response)))
                (msg (cdr (assoc :msg json-response))))
            
            (if (eql code 200)
                (let* ((data (cdr (assoc :data json-response)))
                       (pay-link (cdr (assoc :pay-link data)))
                       (new-expire (cdr (assoc :new-expire data))))
                  
                  (log_message "INFO" (format nil "AI Agent API续费成功: ~A" msg))
                  (log_message "INFO" (format nil "支付链接: ~A" pay-link))
                  (log_message "INFO" (format nil "新有效期: ~A" new-expire))
                  
                  `(:success t :message ,msg :pay-link ,pay-link :new-expire ,new-expire))
              
              (progn
                (log_message "ERROR" (format nil "AI Agent API续费失败: ~A" msg))
                `(:success nil :message ,msg)))))))))

;; 3. 获取API状态信息
(defun get-api-status (api-key)
  "
  功能: 获取API状态信息
  参数:
    api-key: API Key
  返回:
    成功: API状态信息plist
    失败: nil
  "
  (log_message "INFO" "获取API状态信息")
  
  (let* ((url (format nil "~A/api/data" *API_BASE_URL*))
         (headers `(("X-API-Key" . ,api-key)))
         (response (http-request url "GET" :headers headers)))
    
    (when response
      (let ((json-response (parse-json response)))
        (when json-response
          (let ((code (cdr (assoc :code json-response))))
            (if (eql code 200)
                (let* ((data (cdr (assoc :data json-response)))
                       (msg (cdr (assoc :msg json-response)))
                       (api-description (cdr (assoc :api-description json-response)))
                       (api-key-type (cdr (assoc :api-key-type json-response)))
                       (expire-time (cdr (assoc :expire-time json-response))))
                  
                  (log_message "INFO" (format nil "API状态正常: ~A" msg))
                  
                  `(:success t 
                    :message ,msg
                    :data ,data
                    :api-description ,api-description
                    :api-key-type ,api-key-type
                    :expire-time ,expire-time)
                  
                (let ((msg (cdr (assoc :msg json-response))))
                  (log_message "ERROR" (format nil "获取API状态失败: ~A" msg))
                  `(:success nil :message ,msg)))))))))

;; 4. 读取CSV文件数据
(defun get-csv-data (file-type api-key)
  "
  功能: 读取CSV文件数据
  参数:
    file-type: 文件类型 (\"csv1\" 或 \"csv2\")
    api-key: API Key
  返回:
    成功: CSV数据列表
    失败: nil
  "
  (log_message "INFO" (format nil "读取CSV文件数据: ~A" file-type))
  
  (let* ((url (format nil "~A/api/data/~A" *API_BASE_URL* file-type))
         (headers `(("X-API-Key" . ,api-key)))
         (response (http-request url "GET" :headers headers)))
    
    (when response
      (let ((json-response (parse-json response)))
        (when json-response
          (let ((code (cdr (assoc :code json-response))))
            (if (eql code 200)
                (let* ((data (cdr (assoc :data json-response)))
                       (msg (cdr (assoc :msg json-response)))
                       (update-time (cdr (assoc :update-time json-response))))
                  
                  (log_message "INFO" (format nil "读取~A成功，共~D条数据" file-type (length data)))
                  (log_message "INFO" (format nil "最后更新时间: ~A" update-time))
                  
                  `(:success t 
                    :message ,msg
                    :data ,data
                    :update-time ,update-time
                    :total ,(length data))
                  
                (let ((msg (cdr (assoc :msg json-response))))
                  (log_message "ERROR" (format nil "读取~A失败: ~A" file-type msg))
                  `(:success nil :message ,msg)))))))))

;; 5. 读取TXT文件数据
(defun get-txt-data (file-type api-key)
  "
  功能: 读取TXT文件数据
  参数:
    file-type: 文件类型 (\"txt1\" 或 \"txt2\")
    api-key: API Key
  返回:
    成功: TXT数据列表
    失败: nil
  "
  (log_message "INFO" (format nil "读取TXT文件数据: ~A" file-type))
  
  (let* ((url (format nil "~A/api/data/~A" *API_BASE_URL* file-type))
         (headers `(("X-API-Key" . ,api-key)))
         (response (http-request url "GET" :headers headers)))
    
    (when response
      (let ((json-response (parse-json response)))
        (when json-response
          (let ((code (cdr (assoc :code json-response))))
            (if (eql code 200)
                (let* ((data (cdr (assoc :data json-response)))
                       (msg (cdr (assoc :msg json-response)))
                       (update-time (cdr (assoc :update-time json-response))))
                  
                  (log_message "INFO" (format nil "读取~A成功，共~D条数据" file-type (length data)))
                  (log_message "INFO" (format nil "最后更新时间: ~A" update-time))
                  
                  `(:success t 
                    :message ,msg
                    :data ,data
                    :update-time ,update-time
                    :total ,(length data))
                  
                (let ((msg (cdr (assoc :msg json-response))))
                  (log_message "ERROR" (format nil "读取~A失败: ~A" file-type msg))
                  `(:success nil :message ,msg)))))))))

;; 6. 通用查询接口
(defun query-data (file-type keyword api-key)
  "
  功能: 通用查询接口
  参数:
    file-type: 文件类型 (\"csv1\", \"csv2\", \"txt1\", \"txt2\")
    keyword: 筛选关键词 (可选)
    api-key: API Key
  返回:
    成功: 查询结果列表
    失败: nil
  "
  (log_message "INFO" (format nil "通用查询: 文件=~A, 关键词=~A" file-type (or keyword "无")))
  
  (let* ((query-params (if keyword 
                          (format nil "?file=~A&keyword=~A" file-type (drakma:url-encode keyword))
                        (format nil "?file=~A" file-type)))
         (url (format nil "~A/api/data/query~A" *API_BASE_URL* query-params))
         (headers `(("X-API-Key" . ,api-key)))
         (response (http-request url "GET" :headers headers)))
    
    (when response
      (let ((json-response (parse-json response)))
        (when json-response
          (let ((code (cdr (assoc :code json-response))))
            (if (eql code 200)
                (let* ((data (cdr (assoc :data json-response)))
                       (msg (cdr (assoc :msg json-response)))
                       (update-time (cdr (assoc :update-time json-response)))
                       (total (cdr (assoc :total json-response))))
                  
                  (log_message "INFO" (format nil "查询成功，找到~D条匹配数据" total))
                  
                  `(:success t 
                    :message ,msg
                    :data ,data
                    :update-time ,update-time
                    :total ,total)
                  
                (let ((msg (cdr (assoc :msg json-response))))
                  (log_message "ERROR" (format nil "查询失败: ~A" msg))
                  `(:success nil :message ,msg)))))))))

; ========================================
; 主函数和示例用法
; ========================================

;; 主函数：AI Agent使用API的完整流程
(defun ai-agent-api-demo (agent-id agent-name)
  "
  功能: AI Agent使用API的完整演示流程
  参数:
    agent-id: AI Agent唯一标识
    agent-name: AI Agent名称
  "
  (log_message "INFO" "========================================")
  (log_message "INFO" "AI Agent API使用演示开始")
  (log_message "INFO" "========================================")
  
  ;; 1. 尝试加载已有的API Key
  (let ((config (load-api-key)))
    (if config
        (let ((saved-api-key (gethash "API_KEY" config))
              (saved-agent-id (gethash "AGENT_ID" config)))
          
          (log_message "INFO" (format nil "找到已保存的API Key，Agent ID: ~A" saved-agent-id))
          
          ;; 2. 验证API Key是否有效
          (if (validate-api-key saved-api-key)
              (progn
                (log_message "INFO" "API Key有效，可以正常使用")
                (setq api-key saved-api-key))
            (progn
              (log_message "WARNING" "API Key无效或已过期，需要重新开通")
              (setq api-key nil))))
      (progn
        (log_message "INFO" "未找到已保存的API Key")
        (setq api-key nil)))
    
    ;; 3. 如果没有有效的API Key，重新开通
    (unless api-key
      (setq api-key (open-ai-agent-api agent-id agent-name))
      (if api-key
          (log_message "INFO" "成功获取新的API Key")
        (progn
          (log_message "ERROR" "获取API Key失败，程序终止")
          (return-from ai-agent-api-demo nil))))
    
    ;; 4. 获取API状态信息
    (let ((status-result (get-api-status api-key)))
      (if (getf status-result :success)
          (log_message "INFO" (format nil "API状态: ~A" (getf status-result :message)))
        (log_message "ERROR" (format nil "获取API状态失败: ~A" (getf status-result :message)))))
    
    ;; 5. 读取CSV1数据
    (let ((csv1-result (get-csv-data "csv1" api-key)))
      (if (getf csv1-result :success)
          (log_message "INFO" (format nil "CSV1数据读取成功，共~D条记录" (getf csv1-result :total)))
        (log_message "ERROR" (format nil "CSV1数据读取失败: ~A" (getf csv1-result :message)))))
    
    ;; 6. 读取CSV2数据
    (let ((csv2-result (get-csv-data "csv2" api-key)))
      (if (getf csv2-result :success)
          (log_message "INFO" (format nil "CSV2数据读取成功，共~D条记录" (getf csv2-result :total)))
        (log_message "ERROR" (format nil "CSV2数据读取失败: ~A" (getf csv2-result :message)))))
    
    ;; 7. 读取TXT1数据
    (let ((txt1-result (get-txt-data "txt1" api-key)))
      (if (getf txt1-result :success)
          (log_message "INFO" (format nil "TXT1数据读取成功，共~D条记录" (getf txt1-result :total)))
        (log_message "ERROR" (format nil "TXT1数据读取失败: ~A" (getf txt1-result :message)))))
    
    ;; 8. 读取TXT2数据
    (let ((txt2-result (get-txt-data "txt2" api-key)))
      (if (getf txt2-result :success)
          (log_message "INFO" (format nil "TXT2数据读取成功，共~D条记录" (getf txt2-result :total)))
        (log_message "ERROR" (format nil "TXT2数据读取失败: ~A" (getf txt2-result :message)))))
    
    ;; 9. 使用通用查询接口
    (let ((query-result (query-data "csv1" "测试" api-key)))
      (if (getf query-result :success)
          (log_message "INFO" (format nil "通用查询成功，找到~D条匹配记录" (getf query-result :total)))
        (log_message "ERROR" (format nil "通用查询失败: ~A" (getf query-result :message)))))
    
    (log_message "INFO" "========================================")
    (log_message "INFO" "AI Agent API使用演示完成")
    (log_message "INFO" "========================================")
    
    t)))

;; 示例调用
(defun demo-usage ()
  "
  功能: 演示如何使用这个SKILL脚本
  "
  (format t "OpenClaw SKILL for TXT+CSV文件数据API使用说明：~%~%")
  
  (format t "1. 初始化AI Agent API:~%")
  (format t "   (ai-agent-api-demo \"your-agent-id\" \"Your AI Agent Name\")~%~%")
  
  (format t "2. 单独开通API:~%")
  (format t "   (setq api-key (open-ai-agent-api \"agent-001\" \"测试机器人\"))~%~%")
  
  (format t "3. 读取CSV数据:~%")
  (format t "   (setq csv1-data (get-csv-data \"csv1\" api-key))~%~%")
  
  (format t "4. 读取TXT数据:~%")
  (format t "   (setq txt1-data (get-txt-data \"txt1\" api-key))~%~%")
  
  (format t "5. 通用查询:~%")
  (format t "   (setq query-result (query-data \"csv2\" \"关键词\" api-key))~%~%")
  
  (format t "6. 续费API:~%")
  (format t "   (setq renew-result (renew-ai-agent-api \"agent-001\"))~%~%")
  
  (format t "7. 查看API状态:~%")
  (format t "   (setq status (get-api-status api-key))~%~%")
  
  (format t "详细日志请查看: ~A~%" *LOG_FILE*)
  (format t "API Key保存位置: ~A~%" *API_KEY_FILE*))

;; 自动加载时显示使用说明
(unless (fboundp 'main)
  (demo-usage))

;; 主函数（如果作为独立程序运行）
(defun main (argv)
  (declare (ignore argv))
  (demo-usage)
  (format t "~%要启动演示，请运行:~%")
  (format t "(ai-agent-api-demo \"your-agent-id\" \"Your AI Agent Name\")~%")
  0)

; ========================================
; 依赖声明（需要在OpenClaw环境中安装）
; ========================================
;; 需要的依赖包：
;; - drakma (HTTP客户端)
;; - flexi-streams (字符串处理)
;; - json (JSON解析)

;; 确保依赖可用
(eval-when (:compile-toplevel :load-toplevel :execute)
  (require 'drakma)
  (require 'flexi-streams)
  (require 'json))

;; 导出主要函数
(export '(
          ;; 核心功能
          open-ai-agent-api
          renew-ai-agent-api
          get-api-status
          get-csv-data
          get-txt-data
          query-data
          
          ;; 工具函数
          validate-api-key
          load-api-key
          save-api-key
          
          ;; 演示函数
          ai-agent-api-demo
          demo-usage
          
          ;; 主函数
          main
          
          ;; 全局变量
          *API_BASE_URL*
          *API_KEY_FILE*
          *LOG_FILE*
          *DEBUG_MODE*
          ))

;; 脚本结束标记
(format t "OpenClaw SKILL for TXT+CSV文件数据API加载完成~%")
(format t "API基础URL: ~A~%" *API_BASE_URL*)
(format t "使用 (demo-usage) 查看详细使用说明~%")
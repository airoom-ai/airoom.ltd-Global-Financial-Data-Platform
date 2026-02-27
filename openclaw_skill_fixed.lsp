;;;; openclaw_skill.lsp
;;;; OpenClaw SKILL for TXT+CSV文件数据API调用
;;;; 作者: AI Assistant
;;;; 日期: 2024-01-15
;;;; 版本: 1.0.0

;;;; ========================================
;;;; 全局配置
;;;; ========================================
(defparameter *API_BASE_URL* "http://8.217.246.209:8000")
(defparameter *API_KEY_FILE* "./api_key.txt")
(defparameter *LOG_FILE* "./api_call_log.txt")
(defparameter *DEBUG_MODE* t)

;;;; ========================================
;;;; 工具函数
;;;; ========================================

(defun log_message (level message)
  "日志记录函数"
  (let ((timestamp (format nil "~A" (get-internal-real-time))))
    (with-open-file (log-file *LOG_FILE* :direction :output :if-exists :append :if-does-not-exist :create)
      (format log-file "[~A] [~A] ~A~%" timestamp level message))
    (when *DEBUG_MODE*
      (format t "[~A] [~A] ~A~%" timestamp level message))))

(defun http-request (url method &key headers body)
  "通用的HTTP请求函数"
  (handler-case
      (progn
        (log_message "INFO" (format nil "HTTP ~A Request to: ~A" method url))
        (let ((response (drakma:http-request url
                                          :method (intern (string-upcase method) :keyword)
                                          :headers headers
                                          :content body
                                          :content-type (when body "application/json"))))
          (values response 200 nil)))
    (error (e)
      (log_message "ERROR" (format nil "HTTP Request failed: ~A" e))
      (values nil nil (format nil "~A" e)))))

(defun parse-json (json-string)
  "JSON解析函数"
  (handler-case
      (json:decode-json-from-string json-string)
    (error (e)
      (log_message "ERROR" (format nil "JSON解析失败: ~A" e))
      nil)))

(defun generate-json (data)
  "JSON生成函数"
  (handler-case
      (json:encode-json-to-string data)
    (error (e)
      (log_message "ERROR" (format nil "JSON生成失败: ~A" e))
      nil)))

(defun save-api-key (api-key agent-id agent-name)
  "保存API Key到文件"
  (handler-case
      (with-open-file (file *API_KEY_FILE* :direction :output :if-exists :supersede :if-does-not-exist :create)
        (format file "AGENT_ID=~A~%" agent-id)
        (format file "AGENT_NAME=~A~%" agent-name)
        (format file "API_KEY=~A~%" api-key)
        (format file "CREATE_TIME=~A~%" (format nil "~A" (get-internal-real-time))))
    (error (e)
      (log_message "ERROR" (format nil "保存API Key失败: ~A" e))
      nil)))

(defun load-api-key ()
  "从文件读取API Key"
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
            config)))
    (error (e)
      (log_message "ERROR" (format nil "读取API Key失败: ~A" e))
      nil)))

(defun validate-api-key (api-key)
  "验证API Key是否有效"
  (let* ((url (format nil "~A/api/data" *API_BASE_URL*))
         (headers (list (cons "X-API-Key" api-key)))
         (response (http-request url "GET" :headers headers)))

    (when response
      (let ((json-response (parse-json response)))
        (when json-response
          (let ((code (cdr (assoc :CODE json-response))))
            (eql code 200)))))))

;;;; ========================================
;;;; 核心功能函数
;;;; ========================================

(defun open-ai-agent-api (agent-id agent-name)
  "为AI Agent开通API，获取API Key"
  (log_message "INFO" (format nil "开始为AI Agent开通API: ID=~A, Name=~A" agent-id agent-name))

  (let* ((url (format nil "~A/api/charge/ai/open" *API_BASE_URL*))
         (body (generate-json `((:AGENT-ID . ,agent-id) (:AGENT-NAME . ,agent-name))))
         (headers (list (cons "Content-Type" "application/json")))
         (response (http-request url "POST" :headers headers :body body)))

    (when response
      (let ((json-response (parse-json response)))
        (when json-response
          (let ((code (cdr (assoc :CODE json-response)))
                (msg (cdr (assoc :MSG json-response))))

            (if (eql code 200)
                (let* ((data (cdr (assoc :DATA json-response)))
                       (api-key (cdr (assoc :API-KEY data)))
                       (pay-link (cdr (assoc :PAY-LINK data))))

                  (log_message "INFO" (format nil "AI Agent API开通成功: ~A" msg))
                  (save-api-key api-key agent-id agent-name)
                  api-key)

              (progn
                (log_message "ERROR" (format nil "AI Agent API开通失败: ~A" msg))
                nil))))))))

(defun renew-ai-agent-api (agent-id)
  "AI Agent续费API"
  (log_message "INFO" (format nil "开始为AI Agent续费: ID=~A" agent-id))

  (let* ((url (format nil "~A/api/charge/ai/renew" *API_BASE_URL*))
         (body (generate-json `((:AGENT-ID . ,agent-id))))
         (headers (list (cons "Content-Type" "application/json")))
         (response (http-request url "POST" :headers headers :body body)))

    (when response
      (let ((json-response (parse-json response)))
        (when json-response
          (let ((code (cdr (assoc :CODE json-response)))
                (msg (cdr (assoc :MSG json-response))))

            (if (eql code 200)
                (let* ((data (cdr (assoc :DATA json-response)))
                       (pay-link (cdr (assoc :PAY-LINK data)))
                       (new-expire (cdr (assoc :NEW-EXPIRE data))))

                  (log_message "INFO" (format nil "AI Agent API续费成功: ~A" msg))
                  `(:success t :message ,msg :pay-link ,pay-link :new-expire ,new-expire))

              (progn
                (log_message "ERROR" (format nil "AI Agent API续费失败: ~A" msg))
                `(:success nil :message ,msg)))))))))

(defun get-api-status (api-key)
  "获取API状态信息"
  (log_message "INFO" "获取API状态信息")

  (let* ((url (format nil "~A/api/data" *API_BASE_URL*))
         (headers (list (cons "X-API-Key" api-key)))
         (response (http-request url "GET" :headers headers)))

    (when response
      (let ((json-response (parse-json response)))
        (when json-response
          (let ((code (cdr (assoc :CODE json-response))))
            (if (eql code 200)
                (let* ((data (cdr (assoc :DATA json-response)))
                       (msg (cdr (assoc :MSG json-response)))
                       (api-key-type (cdr (assoc :API-KEY-TYPE json-response)))
                       (expire-time (cdr (assoc :EXPIRE-TIME json-response))))

                  (log_message "INFO" (format nil "API状态正常: ~A" msg))
                  `(:success t :message ,msg :data ,data :api-key-type ,api-key-type :expire-time ,expire-time))

              (let ((msg (cdr (assoc :MSG json-response))))
                (log_message "ERROR" (format nil "获取API状态失败: ~A" msg))
                `(:success nil :message ,msg)))))))))

(defun get-csv-data (file-type api-key)
  "读取CSV文件数据"
  (log_message "INFO" (format nil "读取CSV文件数据: ~A" file-type))

  (let* ((url (format nil "~A/api/data/~A" *API_BASE_URL* file-type))
         (headers (list (cons "X-API-Key" api-key)))
         (response (http-request url "GET" :headers headers)))

    (when response
      (let ((json-response (parse-json response)))
        (when json-response
          (let ((code (cdr (assoc :CODE json-response))))
            (if (eql code 200)
                (let* ((data (cdr (assoc :DATA json-response)))
                       (msg (cdr (assoc :MSG json-response)))
                       (update-time (cdr (assoc :UPDATE-TIME json-response))))

                  (log_message "INFO" (format nil "读取~A成功" file-type))
                  `(:success t :message ,msg :data ,data :update-time ,update-time :total ,(length data)))

              (let ((msg (cdr (assoc :MSG json-response))))
                (log_message "ERROR" (format nil "读取~A失败: ~A" file-type msg))
                `(:success nil :message ,msg)))))))))

(defun get-txt-data (file-type api-key)
  "读取TXT文件数据"
  (log_message "INFO" (format nil "读取TXT文件数据: ~A" file-type))

  (let* ((url (format nil "~A/api/data/~A" *API_BASE_URL* file-type))
         (headers (list (cons "X-API-Key" api-key)))
         (response (http-request url "GET" :headers headers)))

    (when response
      (let ((json-response (parse-json response)))
        (when json-response
          (let ((code (cdr (assoc :CODE json-response))))
            (if (eql code 200)
                (let* ((data (cdr (assoc :DATA json-response)))
                       (msg (cdr (assoc :MSG json-response)))
                       (update-time (cdr (assoc :UPDATE-TIME json-response))))

                  (log_message "INFO" (format nil "读取~A成功" file-type))
                  `(:success t :message ,msg :data ,data :update-time ,update-time :total ,(length data)))

              (let ((msg (cdr (assoc :MSG json-response))))
                (log_message "ERROR" (format nil "读取~A失败: ~A" file-type msg))
                `(:success nil :message ,msg)))))))))

(defun query-data (file-type keyword api-key)
  "通用查询接口"
  (log_message "INFO" (format nil "通用查询: 文件=~A, 关键词=~A" file-type (or keyword "无")))

  (let* ((query-params (if keyword
                          (format nil "?file=~A&keyword=~A" file-type (drakma:url-encode keyword))
                        (format nil "?file=~A" file-type)))
         (url (format nil "~A/api/data/query~A" *API_BASE_URL* query-params))
         (headers (list (cons "X-API-Key" api-key)))
         (response (http-request url "GET" :headers headers)))

    (when response
      (let ((json-response (parse-json response)))
        (when json-response
          (let ((code (cdr (assoc :CODE json-response))))
            (if (eql code 200)
                (let* ((data (cdr (assoc :DATA json-response)))
                       (msg (cdr (assoc :MSG json-response)))
                       (total (cdr (assoc :TOTAL json-response))))

                  (log_message "INFO" (format nil "查询成功，找到~A条匹配数据" total))
                  `(:success t :message ,msg :data ,data :total ,total))

              (let ((msg (cdr (assoc :MSG json-response))))
                (log_message "ERROR" (format nil "查询失败: ~A" msg))
                `(:success nil :message ,msg)))))))))

;;;; ========================================
;;;; 导出函数
;;;; ========================================
(export '(open-ai-agent-api
          renew-ai-agent-api
          get-api-status
          get-csv-data
          get-txt-data
          query-data
          validate-api-key
          load-api-key
          save-api-key
          *API_BASE_URL*
          *API_KEY_FILE*
          *LOG_FILE*
          *DEBUG_MODE*))

(format t "~%========================================~%")
(format t "OpenClaw SKILL 加载完成~%")
(format t "API基础URL: ~A~%" *API_BASE_URL*)
(format t "========================================~%")

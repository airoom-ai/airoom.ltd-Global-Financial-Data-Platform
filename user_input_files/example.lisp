;;;; example.lisp
;;;; TXT+CSV数据API SKILL的使用示例
;;;; 演示如何在实际应用中使用这个SKILL

(defpackage :txt-csv-data-api/example
  (:use :cl :txt-csv-data-api))

(in-package :txt-csv-data-api/example)

;; 示例1：AI Agent完整使用流程
(defun ai-agent-complete-workflow ()
  "
  演示AI Agent使用数据API的完整工作流程
  包括：开通API、验证、读取数据、查询等
  "
  (format t "=== AI Agent数据API完整使用流程 ===~%~%")
  
  ;; 1. 设置AI Agent信息
  (let ((agent-id "demo-agent-001")
        (agent-name "演示机器人")
        api-key)
    
    (format t "1. 初始化AI Agent: ID='~A', Name='~A'~%" agent-id agent-name)
    
    ;; 2. 尝试加载已有的API Key
    (let ((config (load-api-key)))
      (if config
          (progn
            (format t "2. 找到已保存的API Key配置~%")
            (setq api-key (gethash "API_KEY" config)))
        (progn
          (format t "2. 未找到已保存的API Key，需要开通新的API~%")
          
          ;; 3. 开通新的API
          (setq api-key (open-ai-agent-api agent-id agent-name))
          (if api-key
              (format t "   ✅ API开通成功，获得API Key: ~A~%" api-key)
            (progn
              (format t "   ❌ API开通失败，请检查网络连接或联系管理员~%")
              (return-from ai-agent-complete-workflow nil))))))
    
    ;; 4. 验证API Key
    (if (validate-api-key api-key)
        (format t "3. ✅ API Key验证通过，可以正常使用~%")
      (progn
        (format t "3. ❌ API Key无效或已过期，请重新开通~%")
        (return-from ai-agent-complete-workflow nil)))
    
    ;; 5. 获取API状态信息
    (let ((status (get-api-status api-key)))
      (if (getf status :success)
          (progn
            (format t "4. API状态信息:~%")
            (format t "   - 状态: ~A~%" (getf status :message))
            (format t "   - 类型: ~A~%" (getf status :api-key-type))
            (format t "   - 有效期: ~A~%" (getf status :expire-time))
            (format t "   - 数据更新时间:~%")
            (let ((data (getf status :data)))
              (when data
                (loop for (key . value) in data do
                      (format t "     * ~A: ~A~%" key value)))))
        (format t "4. ❌ 获取API状态失败: ~A~%" (getf status :message))))
    
    ;; 6. 读取CSV1数据示例
    (format t "~%5. 读取CSV1数据示例:~%")
    (let ((csv1-data (get-csv-data "csv1" api-key)))
      (if (getf csv1-data :success)
          (progn
            (format t "   ✅ 成功读取CSV1数据，共~D条记录~%" (getf csv1-data :total))
            (format t "   更新时间: ~A~%" (getf csv1-data :update-time))
            (format t "   前3条数据示例:~%")
            (let ((data (getf csv1-data :data)))
              (loop for i from 0 to (min 2 (1- (length data))) do
                    (format t "   [~D]: ~A~%" (1+ i) (elt data i)))))
        (format t "   ❌ 读取CSV1数据失败: ~A~%" (getf csv1-data :message))))
    
    ;; 7. 读取TXT1数据示例
    (format t "~%6. 读取TXT1数据示例:~%")
    (let ((txt1-data (get-txt-data "txt1" api-key)))
      (if (getf txt1-data :success)
          (progn
            (format t "   ✅ 成功读取TXT1数据，共~D条记录~%" (getf txt1-data :total))
            (format t "   更新时间: ~A~%" (getf txt1-data :update-time))
            (format t "   前3行数据示例:~%")
            (let ((data (getf txt1-data :data)))
              (loop for i from 0 to (min 2 (1- (length data))) do
                    (format t "   [~D]: ~A~%" (1+ i) (elt data i)))))
        (format t "   ❌ 读取TXT1数据失败: ~A~%" (getf txt1-data :message))))
    
    ;; 8. 使用通用查询示例
    (format t "~%7. 通用查询示例 (搜索关键词'测试'):~%")
    (let ((query-result (query-data "csv1" "测试" api-key)))
      (if (getf query-result :success)
          (progn
            (format t "   ✅ 查询成功，找到~D条匹配记录~%" (getf query-result :total))
            (format t "   匹配数据示例:~%")
            (let ((data (getf query-result :data)))
              (loop for i from 0 to (min 2 (1- (length data))) do
                    (format t "   [~D]: ~A~%" (1+ i) (elt data i)))))
        (format t "   ❌ 查询失败: ~A~%" (getf query-result :message))))
    
    ;; 9. 演示续费功能（仅作示例，不会实际执行）
    (format t "~%8. API续费功能演示:~%")
    (format t "   如需续费，请使用以下代码:~%")
    (format t "   (setq renew-info (renew-ai-agent-api \"~A\"))~%" agent-id)
    (format t "   然后访问返回的支付链接完成支付~%")
    
    (format t "~%=== AI Agent数据API使用演示完成 ===~%")
    t)))

;; 示例2：数据分析师工作流
(defun data-analyst-workflow ()
  "
  演示数据分析师如何使用这个SKILL进行数据分析
  "
  (format t "=== 数据分析师工作流程 ===~%~%")
  
  (let ((api-key "your-api-key-here"))  ;; 需要替换为实际的API Key
    
    (format t "1. 数据概览获取~%")
    (let ((status (get-api-status api-key)))
      (when (getf status :success)
        (format t "   ✅ 数据文件更新时间:~%")
        (let ((data (getf status :data)))
          (when data
            (loop for (key . value) in data do
                  (format t "     * ~A: ~A~%" key value))))))
    
    (format t "~%2. 批量数据获取~%")
    (let ((all-data '()))
      
      ;; 获取CSV1数据
      (let ((csv1-data (get-csv-data "csv1" api-key)))
        (when (getf csv1-data :success)
          (push (cons :csv1 (getf csv1-data :data)) all-data)
          (format t "   ✅ CSV1: ~D条记录~%" (length (getf csv1-data :data)))))
      
      ;; 获取CSV2数据
      (let ((csv2-data (get-csv-data "csv2" api-key)))
        (when (getf csv2-data :success)
          (push (cons :csv2 (getf csv2-data :data)) all-data)
          (format t "   ✅ CSV2: ~D条记录~%" (length (getf csv2-data :data)))))
      
      ;; 数据处理示例
      (format t "~%3. 数据分析示例~%")
      (dolist (data-entry all-data)
        (let ((source (car data-entry))
              (data (cdr data-entry)))
          (format t "   处理 ~A 数据:~%" source)
          (format t "     - 总记录数: ~D~%" (length data))
          
          ;; 简单的数据分析
          (when (and data (listp (car data)))
            (format t "     - 字段列表: ~A~%" (mapcar #'car (car data)))))))
    
    (format t "~%4. 高级查询示例~%")
    (format t "   使用不同关键词进行数据筛选:~%")
    
    (dolist (keyword '("产品" "价格" "库存"))
      (let ((result (query-data "csv1" keyword api-key)))
        (when (getf result :success)
          (format t "   ✅ 关键词'~A': 找到~D条记录~%" keyword (getf result :total))))))
  
  (format t "~%=== 数据分析师工作流程演示完成 ===~%"))

;; 示例3：错误处理和故障排除
(defun error-handling-example ()
  "
  演示错误处理和故障排除
  "
  (format t "=== 错误处理和故障排除示例 ===~%~%")
  
  ;; 1. 无效的API Key
  (format t "1. 测试无效API Key:~%")
  (let ((result (get-api-status "invalid-api-key")))
    (if (getf result :success)
        (format t "   ❌ 应该失败但成功了~%")
      (format t "   ✅ 正确处理了无效API Key: ~A~%" (getf result :message))))
  
  ;; 2. 无效的文件类型
  (format t "~%2. 测试无效文件类型:~%")
  (let ((result (get-csv-data "invalid-type" "test-api-key")))
    (if (getf result :success)
        (format t "   ❌ 应该失败但成功了~%")
      (format t "   ✅ 正确处理了无效文件类型: ~A~%" (getf result :message))))
  
  ;; 3. 日志查看示例
  (format t "~%3. 日志查看示例:~%")
  (format t "   查看API调用日志:~%")
  (format t "   (with-open-file (log *LOG_FILE* :direction :input)~%")
  (format t "     (loop for line = (read-line log nil nil)~%")
  (format t "           while line do~%")
  (format t "           (format t \"~A~%\")~%")
  (format t "           (sleep 0.1)))~%")
  
  ;; 4. API Key管理
  (format t "~%4. API Key管理示例:~%")
  (format t "   - 保存API Key: (save-api-key \"your-key\" \"agent-id\" \"agent-name\")~%")
  (format t "   - 加载API Key: (load-api-key)~%")
  (format t "   - 验证API Key: (validate-api-key \"your-key\")~%")
  
  (format t "~%=== 错误处理和故障排除示例完成 ===~%"))

;; 主示例函数
(defun run-examples ()
  "
  运行所有示例
  "
  (format t "TXT+CSV数据API SKILL使用示例~%")
  (format t "=======================================~%~%")
  
  (format t "选择要运行的示例:~%")
  (format t "1. AI Agent完整工作流程~%")
  (format t "2. 数据分析师工作流程~%")
  (format t "3. 错误处理和故障排除~%")
  (format t "4. 运行所有示例~%~%")
  
  (format t "请输入选项 (1-4): ")
  (let ((choice (read-line)))
    (case (parse-integer choice :junk-allowed t)
      (1 (ai-agent-complete-workflow))
      (2 (data-analyst-workflow))
      (3 (error-handling-example))
      (4 
       (ai-agent-complete-workflow)
       (format t "~%~%")
       (data-analyst-workflow)
       (format t "~%~%")
       (error-handling-example))
      (otherwise
       (format t "无效的选项，请输入1-4之间的数字~%"))))
  
  (format t "~%示例运行完成！~%"))

;; 导出示例函数
(export '(run-examples
          ai-agent-complete-workflow
          data-analyst-workflow
          error-handling-example))

;; 自动显示使用说明
(format t "TXT+CSV数据API SKILL示例文件加载完成~%")
(format t "使用 (txt-csv-data-api/example:run-examples) 运行示例~%")
(format t "或直接调用具体示例函数:~%")
(format t "  - (txt-csv-data-api/example:ai-agent-complete-workflow)~%")
(format t "  - (txt-csv-data-api/example:data-analyst-workflow)~%")
(format t "  - (txt-csv-data-api/example:error-handling-example)~%")
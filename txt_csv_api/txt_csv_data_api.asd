;;;; txt_csv_data_api.asd
;;;; 用于OpenClaw平台的ASD文件
;;;; 定义SKILL包的元数据和依赖

(asdf:defsystem "txt-csv-data-api"
  :version "1.0.0"
  :author "AI Assistant"
  :license "MIT"
  :depends-on ("drakma" "flexi-streams" "json")
  :components ((:file "openclaw_skill"))
  :description "TXT+CSV文件数据API调用SKILL，用于AI Agent访问数据文件"
  :long-description "这是一个用于OpenClaw平台的SKILL脚本，提供完整的TXT+CSV文件数据API调用功能，包括API开通、续费、数据读取、通用查询等功能。"
  :in-order-to ((test-op (test-op "txt-csv-data-api/tests"))))

(asdf:defsystem "txt-csv-data-api/tests"
  :depends-on ("txt-csv-data-api" "fiveam")
  :components ((:file "tests"))
  :description "TXT+CSV数据API SKILL的测试套件")
# InfluxDB Configuration
influxdb_username = "root"
influxdb_password = "root"
influxdb_database = "k6"

# Grafana Configuration
grafana_admin_user      = "admin"
grafana_admin_password  = "admin"
grafana_dashboard_path  = "/home/aaic/api-performance/grafana/dashboards"
grafana_datasource_path = "/home/aaic/api-performance/grafana/datasource.yaml"
grafana_dashboard_yaml  = "/home/aaic/api-performance/grafana/dashboard.yaml"

# MongoDB Configuration
mongodb_data_path = "/tmp/mongodb_data"

# WireMock Configuration
wiremock_mappings_path = "/home/aaic/api-performance/load/wiremock/mappings"

# K6 Load Test Script Path
k6_load_test_script = "/home/aaic/api-performance/scripts/load-test.js"
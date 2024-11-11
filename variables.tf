variable "influxdb_username" {
  description = "InfluxDB username for Chronograf"
  type        = string
}

variable "influxdb_password" {
  description = "InfluxDB password for Chronograf"
  type        = string
  sensitive   = true
}

variable "influxdb_database" {
  description = "InfluxDB database for Chronograf"
  type        = string
}

variable "grafana_admin_user" {
  description = "Grafana admin username"
  type        = string
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}

variable "grafana_dashboard_path" {
  description = "Absolute path for the Grafana dashboards"
  type        = string
}

variable "grafana_dashboard_yaml" {
  description = "Absolute path for the Grafana dashboard YAML file"
  type        = string
}

variable "grafana_datasource_path" {
  description = "Absolute path for the Grafana datasource YAML file"
  type        = string
}

variable "k6_load_test_script" {
  description = "Absolute path for the k6 load test script"
  type        = string
}

variable "wiremock_mappings_path" {
  description = "Absolute path for the WireMock mappings"
  type        = string
}

variable "mongodb_data_path" {
  description = "Absolute path for MongoDB data storage"
  type        = string
}

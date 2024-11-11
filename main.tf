terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.13.0"
    }
  }

  required_version = ">= 0.14"
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Define networks
resource "docker_network" "k6" {
  name = "k6"
}

resource "docker_network" "grafana" {
  name = "grafana"
}

# InfluxDB Container
resource "docker_image" "influxdb" {
  name         = "influxdb:1.8"
  keep_locally = false
}

resource "docker_container" "influxdb" {
  name  = "influxdb"
  image = docker_image.influxdb.name
  networks_advanced {
    name = docker_network.k6.name
  }
  networks_advanced {
    name = docker_network.grafana.name
  }

  ports {
    internal = 8086
    external = 8086
  }

  env = [
    "INFLUXDB_DB=k6"
  ]
}

# Grafana Container
resource "docker_image" "grafana" {
  name         = "grafana/grafana:8.5.21"
  keep_locally = false
}

resource "docker_container" "grafana" {
  name  = "grafana"
  image = docker_image.grafana.name
  networks_advanced {
    name = docker_network.grafana.name
  }

  ports {
    internal = 3000
    external = 3000
  }

  env = [
    "GF_AUTH_ANONYMOUS_ORG_ROLE=Admin",
    "GF_AUTH_ANONYMOUS_ENABLED=false",
    "GF_AUTH_BASIC_ENABLED=false",
    "GF_AUTH_BASIC_USERS=admin:admin",
    "GF_SERVER_SERVE_FROM_SUB_PATH=true"
  ]

  volumes {
    host_path      = var.grafana_dashboard_path
    container_path = "/var/lib/grafana/dashboards"
  }

  volumes {
    host_path      = var.grafana_dashboard_yaml
    container_path = "/etc/grafana/provisioning/dashboards/dashboard.yaml"
  }

  volumes {
    host_path      = var.grafana_datasource_path
    container_path = "/etc/grafana/provisioning/datasources/datasource.yaml"
  }
}

# Chronograf Container
resource "docker_image" "chronograf" {
  name         = "chronograf:1.8"
  keep_locally = false
}

resource "docker_container" "chronograf" {
  name  = "chronograf"
  image = docker_image.chronograf.name
  networks_advanced {
    name = docker_network.k6.name
  }

  ports {
    internal = 8888
    external = 8888
  }

  env = [
    "INFLUXDB_URL=http://influxdb:8086",
    "INFLUXDB_USERNAME=${var.influxdb_username}",
    "INFLUXDB_PASSWORD=${var.influxdb_password}",
    "INFLUXDB_DB=${var.influxdb_database}",
    "INFLUXDB_SKIP_VERIFY=true"
  ]

  depends_on = [
    docker_container.influxdb
  ]
}

# K6 Container
resource "docker_image" "k6" {
  name         = "grafana/k6"
  keep_locally = false
}

resource "docker_container" "k6" {
  name  = "k6"
  image = docker_image.k6.name
  networks_advanced {
    name = docker_network.k6.name
  }

  ports {
    internal = 6566
    external = 6566
  }

  env = [
    "K6_OUT=influxdb=http://influxdb:8086/${var.influxdb_database}"
  ]

  volumes {
    host_path      = var.k6_load_test_script
    container_path = "/scripts/load-test.js"
  }
  command = ["run", "/scripts/load-test.js"]
}

# WireMock Container
resource "docker_image" "wiremock" {
  name         = "rodolpheche/wiremock"
  keep_locally = false
}

resource "docker_container" "wiremock" {
  name  = "wiremock"
  image = docker_image.wiremock.name
  networks_advanced {
    name = docker_network.k6.name
  }
  ports {
    internal = 8080
    external = 8080
  }

  volumes {
    host_path      = var.wiremock_mappings_path
    container_path = "/home/wiremock/mappings"
  }
}

# MongoDB Container
resource "docker_image" "mongodb" {
  name         = "mongo"
  keep_locally = false
}

resource "docker_container" "mongodb" {
  name  = "mongodb"
  image = docker_image.mongodb.name
  networks_advanced {
    name = docker_network.k6.name
  }

  ports {
    internal = 27017
    external = 27017
  }

  volumes {
    host_path      = var.mongodb_data_path
    container_path = "/data/db"
  }
}
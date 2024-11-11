# System Architecture Overview
The system consists of several Docker containers managed through Terraform. The architecture includes:
    • **K6** for load testing.
    • **InfluxDB** for storing performance metrics.
    • **Grafana** for visualizing metrics.
    • **WireMock** for mocking API responses.
    • **MongoDB** for data storage.
    • **Chronograf** for querying and visualizing data in InfluxDB.
Each component is interconnected, simulating an environment where load tests run on an API that connects to a mocked external service (OpenMeteo) and MongoDB for storage.
# System Requirements
Hardware Requirements
    • Minimum 8 GB RAM.
    • Multi-core CPU (Intel i5 or higher recommended).
    • 20 GB of available storage.
# Software Requirements
    • Operating System: Ubuntu 18.04+ or equivalent Linux distribution (with Docker support).
    • Docker: Version 20.10.x or later.
    • Terraform: Version 0.14 or later.
    • Influxdb: Version 1.8
    • Cronograf: Version 1.8
    • Grafana: Version 8.5.x or later 
    • Docker Compose: Optional but recommended for local testing.
# Network Requirements
    • Open ports: 8086 (InfluxDB), 3000 (Grafana), 8888 (Chronograf), 6566 (K6), 8080 (WireMock), 27017 (MongoDB).
    • Reliable internet connection for downloading Docker images and dependencies.
# Prerequisites
    1. Install Docker Follow the official Docker installation guide for your operating system.
    2. Install Terraform Download and install Terraform by following the Terraform installation guide.
    3. Install Docker Compose (Optional but useful for testing) Install Docker Compose using the instructions here.
    4. Create Required Directories
        ◦ /home/aaic/api-performance/scripts/: Load test script (test.js) location.
        ◦ /home/aaic/api-performance/load/wiremock/mappings: WireMock mappings for mock responses.
        ◦ /home/aaic/api-performance/grafana/: Grafana configuration, including custom dashboards and datasources.
    5. Load Test and WireMock Mapping Files Ensure that you have the necessary K6 load test script (load-test.js) and WireMock mappings available in the correct directories.
# Step-by-Step Deployment
1. Initialize the Terraform Project
<p> terraform init </p>

2. Define the Networks
<p>
resource "docker_network" "k6" {
  name = "k6"
}
resource "docker_network" "grafana" {
  name = "grafana"
}
</p>

3. Deploy InfluxDB
</p> 
resource "docker_image" "influxdb" {
  name = "influxdb:1.8"
  keep_locally = false
}
resource "docker_container" "influxdb" {
  name    = "influxdb"
  image   = docker_image.influxdb.name
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
</p>

4. Deploy Grafana
<p>
resource "docker_image" "grafana" {
  name = "grafana/grafana:8.5.21"
  keep_locally = false
}

resource "docker_container" "grafana" {
  name    = "grafana"
  image   = docker_image.grafana.name
  networks_advanced {
    name = docker_network.grafana.name
  }

  ports {
    internal = 3000
    external = 3000
  }

  env = [
    "GF_AUTH_ANONYMOUS_ORG_ROLE=Admin",
    "GF_AUTH_ANONYMOUS_ENABLED=true",
    "GF_AUTH_BASIC_ENABLED=false",
    "GF_SERVER_SERVE_FROM_SUB_PATH=true"
  ]

  volumes {
    host_path      = var.grafana_dashboard_path
    container_path = "/var/lib/grafana/dashboards"   
  }
</p>

 <em><strong> Optional step if you don’t have dashboard use id in import dashboard 2587 </strong></em>
<p> 
  volumes {
    host_path      = var.grafana_dashboard_yaml
    container_path = "/etc/grafana/provisioning/dashboards/dashboard.yaml"
  }

  volumes {
    host_path      = var.grafana_datasource_path
    container_path = "/etc/grafana/provisioning/datasources/datasource.yaml"
  }
}
</p>

5. Deploy Chronograf
<p>
resource "docker_image" "chronograf" {
  name = "chronograf:1.8"
  keep_locally = false
}

resource "docker_container" "chronograf" {
  name    = "chronograf"
  image   = docker_image.chronograf.name
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
</p>

6. Deploy K6 Load Testing
<p>
resource "docker_image" "k6" {
  name = "grafana/k6"
  keep_locally = false
}

resource "docker_container" "k6" {
  name    = "k6"
  image   = docker_image.k6.name
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
</p>

7. Deploy WireMock
<p>
resource "docker_image" "wiremock" {
  name = "rodolpheche/wiremock"
  keep_locally = false
}
resource "docker_container" "wiremock" {
  name    = "wiremock"
  image   = docker_image.wiremock.name
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
</p>

8. Deploy MongoDB
<p>
resource "docker_image" "mongodb" {
  name = "mongo"
  keep_locally = false
}

resource "docker_container" "mongodb" {
  name    = "mongodb"
  image   = docker_image.mongodb.name
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
</p>

9. Also Create terraform.tfvars and variables.tf file at the same location where the main.tf is for achiving the terraform best practices.
<p>
Folder structure
main.tf
terraform.tfvars
variables.tf
scripts
-- test.js -- #load testing file for k6
load
-- wiremock
---- mappings
------ .json files
grafana
-- dashboards
---- dashboard.yaml  # optional
-- datasource.yaml
</p>

10. Plan and Apply the Terraform Configuration
Once the configuration is ready, deploy the infrastructure by running:
<p>
terraform plan
terraform apply
</p>

11. Check for the docker containers are running and what ports are they exposed to
<p> docker ps -a --> to see the containers in full details </p> 

12. Check the logs for the k6 container to see if the load test is working fine or not
<p> docker logs <k6_container_id> </p>

13. Go to browser and access the grafana by using port 3000.
<p> http:<ip_address>:<port> </p>

14. The data source is already added as influxdb as it is configured into our main.tf.
15. Go to create dashboards if you don’t have a pre-configured dashboard.
 Dashboard >  import dashboard > id <2578> for k6 load testing > load > select datasource > influxdb > import

16.  Viola! Your dashboard is created and monitor the metrics in Grafana

17. After sucessfull testing the container will auto exist because we will not be needing it anymore.
18. You can again start the container and run a load test manually to see the results again.
<p> docker start <container_id>
docker exec -it k6 k6 run /scripts/load-test.js </p>
(note: our k6 script (load-test.js) should be mounted into the k6 container at /scripts/load-test.js.)

19. To setup an alerts in grafana
    1. create a folder
    2. add the dashboard into that or move the current dashboard into the folder
    3. Go to create alert rules 
    4. Rule name > select folder > Group name > Create a query for alert (A) > Choose condition (B) > Define alert condititon > save and exit 
    5. in alerting rules now you can see the alerts. 
       
#### This is how the alerts can be set easily.
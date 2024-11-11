# System Architecture Overview
The system consists of several Docker containers managed through Terraform. The architecture includes:
<ol>
    <li> <em><strong>K6</em></strong> for load testing. </li>
    <li> <em><strong>InfluxDB</em></strong> for storing performance metrics </li>
    <li> <em><strong>Grafana</em></strong> for visualizing metrics. </li>
    <li> <em><strong>WireMock</em></strong> for mocking API responses. </li>
    <li> <em><strong>MongoDB</em></strong> for data storage. </li>
    <li> <em><strong>Chronograf</em></strong> for querying and visualizing data in InfluxDB. </li>
</ol>
Each component is interconnected, simulating an environment where load tests run on an API that connects to a mocked external service (OpenMeteo) and MongoDB for storage.

# System Requirements
Hardware Requirements
<ol>
    <li> Minimum 8 GB RAM. </li> 
    <li> Multi-core CPU (Intel i5 or higher recommended). </li>
    <li> 20 GB of available storage. </li>
</ol>

# Software Requirements
<ol>
    <li> Operating System: Ubuntu 18.04+ or equivalent Linux distribution (with Docker support). </li>
    <li> Docker: Version 20.10.x or later. </li>
    <li> Terraform: Version 0.14 or later. </li>
    <li> Influxdb: Version 1.8 </li>
    <li> Cronograf: Version 1.8 </li>
    <li> Grafana: Version 8.5.x or later </li>
    <li> Docker Compose: Optional but recommended for local testing. </li>
</ol>

# Network Requirements
<ol>
    <li> Open ports: 8086 (InfluxDB), 3000 (Grafana), 8888 (Chronograf), 6566 (K6), 8080 (WireMock), 27017 (MongoDB). </li>
    <li> Reliable internet connection for downloading Docker images and dependencies.</li>
</ol>    

# Prerequisites
<ol>
    <li> Install Docker Follow the official Docker installation guide for your operating system. </li>
    <li> Install Terraform Download and install Terraform by following the Terraform installation guide. </li>
    <li> Install Docker Compose (Optional but useful for testing) Install Docker Compose using the instructions here. </li>
    <li> Create Required Directories
    <ul>
        <li> /home/aaic/api-performance/scripts/: Load test script (test.js) location. </li>
        <li> /home/aaic/api-performance/load/wiremock/mappings: WireMock mappings for mock responses.</li>
        <li> /home/aaic/api-performance/grafana/: Grafana configuration, including custom dashboards and datasources.</li>
    </ul>
    <li> Load Test and WireMock Mapping Files Ensure that you have the necessary K6 load test script (load-test.js) and WireMock mappings available in the correct directories.</li>
</ol>

# Step-by-Step Deployment
1. Initialize the Terraform Project
```
terraform init 
```
2. Define the Networks
```
resource "docker_network" "k6" {
  name = "k6"
}
resource "docker_network" "grafana" {
  name = "grafana"
}

```

3. Deploy InfluxDB
 
```
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
```

4. Deploy Grafana
```
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
  ```

 <em><strong> Optional step if you don’t have dashboard use id in import dashboard 2587 </strong></em>
```
volumes {
    host_path      = var.grafana_dashboard_yaml
    container_path = "/etc/grafana/provisioning/dashboards/dashboard.yaml"
  }

  volumes {
    host_path      = var.grafana_datasource_path
    container_path = "/etc/grafana/provisioning/datasources/datasource.yaml"
  }
}```    


5. Deploy Chronograf
```
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
```

6. Deploy K6 Load Testing

```
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
```

7. Deploy WireMock
```
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
```

8. Deploy MongoDB
```
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
```

9. Also Create terraform.tfvars and variables.tf file at the same location where the main.tf is for achiving the terraform best practices.

<em><strong> Folder structure </em></strong>
```
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
```

10. Plan and Apply the Terraform Configuration
Once the configuration is ready, deploy the infrastructure by running:
```
terraform plan
terraform apply
```

11. Check for the docker containers are running and what ports are they exposed to
``` 
docker ps -a  # to see the containers in full details 
```

12. Check the logs for the k6 container to see if the load test is working fine or not
```
docker logs <k6_container_id>
```

13. Go to browser and access the grafana by using port 3000.
```
http:<ip_address>:<port>
``` 

14. The data source is already added as influxdb as it is configured into our <em><strong> main.tf </em></strong>

15. Go to create dashboards if you don’t have a pre-configured dashboard.
<em></strong> Dashboard -->  import dashboard --> id <2578> for k6 load testing --> load --> select datasource --> influxdb --> import </em></strong>

16.  Viola! Your dashboard is created and monitor the metrics in Grafana

17. After sucessfull testing the container will auto exist because we will not be needing it anymore.

18. You can again start the container and run a load test manually to see the results again.
```
docker start <container_id>
docker exec -it k6 k6 run /scripts/load-test.js
```
(note: our k6 script (load-test.js) should be mounted into the k6 container at /scripts/load-test.js.)

19. To setup an alerts in grafana
<ol>
    <li> create a folder </li>
    <li> add the dashboard into that or move the current dashboard into the folder. </li>
    <li> Go to create alert rules </li>
    <li> Rule name > select folder > Group name > Create a query for alert (A) > Choose condition (B) > Define alert condititon > save and exit </li>
    <li> in alerting rules now you can see the alerts. </li>
</ol>    

#### This is how the alerts can be set easily.
resource "confluent_environment" "development" {
  display_name = "Development"

  
}



#This part creates cluster inside environment
resource "confluent_kafka_cluster" "basic" {
  display_name = "Terraform_Dev"
  availability = "SINGLE_ZONE"
  cloud        = "AWS"
  region       = "us-east-2"
  basic {}

  environment {
    
  id=confluent_environment.development.id
 
  }

  
}

##This part creates service account

resource "confluent_service_account" "terraform_dev" {
  display_name = "terraform_dev"
  description  = "terraform created"

  
}

##This part assigned role to the user  account created
resource "confluent_role_binding" "terraform_user-kafka-cluster-admin" {
  principal   = "User:${confluent_service_account.terraform_dev.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.basic.rbac_crn
}

# This part creates API Key for service account
resource "confluent_api_key" "terraform_Created_APIKEY" {
  display_name = "terraform_Created_APIKEY-kafka-api-key"
  description  = "Kafka API Key that is owned by 'terraform_dev' service account"
  owner {
    id          = confluent_service_account.terraform_dev.id
    api_version = confluent_service_account.terraform_dev.api_version
    kind        = confluent_service_account.terraform_dev.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.basic.id
    api_version = confluent_kafka_cluster.basic.api_version
    kind        = confluent_kafka_cluster.basic.kind

    environment {
    id = confluent_environment.development.id
       
    }
  }
    
  
  

 
}
   

# This part creates a topic 

resource "confluent_kafka_topic" "Fleet_Location" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  topic_name    = "Fleet_Location"
  rest_endpoint      = confluent_kafka_cluster.basic.rest_endpoint
  partitions_count   = 2
  credentials {
    key   = confluent_api_key.terraform_Created_APIKEY.id
    secret = confluent_api_key.terraform_Created_APIKEY.secret
  }
}
resource "confluent_kafka_topic" "Fleet_User" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  topic_name    = "Fleet_User"
  partitions_count   = 2
  rest_endpoint      = confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key   = confluent_api_key.terraform_Created_APIKEY.id
    secret = confluent_api_key.terraform_Created_APIKEY.secret
  }
}

resource "confluent_kafka_topic" "real_time_location" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  topic_name    = "real_time_location"
  rest_endpoint      = confluent_kafka_cluster.basic.rest_endpoint
  partitions_count   = 2
  credentials {
    key   = confluent_api_key.terraform_Created_APIKEY.id
    secret = confluent_api_key.terraform_Created_APIKEY.secret
  }
}

  
resource "confluent_ksql_cluster" "example" {
  display_name = "example"
  csu          = 4
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  credential_identity {
    id = confluent_service_account.terraform_dev.id
  }
  environment {
    id = confluent_environment.development.id
    
     
  }
  


  
}

#creating datagen source connector
resource "confluent_connector" "datagen-source" {
  environment {
    id = confluent_environment.development.id
    
  }
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  config_sensitive = {}

  config_nonsensitive = {
    "connector.class"          = "DatagenSource"
    "name"                     = "Fleet_Location_Connector"
    "kafka.auth.mode"          = "SERVICE_ACCOUNT"
    "kafka.service.account.id" = confluent_service_account.terraform_dev.id
    "kafka.topic"              = confluent_kafka_topic.Fleet_Location.topic_name
    "output.data.format"       = "JSON"
    "quickstart"               = "FLEET_MGMT_LOCATION"
    "tasks.max"                = "1"
  }


  depends_on = [
    confluent_api_key.terraform_Created_APIKEY,
  ]
}
resource "confluent_connector" "datagen-source2" {
  environment {
    id = confluent_environment.development.id
    
  }
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  config_sensitive = {}

  config_nonsensitive = {
    "connector.class"          = "DatagenSource"
    "name"                     = "Fleet_User_Connector"
    "kafka.auth.mode"          = "SERVICE_ACCOUNT"
    "kafka.service.account.id" = confluent_service_account.terraform_dev.id
    "kafka.topic"              = confluent_kafka_topic.Fleet_User.topic_name
    "output.data.format"       = "JSON"
    "quickstart"               = "FLEET_MGMT_DESCRIPTION"
    "tasks.max"                = "1"
  }


  depends_on = [
    confluent_api_key.terraform_Created_APIKEY,
  ]
}

resource "confluent_connector" "mongo-db-sink" {
  environment {
      id = confluent_environment.development.id
  }
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }

  
  config_sensitive = {
    "connection.password" = var.mongo_password,
  }

  
  config_nonsensitive = {
    "connector.class"          = "MongoDbAtlasSink"
    "name"                     = "confluent-mongodb-sink"
    "kafka.auth.mode"          = "SERVICE_ACCOUNT"
    "kafka.service.account.id" = confluent_service_account.terraform_dev.id
    "connection.host"          = var.mongo_host
    "connection.user"          = var.mongo_username
    "input.data.format"        = "JSON"
    "topics"                   = confluent_kafka_topic.real_time_location.topic_name
    "max.num.retries"          = "3"
    "retries.defer.timeout"    = "5000"
    "max.batch.size"           = "0"
    "database"                 = "real_time_location"
    "collection"               = "real_time_location"
    "tasks.max"                = "1"
  }

}


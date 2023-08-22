variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key (also referred as Cloud API ID)"
  type        = string
  default = " "   #Add your API Key created during pre-requsite
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret"
  type        = string
  sensitive   = true
  default = " "    #Add your API secret created during pre-requsite
}

variable "mongo_host {
  description = "Add your Atlas Host"
  type        = string
  sensitive   = true
  default = " "    # Add your mongohost 
}

variable "mongo_username {
  description = "Add your mongoDB Atlas Username"
  type        = string
  sensitive   = true
  default = " "    # Add your username
}

variable "mongo_password{
  description = "Add your mongoDB Atlas password"
  type        = string
  sensitive   = true
  default = " "    # Add your password
}

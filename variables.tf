variable "project_id" {
  description = "The GCP Project ID"
}

variable "region" {
  description = "The GCP region to deploy resources"
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone to deploy resources"
  default     = "us-central1-a"
}

variable "cluster_name" {
  description = "The name of the GKE cluster"
  default     = "time-api-cluster"
}

variable "network_name" {
  description = "The name of the VPC network"
}

variable "subnet_name" {
  description = "The name of the subnet"
  default     = "time-api-subnet"
}

variable "subnet_ip_range" {
  description = "The IP range for the subnet"
  default     = "10.0.0.0/24"
}



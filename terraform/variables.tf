variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone for GKE cluster"
  type        = string
  default     = "us-central1-a"
}

variable "cluster_name" {
  description = "Name for the GKE cluster and related resources"
  type        = string
  default     = "hello-gke"
}

variable "app_name" {
  description = "Application name (used for Artifact Registry repo)"
  type        = string
  default     = "hello-app"
}

variable "node_count" {
  description = "Number of nodes in the GKE node pool"
  type        = number
  default     = 2
}

variable "machine_type" {
  description = "GCE machine type for GKE nodes"
  type        = string
  default     = "e2-medium"
}

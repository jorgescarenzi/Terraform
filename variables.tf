#variables

variable "server_type" {
  type        = string
  description = "Instance type"
  default     = "t3.nano"

}

variable "server_count_public" {
  type        = number
  description = "Instance count"
  default     = 1

}

variable "server_count_private" {
  type        = number
  description = "Instance count"
  default     = 3

}

variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}
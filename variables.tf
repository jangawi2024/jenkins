variable "vpc_id" {
  description = "The ID of the VPC where the subnet will be created."
  type        = string
  default     = "vpc-0b7663962ba7082cb"
}

variable "subnet_cidr" {
  description = "The CIDR block for the new subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "The availability zone for the new subnet."
  type        = string
  default     = "us-east-1a"
}
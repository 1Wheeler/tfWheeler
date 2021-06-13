provider "aws" {
  region     = "us-west-1"
  access_key = var.access_key
  secret_key = var.secret_key
}
 
resource "aws_kms_key" "kms-efs-gptappshare" {
  description             = "KMS key for EFS encryption"
  deletion_window_in_days = 7
}
 
resource "aws_kms_alias" "alias-efs-gptappshare" {
  name          = "alias/efs/${var.efs-name}"
  target_key_id = "${aws_kms_key.kms-efs-gptappshare.key_id}"
}
 
resource "aws_efs_file_system" "efs" {
  creation_token = "${var.efs-name}"
  encrypted = true
  kms_key_id = "${aws_kms_key.kms-efs-gptappshare.arn}"
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
  performance_mode = "generalPurpose"
  throughput_mode = "bursting"
  tags = {
    Name = "${join("-", ["${var.efs-name}", "${var.client}", "EFS"])}"
    Environment = "${var.environment}"
    BackMeUpEvery4Hours = "true"
  }
}
resource "aws_efs_mount_target" "az1" {
  count = length(var.subnet-az1) > 4 ? 1 : 0
  file_system_id = "${aws_efs_file_system.efs.id}"
  subnet_id      = var.subnet-az1
}
resource "aws_efs_mount_target" "az2" {
  count = length(var.subnet-az2) > 4 ? 1 : 0
  file_system_id = "${aws_efs_file_system.efs.id}"
  subnet_id      = var.subnet-az2
}
 
resource "aws_efs_mount_target" "az3" {
  count = length(var.subnet-az3) > 4 ? 1 : 0
  file_system_id = "${aws_efs_file_system.efs.id}"
  subnet_id      = var.subnet-az3
}
resource "aws_efs_file_system_policy" "policy" {
  file_system_id = "${aws_efs_file_system.efs.id}"
 
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "ExamplePolicy01",
    "Statement": [
        {
            "Sid": "ExampleSatement01",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Resource": "${aws_efs_file_system.efs.arn}",
            "Action": [
				"elasticfilesystem:ClientRootAccess",
                "elasticfilesystem:ClientMount",
                "elasticfilesystem:ClientWrite"
            ],
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        }
    ]
}
POLICY
}
 
# If environment name includes "DR", region is US East 1. 
locals {
  region = var.environment == "R" ? "us-east-1" : "us-west-1" 
}
variable "client"{
  description = "Name of the client"
  type        = string 
  default     = "Morpheus"
}
variable "environment"{
  default     = ""
}
variable "subnet-az1" {
}
variable "subnet-az2" {
}
variable "subnet-az3" {
}
 
variable "efs-name" {
  default = ""
}
 
variable "access_key"{
  description = "Access Key"
  default = ""
}
 
variable "secret_key" {
  description = "Secret Key"
  default = ""
}
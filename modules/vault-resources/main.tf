#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

terraform {
  required_version = ">=1.0.0"

  required_providers {
    aws = {
      version = ">= 3.45.0"
      source  = "hashicorp/aws"
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_dynamodb_table" "vault_table" {
  name         = format("%s-vault-table", var.cluster_name)
  billing_mode = var.dynamo_billing_mode
  hash_key     = "Path"
  range_key    = "Key"

  attribute {
    name = "Path"
    type = "S"
  }
  attribute {
    name = "Key"
    type = "S"
  }

  write_capacity = var.dynamo_billing_mode == "PROVISIONED" ? var.dynamo_provisioned_capacity.write : 0
  read_capacity  = var.dynamo_billing_mode == "PROVISIONED" ? var.dynamo_provisioned_capacity.read : 0

  tags = var.tags
}

resource "aws_kms_key" "vault_key" {
  description = "Key for vault in streamnative pulsar cluster"
}

resource "aws_kms_alias" "vault_key" {
  name          = format("alias/%s-vault-key", var.cluster_name)
  target_key_id = aws_kms_key.vault_key.id
}

data "aws_iam_policy_document" "vault_role_policy" {
  statement {
    actions = [
      "dynamodb:List*",
      "dynamodb:DescribeReservedCapacity*",
      "dynamodb:DescribeLimits",
      "dynamodb:DescribeTimeToLive"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "dynamodb:DescribeLimits",
      "dynamodb:DescribeTimeToLive",
      "dynamodb:ListTagsOfResource",
      "dynamodb:DescribeReservedCapacityOfferings",
      "dynamodb:DescribeReservedCapacity",
      "dynamodb:ListTables",
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:CreateTable",
      "dynamodb:DeleteItem",
      "dynamodb:GetItem",
      "dynamodb:GetRecords",
      "dynamodb:PutItem",
      "dynamodb:Query",
      "dynamodb:UpdateItem",
      "dynamodb:Scan",
      "dynamodb:DescribeTable"
    ]
    resources = [aws_dynamodb_table.vault_table.arn]
  }

  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    resources = [aws_kms_key.vault_key.arn]
  }

  statement {
    actions = [
      "sts:GetCallerIdentity"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "vault_sts_policy" {
  statement {
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [format("arn:%s:iam::%s:oidc-provider/%s", var.aws_partition, data.aws_caller_identity.current.account_id, var.oidc_issuer)]
    }
    condition {
      test     = "StringLike"
      values   = [format("system:serviceaccount:%s:%s", var.pulsar_namespace, var.service_account_name)]
      variable = format("%s:sub", var.oidc_issuer)
    }
  }
}

resource "aws_iam_role" "vault" {
  name               = format("%s-vault-role", var.cluster_name)
  description        = format("Role assumed by EKS ServiceAccount %s", var.service_account_name)
  assume_role_policy = data.aws_iam_policy_document.vault_sts_policy.json
  tags               = var.tags

  inline_policy {
    name   = format("%s-vault-base-policy", var.cluster_name)
    policy = data.aws_iam_policy_document.vault_role_policy.json
  }
}
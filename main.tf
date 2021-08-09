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

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "17.1.0"

  cluster_iam_role_name    = format("%s-role", var.cluster_name)
  cluster_name             = var.cluster_name
  cluster_version          = var.cluster_version
  enable_irsa              = var.enable_irsa
  kubeconfig_output_path   = var.kubeconfig_output_path
  map_accounts             = var.map_additional_aws_accounts
  map_roles                = var.map_additional_iam_roles
  map_users                = var.map_additional_iam_users
  subnets                  = local.cluster_subnet_ids
  vpc_id                   = var.vpc_id
  wait_for_cluster_timeout = var.wait_for_cluster_timeout // This was added in version 17.1.0, and if set above 0, causes TF to crash.
  write_kubeconfig         = var.write_kubeconfig

  node_groups = local.node_groups

  node_groups_defaults = {
    additional_tags = merge({
      "k8s.io/cluster-autoscaler/enabled"                      = "true",
      format("k8s.io/cluster-autoscaler/%s", var.cluster_name) = "owned",
      },
      var.additional_tags
    )
    subnets = var.private_subnet_ids
  }

  tags = {
    format("k8s.io/cluster/%s", var.cluster_name) = "owned",
  }
}

resource "kubernetes_namespace" "sn_system" {
  metadata {
    name = "sn-system"
  }
  depends_on = [
    module.eks
  ]
}

resource "kubernetes_namespace" "pulsar" {
  count = var.pulsar_namespace_create ? 1 : 0
  metadata {
    name = var.pulsar_namespace
  }
  depends_on = [
    module.eks
  ]
}

resource "kubernetes_namespace" "istio" {
  count = var.enable_istio_operator ? 1 : 0
  metadata {
    name = "istio-system"
  }
  depends_on = [
    module.eks
  ]
}
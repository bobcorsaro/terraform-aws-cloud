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

output "role_arn" {
  value       = aws_iam_role.tiered_storage.arn
  description = "The arn of the role used for Pulsar's tiered storage offloading. This needs to be annotated on the corresponding Kubernetes Service account in order for IRSA to work properly, e.g. \"eks.amazonaws.com/role-arn\" : \"<this_arn>\""
}

output "role_name" {
  value       = aws_iam_role.tiered_storage.name
  description = "The name of the role used for Pulsar's tiered storage offloading"
}

output "s3_bucket" {
  value       = aws_s3_bucket.pulsar_offload.bucket
  description = "The name of the bucket used for Pulsar's tiered storage offloading"
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.pulsar_offload.arn
  description = "The arn of the bucket used for Pulsar's tiered storage offloading"
}
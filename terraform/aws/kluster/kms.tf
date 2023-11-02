# resource "aws_kms_key" "ebs" {
#   description             = "Tenant managed key to encrypt EKS managed node group volumes"
#   deletion_window_in_days = 7
# }

# resource "aws_kms_alias" "ebs" {
#   name          = "alias/${var.tenant}/ebs-${var.sid}"
#   target_key_id = aws_kms_key.ebs.key_id
# }

# module "ebs_csi_role" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#   version = "5.20.0"

#   role_name             = "ebs-csi-${var.cluster_name}"
#   attach_ebs_csi_policy = true

#   ebs_csi_kms_cmk_ids = [aws_kms_key.ebs.arn]

#   oidc_providers = {
#     main = {
#       provider_arn               = module.eks.oidc_provider_arn
#       namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
#     }
#   }
# }

# This policy is required for the KMS key used for EKS root volumes, so the cluster is allowed to enc/dec/attach encrypted EBS volumes
# data "aws_iam_policy_document" "ebs" {
#   # Copy of default KMS policy that lets you manage it
#   statement {
#     sid       = "Enable IAM User Permissions"
#     actions   = ["kms:*"]
#     resources = ["*"]

#     principals {
#       type        = "AWS"
#       identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
#     }
#   }

#   # Required for EKS
#   statement {
#     sid = "Allow service-linked role use of the CMK"
#     actions = [
#       "kms:Encrypt",
#       "kms:Decrypt",
#       "kms:ReEncrypt*",
#       "kms:GenerateDataKey*",
#       "kms:DescribeKey"
#     ]
#     resources = ["*"]

#     principals {
#       type = "AWS"
#       identifiers = [
#         "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling", # required for the ASG to manage encrypted volumes for nodes
#         module.eks.cluster_iam_role_arn,                                                                                                            # required for the cluster / persistentvolume-controller to create encrypted PVCs
#         module.ebs_csi_role.iam_role_arn
#       ]
#     }
#   }

#   statement {
#     sid       = "Allow attachment of persistent resources"
#     actions   = ["kms:CreateGrant"]
#     resources = ["*"]

#     principals {
#       type = "AWS"
#       identifiers = [
#         "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling", # required for the ASG to manage encrypted volumes for nodes
#         module.eks.cluster_iam_role_arn,                                                                                                            # required for the cluster / persistentvolume-controller to create encrypted PVCs
#         module.ebs_csi_role.iam_role_arn
#       ]
#     }

#     condition {
#       test     = "Bool"
#       variable = "kms:GrantIsForAWSResource"
#       values   = ["true"]
#     }
#   }
# }

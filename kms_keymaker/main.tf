# -- Variables --

variable "ec2_kms_arns" {
  default     = []
  description = "ARN(s) of EC2 roles permitted access to KMS"
}

variable "env_name" {
  description = "Environment name"
}

variable "region" {
  default     = "us-west-2"
  description = "AWS Region"
}

# -- Data Sources --

data "aws_caller_identity" "current" {
}

data "aws_iam_policy_document" "kms" {
  # Allow root users in
  statement {
    actions = [
      "kms:*",
    ]
    principals {
      type        = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
    resources = [
      "*",
    ]
  }

  # allow an EC2 instance role to use KMS
  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    principals {
      type        = "AWS"
      identifiers = concat(
        var.ec2_kms_arns
      )
    }
    resources = [
      "*",
    ]
  }

  # Allow CloudWatch Events and SNS Access
  statement {
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt",
    ]
    resources = [
      "*",
    ]
    principals {
      type        = "Service"
      identifiers = [
        "events.amazonaws.com",
        "sns.amazonaws.com",
      ]
    }
  }
}

# -- Resources --

resource "aws_kms_key" "login-dot-gov-keymaker" {
  enable_key_rotation = true
  description         = "${var.env_name}-login-dot-gov-keymaker"
  policy              = data.aws_iam_policy_document.kms.json
}

resource "aws_kms_alias" "login-dot-gov-keymaker-alias" {
  name          = "alias/${var.env_name}-login-dot-gov-keymaker"
  target_key_id = aws_kms_key.login-dot-gov-keymaker.key_id
}

# -- Outputs --

output "keymaker_arn" {
  description = "ARN of the login-dot-gov-keymaker KMS key."
  value = aws_kms_key.login-dot-gov-keymaker.arn
}

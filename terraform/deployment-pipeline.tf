resource "aws_codestarconnections_connection" "github" {
  name          = "github-connection"
  provider_type = "GitHub"
}

resource "aws_s3_bucket" "deployment-pipeline" {
  bucket        = "${var.cluster_name}-deployment-pipeline"
  force_destroy = true

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "deployment-pipeline" {
  bucket = aws_s3_bucket.deployment-pipeline.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_codepipeline" "deployment-pipeline" {
  name     = "${var.cluster_name}-deployment-pipeline"
  role_arn = aws_iam_role.deployment-pipeline-codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.deployment-pipeline.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = "tsub/eks-sandbox"
        BranchName       = "master"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Plan"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["plan_output"]
      version          = "1"
      run_order        = 1

      configuration = {
        ProjectName = aws_codebuild_project.deployment-pipeline.name

        EnvironmentVariables = jsonencode([{
          name  = "TF_CMD"
          value = "plan -input=false -out=tfplan"
        }])
      }
    }

    action {
      name      = "ManualApproval"
      category  = "Approval"
      owner     = "AWS"
      provider  = "Manual"
      version   = "1"
      run_order = 2

      configuration = {
        CustomData         = "Review the `Plan` action result."
        ExternalEntityLink = "https://${local.region}.console.aws.amazon.com/codesuite/codebuild/${local.account_id}/projects/${var.cluster_name}-deployment-pipeline/history?region=${local.region}"
      }
    }

    action {
      name             = "Apply"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["plan_output"]
      output_artifacts = ["apply_output"]
      version          = "1"
      run_order        = 3

      configuration = {
        ProjectName = aws_codebuild_project.deployment-pipeline.name

        EnvironmentVariables = jsonencode([{
          name  = "TF_CMD"
          value = "apply -input=false tfplan"
        }])
      }
    }
  }
}

resource "aws_codebuild_project" "deployment-pipeline" {
  name         = "${var.cluster_name}-deployment-pipeline"
  service_role = aws_iam_role.deployment-pipeline-codebuild.arn

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "TF_VERSION"
      value = "0.14.7"
    }

    environment_variable {
      name  = "KUBECTL_URL"
      value = "https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/kubectl"
    }

    environment_variable {
      name  = "TF_VAR_cluster_name"
      value = var.cluster_name
    }

    environment_variable {
      name  = "TF_VAR_route53_sandbox_zone"
      value = var.route53_sandbox_zone
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = file("${path.module}/files/codebuild/deployment-pipeline.yml")
  }

  artifacts {
    type = "CODEPIPELINE"
  }
}

resource "aws_iam_role" "deployment-pipeline-codepipeline" {
  name = "${var.cluster_name}-deployment-pipeline-codepipeline"
  path = "/service-role/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"

        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "deployment-pipeline-codepipeline" {
  name   = "${var.cluster_name}-deployment-pipeline-codepipeline"
  path   = "/service-role/"
  policy = file("${path.module}/files/aws_iam_policy/deployment-pipeline-codepipeline.json")
}

resource "aws_iam_role_policy_attachment" "deployment-pipeline-codepipeline" {
  role       = aws_iam_role.deployment-pipeline-codepipeline.name
  policy_arn = aws_iam_policy.deployment-pipeline-codepipeline.arn
}

resource "aws_iam_role" "deployment-pipeline-codebuild" {
  name = "${var.cluster_name}-deployment-pipeline-codebuild"
  path = "/service-role/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"

        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "deployment-pipeline-codebuild" {
  name   = "${var.cluster_name}-deployment-pipeline-codebuild"
  path   = "/service-role/"
  policy = file("${path.module}/files/aws_iam_policy/deployment-pipeline-codebuild.json")
}

resource "aws_iam_role_policy_attachment" "deployment-pipeline-codebuild" {
  role       = aws_iam_role.deployment-pipeline-codebuild.name
  policy_arn = aws_iam_policy.deployment-pipeline-codebuild.arn
}

resource "aws_iam_role_policy_attachment" "deployment-pipeline-codebuild-terraform" {
  role       = aws_iam_role.deployment-pipeline-codebuild.name
  policy_arn = data.aws_iam_policy.administrator.arn
}

resource "aws_codestarnotifications_notification_rule" "deployment-pipeline" {
  name        = "deployment-pipeline-notification"
  resource    = aws_codepipeline.deployment-pipeline.arn
  detail_type = "BASIC"

  event_type_ids = [
    "codepipeline-pipeline-pipeline-execution-failed",
    "codepipeline-pipeline-pipeline-execution-canceled",
    "codepipeline-pipeline-pipeline-execution-started",
    "codepipeline-pipeline-pipeline-execution-resumed",
    "codepipeline-pipeline-pipeline-execution-succeeded",
    "codepipeline-pipeline-pipeline-execution-superseded",
    "codepipeline-pipeline-manual-approval-failed",
    "codepipeline-pipeline-manual-approval-needed",
    "codepipeline-pipeline-manual-approval-succeeded",
  ]

  target {
    type    = "AWSChatbotSlack"
    address = var.aws_chatbot_arn_for_slack
  }
}

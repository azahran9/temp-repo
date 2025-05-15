# CodePipeline and CI/CD resources

# S3 bucket for artifacts
resource "aws_s3_bucket" "artifacts_bucket" {
  bucket = "${var.project_name}-artifacts-${random_string.suffix.result}"
  force_destroy = true

  tags = {
    Name        = "${var.project_name}-artifacts"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 bucket policy
resource "aws_s3_bucket_policy" "artifacts_bucket_policy" {
  bucket = aws_s3_bucket.artifacts_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:GetObjectVersion",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.artifacts_bucket.arn}",
          "${aws_s3_bucket.artifacts_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:GetObjectVersion",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.artifacts_bucket.arn}",
          "${aws_s3_bucket.artifacts_bucket.arn}/*"
        ]
      }
    ]
  })
}

# IAM role for CodeBuild
resource "aws_iam_role" "codebuild_role" {
  name = "${var.project_name}-codebuild-role"

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

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM policy for CodeBuild
resource "aws_iam_policy" "codebuild_policy" {
  name        = "${var.project_name}-codebuild-policy"
  description = "Policy for CodeBuild in the ${var.project_name} project"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [
          "${aws_s3_bucket.artifacts_bucket.arn}",
          "${aws_s3_bucket.artifacts_bucket.arn}/*"
        ]
      },
      {
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:ssm:${var.aws_region}:*:parameter/${var.project_name}/*"
      }
    ]
  })
}

# Attach policy to CodeBuild role
resource "aws_iam_role_policy_attachment" "codebuild_policy_attachment" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_policy.arn
}

# IAM role for CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  name = "${var.project_name}-codepipeline-role"

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

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM policy for CodePipeline
resource "aws_iam_policy" "codepipeline_policy" {
  name        = "${var.project_name}-codepipeline-policy"
  description = "Policy for CodePipeline in the ${var.project_name} project"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [
          "${aws_s3_bucket.artifacts_bucket.arn}",
          "${aws_s3_bucket.artifacts_bucket.arn}/*"
        ]
      },
      {
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:GetApplicationRevision",
          "codedeploy:RegisterApplicationRevision"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "lambda:InvokeFunction",
          "lambda:ListFunctions"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach policy to CodePipeline role
resource "aws_iam_role_policy_attachment" "codepipeline_policy_attachment" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}

# IAM role for CodeDeploy
resource "aws_iam_role" "codedeploy_role" {
  name = "${var.project_name}-codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Attach AWS managed policy for CodeDeploy
resource "aws_iam_role_policy_attachment" "codedeploy_policy_attachment" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

# CodeBuild project
resource "aws_codebuild_project" "app_build" {
  name          = "${var.project_name}-build"
  description   = "Build project for ${var.project_name}"
  service_role  = aws_iam_role.codebuild_role.arn
  build_timeout = "15"

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    type                        = "LINUX_CONTAINER"
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "ENVIRONMENT"
      value = var.environment
    }

    environment_variable {
      name  = "PROJECT_NAME"
      value = var.project_name
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "aws/terraform/ci-cd/buildspec.yml"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${var.project_name}"
      stream_name = "build-log"
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# CodeDeploy application
resource "aws_codedeploy_app" "app" {
  name = "${var.project_name}-app"

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# CodeDeploy deployment group for EC2
resource "aws_codedeploy_deployment_group" "app_deployment_group" {
  app_name               = aws_codedeploy_app.app.name
  deployment_group_name  = "${var.project_name}-deployment-group"
  service_role_arn       = aws_iam_role.codedeploy_role.arn
  deployment_config_name = "CodeDeployDefault.AllAtOnce"

  autoscaling_groups = [aws_autoscaling_group.app_asg.name]

  deployment_style {
    deployment_type   = "IN_PLACE"
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  alarm_configuration {
    alarms  = ["${var.project_name}-deployment-alarm"]
    enabled = false
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# CodePipeline
resource "aws_codepipeline" "app_pipeline" {
  name     = "${var.project_name}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.artifacts_bucket.bucket
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
        ConnectionArn    = var.codestar_connection_arn
        FullRepositoryId = var.github_repository
        BranchName       = var.github_branch
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.app_build.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ApplicationName     = aws_codedeploy_app.app.name
        DeploymentGroupName = aws_codedeploy_deployment_group.app_deployment_group.deployment_group_name
      }
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

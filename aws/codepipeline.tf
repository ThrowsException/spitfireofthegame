resource "aws_codepipeline" "codepipeline" {
  name     = "spitfireofthegame"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = data.aws_s3_bucket.codepipeline_bucket.bucket
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
        ConnectionArn    = data.aws_codestarconnections_connection.github.arn
        FullRepositoryId = "ThrowsException/spitfireofthegame"
        BranchName       = "master"
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
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"


      configuration = {
        ProjectName = "test-project"
      }
    }
  }
}

data "aws_codestarconnections_connection" "github" {
  arn = "arn:aws:codestar-connections:us-east-1:063754174791:connection/f82bad92-5580-4ef2-8ae7-21688ba9c04f"
}

resource "aws_iam_role" "codepipeline_role" {
  name = "test-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    },
     {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline_policy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "s3:GetObject",
            "s3:GetObjectVersion",
            "s3:GetBucketVersioning",
            "s3:PutObjectAcl",
            "s3:PutObject"
          ],
          "Resource" : [
            "${data.aws_s3_bucket.codepipeline_bucket.arn}",
            "${data.aws_s3_bucket.codepipeline_bucket.arn}/*",
            "${aws_s3_bucket.website.arn}/*",
            "${aws_s3_bucket.website.arn}",
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "codestar-connections:UseConnection"
          ],
          "Resource" : "${data.aws_codestarconnections_connection.github.arn}"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "codebuild:BatchGetBuilds",
            "codebuild:StartBuild"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          "Resource" : "*"
        }
      ]
  })
}

resource "aws_codebuild_project" "example" {
  name          = "test-project"
  description   = "test_codebuild_project"
  build_timeout = "5"
  service_role  = aws_iam_role.codepipeline_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }
  source {
    type = "CODEPIPELINE"
  }
}

data "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "codepipeline-us-east-1-463096050773"
}

# resource "aws_s3_bucket" "codepipeline_bucket" {
#   bucket = "cjo-codepipeline"
#   acl    = "private"
# }

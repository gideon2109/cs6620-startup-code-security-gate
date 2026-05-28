# ECR Repository for the SAST Scanner Docker image
resource "aws_ecr_repository" "this" {
  name                 = "${var.project_name}-repo"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.common_tags
}

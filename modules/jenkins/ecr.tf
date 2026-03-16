# ECR repositories for Jenkins controller and agent images.

resource "aws_ecr_repository" "jenkins_controller" {
  name                 = "detent-jenkins-controller"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = false
  tags                 = local.tags

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "jenkins_agent" {
  name                 = "detent-jenkins-agent"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = false
  tags                 = local.tags

  image_scanning_configuration {
    scan_on_push = true
  }
}

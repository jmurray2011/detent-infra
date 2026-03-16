# EFS for persistent JENKINS_HOME across container restarts.

resource "aws_efs_file_system" "jenkins_home" {
  encrypted = true
  tags      = merge(local.tags, { Name = "detent-jenkins-home" })

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
}

resource "aws_efs_mount_target" "jenkins_home" {
  count = length(var.private_subnet_ids)

  file_system_id  = aws_efs_file_system.jenkins_home.id
  subnet_id       = var.private_subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_access_point" "jenkins_home" {
  file_system_id = aws_efs_file_system.jenkins_home.id
  tags           = local.tags

  posix_user {
    uid = 1000
    gid = 1000
  }

  root_directory {
    path = "/jenkins-home"

    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "755"
    }
  }
}

resource "aws_security_group" "efs" {
  name_prefix = "detent-efs-"
  vpc_id      = var.vpc_id
  description = "EFS mount targets for Jenkins home"
  tags        = local.tags

  ingress {
    description     = "NFS from controller"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.controller.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

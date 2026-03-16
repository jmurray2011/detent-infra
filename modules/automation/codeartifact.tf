# CodeArtifact domain and repository for publishing detent-lib.
# Job Dockerfiles pull pinned versions at build time via pip.

resource "aws_codeartifact_domain" "detent" {
  domain = "detent"
  tags   = local.tags
}

resource "aws_codeartifact_repository" "detent_lib" {
  repository = "detent-lib"
  domain     = aws_codeartifact_domain.detent.domain
  tags       = local.tags

  external_connections {
    external_connection_name = "public:pypi"
  }
}

resource "aws_codeartifact_domain_permissions_policy" "cross_account_read" {
  domain = aws_codeartifact_domain.detent.domain

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowOrgRead"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "codeartifact:GetAuthorizationToken",
          "codeartifact:GetDomainPermissionsPolicy",
          "codeartifact:ListRepositoriesInDomain",
        ]
        Resource = aws_codeartifact_domain.detent.arn
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = var.org_id
          }
        }
      },
    ]
  })
}

resource "aws_codeartifact_repository_permissions_policy" "cross_account_read" {
  repository = aws_codeartifact_repository.detent_lib.repository
  domain     = aws_codeartifact_domain.detent.domain

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowOrgReadPackages"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "codeartifact:ReadFromRepository",
          "codeartifact:GetRepositoryEndpoint",
          "codeartifact:ListPackages",
          "codeartifact:ListPackageVersions",
        ]
        Resource = aws_codeartifact_repository.detent_lib.arn
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = var.org_id
          }
        }
      },
    ]
  })
}

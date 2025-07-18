resource "aws_iam_role" "provisioning_lambda" {
  name = "AccountProvisioningLambdaRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "provisioning_policy" {
  name        = "AccountProvisioningPolicy"
  description = "Permissions for account provisioning"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "organizations:CreateAccount",
          "organizations:CreateOrganizationalUnit",
          "organizations:ListOrganizationalUnitsForParent",
          "organizations:MoveAccount",
          "organizations:DescribeCreateAccountStatus",
          "organizations:DescribeOrganizationalUnit",
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Scan",
          "ses:SendEmail"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "provisioning_attach" {
  role       = aws_iam_role.provisioning_lambda.name
  policy_arn = aws_iam_policy.provisioning_policy.arn
}

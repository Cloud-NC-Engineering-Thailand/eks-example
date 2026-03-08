data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

resource "aws_iam_role" "s3-reader" {
  name               = "s3-reader"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "s3-reader" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.s3-reader.name
}

resource "aws_eks_pod_identity_association" "s3-reader" {
  cluster_name    = module.eks.cluster_name
  namespace       = "demo"
  service_account = "s3-reader"
  role_arn        = aws_iam_role.s3-reader.arn
}

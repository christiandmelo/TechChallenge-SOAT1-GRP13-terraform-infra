resource "aws_s3_bucket" "lambda_s3" {
  bucket = "tech-challenge-soat1-grp13-s3-auth"

  tags = {
    Name        = "S3-lambda"
    Environment = "${var.environment}"
  }
}

resource "aws_s3_bucket" "lambda_s3_2" {
  bucket = "tech-challenge-soat1-grp13-s3-auth-te"

  tags = {
    Name        = "S3-lambda"
    Environment = "${var.environment}"
  }
}
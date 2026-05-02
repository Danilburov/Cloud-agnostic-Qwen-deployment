resource "aws_dynamodb_table" "tf_locks" {
    name = "${local.name}-tf-locks"
    billing_mode = "PAY-PER-REQUEST"
    hash_key = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    Project = local.name
    Purpose = "terraform-locks"
  }
}
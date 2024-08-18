resource "aws_secretsmanager_secret" "my_secret" {
  name = "my-secret"
}

resource "aws_secretsmanager_secret_version" "my_secret_version" {
  secret_id     = aws_secretsmanager_secret.my_secret.id
  secret_string = jsonencode({
    username = "admin"
    password = "P@ssw0rd"
  })
}

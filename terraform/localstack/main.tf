resource "aws_sqs_queue" "main" {
  name = var.main_queue_name
}

output "queue_url" {
  description = "URL of the LocalStack queue."
  value       = aws_sqs_queue.main.url
}

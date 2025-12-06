resource "aws_cloudwatch_event_bus" "source" {
  name = "source-bus"
}

resource "aws_kinesis_stream" "main" {
  name             = "main-stream"
  shard_count      = 1
}

resource "aws_iam_role" "eventbridge_to_kinesis" {
  name = "eventbridge-to-kinesis-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "eventbridge_to_kinesis" {
  name = "eventbridge-to-kinesis-policy"
  role = aws_iam_role.eventbridge_to_kinesis.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kinesis:DescribeStream",
          "kinesis:PutRecord",
          "kinesis:PutRecords"
        ]
        Resource = aws_kinesis_stream.main.arn
      }
    ]
  })
}

resource "aws_cloudwatch_event_rule" "forward_to_kinesis" {
  name           = "forward-to-kinesis"
  event_bus_name = aws_cloudwatch_event_bus.source.name

  event_pattern = jsonencode({
    source = ["mock-producer"]
  })
}

resource "aws_cloudwatch_event_target" "forward_to_kinesis" {
  rule           = aws_cloudwatch_event_rule.forward_to_kinesis.name
  target_id      = "main-stream-target"
  arn            = aws_kinesis_stream.main.arn
  event_bus_name = aws_cloudwatch_event_bus.source.name
  role_arn       = aws_iam_role.eventbridge_to_kinesis.arn

  kinesis_target {
    partition_key_path = "$.detail.event_id"
  }
}

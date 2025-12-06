provider "aws" {
  region                      = var.aws_region
  access_key                  = var.aws_access_key
  secret_key                  = var.aws_secret_key
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  skip_region_validation      = true

  endpoints {
    s3      = var.localstack_url
    events  = var.localstack_url
    iam     = var.localstack_url
    kinesis = var.localstack_url
    sts     = var.localstack_url
  }
}

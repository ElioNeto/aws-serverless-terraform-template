provider "aws" {
  region = "us-east-1"
}

module "database" {
  source     = "../../modules/database"
  table_name = "modernization-demo-table"
}

module "api" {
  source              = "../../modules/serverless-api"
  project_name        = "modern-serverless"
  dynamodb_table_name = "modernization-demo-table"
  dynamodb_table_arn  = module.database.table_arn
}

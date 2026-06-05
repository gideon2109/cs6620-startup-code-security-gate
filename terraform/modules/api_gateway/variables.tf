variable "lambda_invoke_arn" {
  type = string
}

variable "lambda_function_name" {
  type = string
}

variable "common_tags" {
  type    = map(string)
  default = {}
}

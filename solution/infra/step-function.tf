# Create a AWS Step Funtion to execute error handling.
# In this project it will just retry once if any unhanlded exception is thrown
resource "aws_sfn_state_machine" "gql_server_state_machine" {
  depends_on = [
    aws_iam_role.gql_step_function_role,
    aws_lambda_function.gql_lambda_function,
  ]
  name     = "gql_server_state_machine"
  role_arn = aws_iam_role.gql_step_function_role.arn

  definition = <<EOF
{
  "Comment": "A basic usasge of retry and catch using AWS Step Functions to handle API responses",
  "StartAt": "Call API",
  "States": {
    "Call API": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.gql_lambda_function.arn}",
      "Next" : "OK",
      "Comment": "Catch unhandled exception from AWS Lambda function an retry.",
      "Retry" : [ {
        "ErrorEquals": [ "States.ALL" ],
        "IntervalSeconds": 1,
        "MaxAttempts": 2
      } ],
      "Catch": [ 
        {
          "ErrorEquals": ["States.ALL"],
          "Next": "Catch All"
        }
      ]
    },
    "Catch All": {
      "Type": "Fail",
      "Cause": "Server error",
      "Error": "A server error occurred"
    },
    "OK": {
      "Type": "Pass",
      "Result": "The request has succeeded.",
      "End": true
    }
  }
}
EOF
}

resource "aws_iam_role" "gql_step_function_role" {
  name = "cloud_backend_test_gql_step_function_role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "states.amazonaws.com"              
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "step_function_policy" {
  name = "step_function_policy"
  role = aws_iam_role.gql_step_function_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "lambda:InvokeFunction"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}
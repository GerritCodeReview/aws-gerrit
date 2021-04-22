## Operations

#### Export logs to S3

All logs, for all recipes are streamed to [cloudwatch logs](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/WhatIsCloudWatchLogs.html)
and can be accessed via the cloudwatch console.

In some occasions however it is useful to export logs so that they
can be shared, analyzed, manipulated outside the AWS environment.

To do so a make rule is provided for all recipes, to export logs
to an S3 bucket.

```bash
make AWS_REGION=<region> AWS_PREFIX=<prefix> export-logs
```

In order to execute the command, the issuing profile needs to have
the ability to have full access to S3 and to CloudWatch, as detailed
in the official [AWS documentation](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/S3ExportTasks.html)



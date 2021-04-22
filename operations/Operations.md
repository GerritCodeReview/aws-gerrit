## Operations

#### Export logs to S3

All logs, for all recipes are streamed to [cloudwatch logs](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/WhatIsCloudWatchLogs.html)
and can be accessed via the cloudwatch console.

In some occasions however it is useful to export logs so that they
can be shared, analyzed, manipulated outside the AWS environment.

To do so, a make rule is provided for all recipes, to export logs
to an S3 bucket.

```bash
make \
  [AWS_REGION=<region>] \
  [AWS_PREFIX=<prefix>] \
  [EXPORT_FROM_SECONDS=<epoch_secs>] \
  [S3_EXPORT_LOGS_BUCKET_NAME=<bucket>] \
  export-logs
```

*`AWS_REGION`: Optional. Defaults to the value set in your [common.env](../common.env)
*`AWS_PREFIX`: Optional. Defaults to the value set in your [common.env](../common.env)
*`EXPORT_FROM_SECONDS`. Optional. The start time of the range for the request,
  expressed as the number of seconds after Jan 1, 1970 00:00:00 UTC.
*`S3_EXPORT_LOGS_BUCKET_NAME`: Optional. Defaults to `$(AWS_PREFIX)-s3-export-logs`

Note: this command assumes that the bucket already exists and that is configured
with the relevant policy allowing cloudwatch to export logs into it (see
[permissions](#permissions)) for more information on how to set this up.

Alternatively you can create, setup the bucket and export the logs in one command.

```bash
make \
  [AWS_REGION=<region>] \
  [AWS_PREFIX=<prefix>] \
  [EXPORT_FROM_SECONDS=<epoch_secs>] \
  [S3_EXPORT_LOGS_BUCKET_NAME=<bucket>] \
  setup-bucket-and-export-logs
```

##### Permissions
In order to execute the command, the issuing profile needs to have
the ability to have full access to S3 and to CloudWatch, as detailed
in the official [AWS documentation](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/S3ExportTasks.html)



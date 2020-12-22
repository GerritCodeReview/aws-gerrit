## Git Repo Garbage Collection

Optionally any recipe can be deployed so that a garbage collection task is
scheduled to run periodically against a specified list of repositories.

By setting the environment variable `GIT_GC_ENABLED=true`, a new stack will be
deployed to provision the resources needed to run garbage collection as a
scheduled ECS task.

Please refer to the relevant [configuration section](../../Configuration.md#scheduled-git-garbage-collection)
to understand which parameters need to be set for this.

You can also deploy and destroy this stack separately, as such:

* Add GC scheduled task to an existing deployment
```bash
make [AWS_REGION=a-valid-aws-region] [AWS_PREFIX=some-cluster-prefix] create-scheduled-gc-task
```
* Delete GC scheduled task from an existing deployment
```bash
make [AWS_REGION=a-valid-aws-region] [AWS_PREFIX=some-cluster-prefix] delete-scheduled-gc-task
```

The scheduled task will be executed on any master EC2 instance.
You will need to account for this when deciding the instance type and the
allocated CPU and Memory running on those EC2 instances.
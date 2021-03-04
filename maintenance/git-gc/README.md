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

The scheduled task will be executed on any primary EC2 instance.
You will need to account for this when deciding the instance type and the
allocated CPU and Memory running on those EC2 instances.

## Limitations

### Resources

CPU and memory allocated to the GC task are hardcoded to 1 vCpu and 1GB,
respectively. Depending on the amount and size of repositories, these might not
be fitting values.

* Issue: https://bugs.chromium.org/p/gerrit/issues/detail?id=13888

### Docker image

The docker image onto which the GC task is based is not the official
[OpenJDK](https://hub.docker.com/_/openjdk).

* Issue: https://bugs.chromium.org/p/gerrit/issues/detail?id=13889

### Managing repositories

The GC task requires a list of projects to perform GC on.

Whilst this provides flexibility for the Gerrit admin to decide which projects
should be GC'd, it might also make it difficult to manage for installations with
a very large number of projects.

There is already a Gerrit plugin named gc-conductor that can offload this burden
by evaluating the dirtiness of repositories and add them to a queue to be
garbage collected.

This approach should and can be considered as a valid alternative to perform GC
activities.

* Issue: https://bugs.chromium.org/p/gerrit/issues/detail?id=13890
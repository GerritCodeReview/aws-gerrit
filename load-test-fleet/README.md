# Load tests

This is a set of Cloud Formation Templates and scripts to spin up a simple load
test fleet of EC2 instances.

It can be used to run load tests against stacks created with any recipe.

## How to run it

```
make load-test ENTRYPOINT="command to run the tests" DESIRED_CAPACITY=5
```

This will create a CF stack with `DESIRED_CAPACITY` EC2 instances running the
`ENTRYPOINT` command after startup.

### Cleaning up

```
make delete-load-tets
```

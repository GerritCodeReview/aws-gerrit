include ../Makefile.common

LOAD_TEST_TEMPLATE:=cf-load-test-workers.yml
AWS_REGION:=us-east-1
AWS_FC_COMMAND=export AWS_PAGER=;aws cloudformation
LOAD_TEST_STACK_NAME:=gerrit-load-test
DESIRED_CAPACITY:=3
ENTRYPOINT:="ls -lrt"

.PHONY: load-test delete-load-test

load-test:
	$(AWS_FC_COMMAND) create-stack \
		--stack-name $(LOAD_TEST_STACK_NAME) \
		--capabilities CAPABILITY_IAM  \
		--template-body file://`pwd`/$(LOAD_TEST_TEMPLATE) \
		--region $(AWS_REGION) \
		--parameters \
		ParameterKey=DesiredCapacity,ParameterValue=$(DESIRED_CAPACITY) \
		ParameterKey=ECSKeyName,ParameterValue=$(CLUSTER_KEYS) \
		ParameterKey=EntryPoint,ParameterValue="$(ENTRYPOINT)"

delete-load-test:
	$(AWS_FC_COMMAND) delete-stack \
	--stack-name $(LOAD_TEST_STACK_NAME) \
	--region $(AWS_REGION)

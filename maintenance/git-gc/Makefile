DOCKER_NAME=aws-gerrit/git-gc
ECR_REPO=$(DOCKER_REGISTRY_URI)/$(DOCKER_NAME)
GIT_GC_SHA1=$(shell find . -type f -exec cat {} \; | sha1sum | cut -c 1-20)
GIT_GC_IMAGE=$(DOCKER_NAME):$(GIT_GC_SHA1)
GIT_GC_IMAGE_FQDN=$(ECR_REPO):$(GIT_GC_SHA1)

SERVICE_GIT_GC_TEMPLATE:=../maintenance/git-gc/cf-task-git-gc.yml

ifeq ($(GIT_GC_ENABLED),true)
optional_git_gc_targets_creation=create-scheduled-gc-task
optional_git_gc_targets_deletion=delete-scheduled-gc-task
endif

docker-registry-login:
	$(AWS) ecr get-login-password \
		| docker login --username AWS --password-stdin ${ECR_REPO}

git-gc-build:
	docker build -t aws-gerrit/git-gc:$(GIT_GC_SHA1) ../maintenance/git-gc
	docker tag $(GIT_GC_IMAGE) $(ECR_REPO):$(GIT_GC_SHA1)

git-gc-publish: docker-registry-login git-gc-build
	docker push $(GIT_GC_IMAGE_FQDN)

create-scheduled-gc-task: service-git-gc wait-for-service-git-gc-creation
delete-scheduled-gc-task: delete-service-git-gc wait-for-service-git-gc-deletion

service-git-gc: git-gc-publish

	$(AWS_FC_COMMAND) create-stack \
		--stack-name $(SERVICE_GIT_GC_STACK_NAME) \
		--capabilities CAPABILITY_IAM  \
		--template-body file://`pwd`/$(SERVICE_GIT_GC_TEMPLATE) \
		--parameters \
		ParameterKey=ClusterStackName,ParameterValue=$(CLUSTER_STACK_NAME) \
		ParameterKey=TemplateBucketName,ParameterValue=$(TEMPLATE_BUCKET_NAME) \
		ParameterKey=DockerImageFQN,ParameterValue="$(GIT_GC_IMAGE_FQDN)" \
		ParameterKey=ProjectList,ParameterValue=\"$(GIT_GC_PROJECT_LIST)\" \
		ParameterKey=ScheduleCronExpression,ParameterValue=$(GIT_GC_CRON_EXPRESSION) \
		ParameterKey=GitSourcePath,ParameterValue=$(GIT_GC_SOURCE_PATH) \
		ParameterKey=GitGCOptions,ParameterValue=$(GIT_GC_OPTION) \
		ParameterKey=PackThreads,ParameterValue=$(GIT_GC_PACK_THREADS) \
		ParameterKey=PruneExpire,ParameterValue=$(GIT_GC_PRUNE_EXPIRE) \
		ParameterKey=PrunePackExpire,ParameterValue=$(GIT_GC_PRUNE_PACK_EXPIRE) \
		ParameterKey=JavaArgs,ParameterValue=$(GIT_GC_JAVA_ARGS)

wait-for-service-git-gc-creation:
	@echo "*** Wait for service-git-gc stack '$(SERVICE_GIT_GC_STACK_NAME)' creation"
	$(AWS_FC_COMMAND) wait stack-create-complete \
	--stack-name $(SERVICE_GIT_GC_STACK_NAME)

	@echo "*** Cluster stack '$(SERVICE_GIT_GC_STACK_NAME)' created"

wait-for-service-git-gc-deletion:
	@echo "*** Wait for service-git-gc stack '$(SERVICE_GIT_GC_STACK_NAME)' deletion"
	$(AWS_FC_COMMAND) wait stack-delete-complete \
	--stack-name $(SERVICE_GIT_GC_STACK_NAME)

	@echo "*** service-git-gc stack '$(SERVICE_GIT_GC_STACK_NAME)' deleted"

delete-service-git-gc:
	$(AWS_FC_COMMAND) delete-stack \
	--stack-name $(SERVICE_GIT_GC_STACK_NAME)
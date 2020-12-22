AWS=export AWS_PAGER=;aws
DOCKER_NAME=aws-gerrit/git-gc
ECR_REPO=$(DOCKER_REGISTRY_URI)/$(DOCKER_NAME)
GIT_GC_SHA1=$(shell find . -type f -exec cat {} \; | sha1sum | cut -c 1-20)
GIT_GC_IMAGE=$(DOCKER_NAME):$(GIT_GC_SHA1)
GIT_GC_IMAGE_FQDN=$(ECR_REPO):$(GIT_GC_SHA1)

docker-registry-login:
	$(AWS) ecr get-login-password --region $(AWS_REGION) \
		| docker login --username AWS --password-stdin ${ECR_REPO}

git-gc-build:
	docker build -t aws-gerrit/git-gc:$(GIT_GC_SHA1) maintenance/git-gc
	docker tag $(GIT_GC_IMAGE) $(ECR_REPO):$(GIT_GC_SHA1)

git-gc-publish: docker-registry-login git-gc-build

	docker push $(GIT_GC_IMAGE_FQDN)
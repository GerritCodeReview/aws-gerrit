include ../../Makefile.common
include ../setup.env

IMAGE_NAME:=git-daemon

docker-registry-login:
	$(AWS) ecr get-login-password \
		| docker login --username AWS --password-stdin $(DOCKER_REGISTRY_URI)/aws-gerrit/$(IMAGE_NAME)

git-daemon-build:
	docker build -t aws-gerrit/$(IMAGE_NAME) .
		docker tag aws-gerrit/$(IMAGE_NAME):latest $(DOCKER_REGISTRY_URI)/aws-gerrit/$(IMAGE_NAME):latest

git-daemon-publish: docker-registry-login git-daemon-build
	docker push $(DOCKER_REGISTRY_URI)/aws-gerrit/$(IMAGE_NAME):latest

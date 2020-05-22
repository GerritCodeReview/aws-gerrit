include ../../Makefile.common
include ../setup.env

IMAGE_NAME:=syslog-sidecar

docker-registry-login:
	aws ecr get-login-password --region $(AWS_REGION) \
		| docker login --username AWS --password-stdin $(DOCKER_REGISTRY_URI)/aws-gerrit/$(IMAGE_NAME)

syslog-sidecar-build:
	docker build -t aws-gerrit/$(IMAGE_NAME):$(IMAGE_TAG) .
	docker tag aws-gerrit/$(IMAGE_NAME):$(IMAGE_TAG) $(DOCKER_REGISTRY_URI)/aws-gerrit/$(IMAGE_NAME):$(IMAGE_TAG)

syslog-sidecar-publish: docker-registry-login syslog-sidecar-build
	docker push $(DOCKER_REGISTRY_URI)/aws-gerrit/$(IMAGE_NAME):$(IMAGE_TAG)

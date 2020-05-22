include ../../Makefile.common
include ../setup.env

IMAGE_NAME:=haproxy

docker-registry-login:
	aws ecr get-login-password --region $(AWS_REGION) \
		| docker login --username AWS --password-stdin $(DOCKER_REGISTRY_URI)/aws-gerrit/$(IMAGE_NAME)

haproxy-build:
	docker build -t aws-gerrit/$(IMAGE_NAME):$(IMAGE_TAG) .
		docker tag aws-gerrit/$(IMAGE_NAME):$(IMAGE_TAG) $(DOCKER_REGISTRY_URI)/aws-gerrit/$(IMAGE_NAME):$(IMAGE_TAG)

haproxy-publish: docker-registry-login haproxy-build
	docker push $(DOCKER_REGISTRY_URI)/aws-gerrit/$(IMAGE_NAME):$(IMAGE_TAG)

include ../setup.env

IMAGE_NAME:=git-ssh

docker-registry-login:
	aws ecr get-login-password --region $(AWS_REGION) \
		| docker login --username AWS --password-stdin $(DOCKER_REGISTRY_URI)/aws-gerrit/$(IMAGE_NAME)

git-ssh-build:
	docker build -t aws-gerrit/$(IMAGE_NAME) .
		docker tag aws-gerrit/$(IMAGE_NAME):latest $(DOCKER_REGISTRY_URI)/aws-gerrit/$(IMAGE_NAME):latest

git-ssh-publish: docker-registry-login git-ssh-build
	docker push $(DOCKER_REGISTRY_URI)/aws-gerrit/$(IMAGE_NAME):latest

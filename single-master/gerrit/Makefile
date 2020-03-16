include ../setup.env

docker-registry-login:
	aws ecr get-login-password --region $(AWS_REGION) \
		| docker login --username AWS --password-stdin $(DOCKER_REGISTRY_URI)/aws-gerrit/gerrit

gerrit-build:
	docker build -t aws-gerrit/gerrit .
	docker tag aws-gerrit/gerrit:latest $(DOCKER_REGISTRY_URI)/aws-gerrit/gerrit:latest

gerrit-publish: docker-registry-login gerrit-build
	docker push $(DOCKER_REGISTRY_URI)/aws-gerrit/gerrit:latest

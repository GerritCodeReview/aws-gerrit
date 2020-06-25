include ../../$(RECIPE)/setup.env
include ../../Makefile.common

docker-registry-login:
	aws ecr get-login-password --region $(AWS_REGION) \
		| docker login --username AWS --password-stdin $(DOCKER_REGISTRY_URI)/aws-gerrit/prometheus

prometheus-build:
	docker build -t aws-gerrit/prometheus .
	docker tag aws-gerrit/prometheus:latest $(DOCKER_REGISTRY_URI)/aws-gerrit/prometheus:latest

prometheus-publish: docker-registry-login prometheus-build
	docker push $(DOCKER_REGISTRY_URI)/aws-gerrit/prometheus:latest

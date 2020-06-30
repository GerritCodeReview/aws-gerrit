include ../../$(RECIPE)/setup.env

docker-registry-login:
	aws ecr get-login-password --region $(AWS_REGION) \
		| docker login --username AWS --password-stdin $(DOCKER_REGISTRY_URI)/aws-gerrit/grafana

grafana-build:
	docker build -t aws-gerrit/grafana .
	docker tag aws-gerrit/grafana:
	latest $(DOCKER_REGISTRY_URI)/aws-gerrit/grafana:latest

grafana-publish: docker-registry-login grafana-build
	docker push $(DOCKER_REGISTRY_URI)/aws-gerrit/grafana:latest

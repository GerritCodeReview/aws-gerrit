include ../$(RECIPE)/setup.env

GERRIT_BRANCH=stable-3.0
GERRIT_CI=https://gerrit-ci.gerritforge.com/view/Plugins-$(GERRIT_BRANCH)/job
LAST_BUILD=lastSuccessfulBuild/artifact/bazel-bin/plugins

docker-registry-login:
	aws ecr get-login-password --region $(AWS_REGION) \
		| docker login --username AWS --password-stdin $(DOCKER_REGISTRY_URI)/aws-gerrit/gerrit

gerrit-get-plugins:
	# Make sure Prometheus MEtrics exporter plugin is installed

	@echo "Downloading metrics-reporter-prometheus plugin $(GERRIT_BRANCH)"
	wget $(GERRIT_CI)/plugin-metrics-reporter-prometheus-bazel-master-$(GERRIT_BRANCH)/$(LAST_BUILD)/metrics-reporter-prometheus/metrics-reporter-prometheus.jar \
	-O ./plugins/metrics-reporter-prometheus.jar \
	|| { echo >&2 "Cannot download metrics-reporter-prometheus plugin: Check internet connection. Aborting"; exit 1; }

	@echo "Downloading javamelody plugin $(GERRIT_BRANCH)"
	wget $(GERRIT_CI)/plugin-javamelody-bazel-$(GERRIT_BRANCH)/$(LAST_BUILD)/javamelody/javamelody.jar \
	-O ./plugins/javamelody.jar \
	|| { echo >&2 "Cannot download javamelody plugin: Check internet connection. Aborting"; exit 1; }

gerrit-build:
	docker build -t aws-gerrit/gerrit .
	docker tag aws-gerrit/gerrit:latest $(DOCKER_REGISTRY_URI)/aws-gerrit/gerrit:latest

gerrit-publish: gerrit-get-plugins docker-registry-login gerrit-build
	docker push $(DOCKER_REGISTRY_URI)/aws-gerrit/gerrit:latest

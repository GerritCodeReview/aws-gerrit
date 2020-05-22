include ../$(RECIPE)/setup.env
include ../Makefile.common

docker-registry-login:
	aws ecr get-login-password --region $(AWS_REGION) \
		| docker login --username AWS --password-stdin $(DOCKER_REGISTRY_URI)/aws-gerrit/gerrit

gerrit-get-plugins:
	# Make sure Prometheus Metrics exporter plugin is installed

	@echo "Downloading metrics-reporter-prometheus plugin $(GERRIT_BRANCH)"
	wget $(GERRIT_CI)/plugin-metrics-reporter-prometheus-bazel-master-$(GERRIT_BRANCH)/$(LAST_BUILD)/metrics-reporter-prometheus/metrics-reporter-prometheus.jar \
	-O ./plugins/metrics-reporter-prometheus.jar \
	|| { echo >&2 "Cannot download metrics-reporter-prometheus plugin: Check internet connection. Aborting"; exit 1; }

	@echo "Downloading javamelody plugin $(GERRIT_BRANCH)"
	wget $(GERRIT_CI)/plugin-javamelody-bazel-master-$(GERRIT_BRANCH)/$(LAST_BUILD)/javamelody/javamelody.jar \
	-O ./plugins/javamelody.jar \
	|| { echo >&2 "Cannot download javamelody plugin: Check internet connection. Aborting"; exit 1; }

	@echo "Downloading HA plugin $(GERRIT_BRANCH)"
	wget $(GERRIT_CI)/plugin-high-availability-bazel-master-$(GERRIT_BRANCH)/$(LAST_BUILD)/high-availability/high-availability.jar \
	-O ./plugins/high-availability.jar \
	|| { echo >&2 "Cannot download high-availability plugin: Check internet connection. Aborting"; exit 1; }

gerrit-build:
	cat Dockerfile | \
		GERRIT_VERSION=$(GERRIT_VERSION) GERRIT_PATCH=$(GERRIT_PATCH) envsubst | \
		docker build -f - -t aws-gerrit/gerrit:$(IMAGE_TAG) .
	docker tag aws-gerrit/gerrit:$(IMAGE_TAG) $(DOCKER_REGISTRY_URI)/aws-gerrit/gerrit:$(IMAGE_TAG)

gerrit-publish: gerrit-get-plugins docker-registry-login gerrit-build
	docker push $(DOCKER_REGISTRY_URI)/aws-gerrit/gerrit:$(IMAGE_TAG)

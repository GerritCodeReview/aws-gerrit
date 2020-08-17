include ../$(RECIPE)/setup.env
include ../Makefile.common

docker-registry-login:
	aws ecr get-login-password --region $(AWS_REGION) \
		| docker login --username AWS --password-stdin $(DOCKER_REGISTRY_URI)/aws-gerrit/gerrit

gerrit-get-plugins:
	# Make sure Prometheus Metrics exporter plugin is installed
	mkdir -p $(@D)/{plugins,lib}

	@echo "Ensure no plugins are left from previous deployments"
	rm -f $(@D)/plugins/*.jar

	@echo "Downloading metrics-reporter-prometheus plugin $(GERRIT_BRANCH)"
	wget $(GERRIT_CI)/plugin-metrics-reporter-prometheus-bazel-master-$(GERRIT_BRANCH)/$(LAST_BUILD)/metrics-reporter-prometheus/metrics-reporter-prometheus.jar \
	-O ./plugins/metrics-reporter-prometheus.jar \
	|| { echo >&2 "Cannot download metrics-reporter-prometheus plugin: Check internet connection. Aborting"; exit 1; }

	@echo "Downloading javamelody plugin $(GERRIT_BRANCH)"
	wget $(GERRIT_CI)/plugin-javamelody-bazel-master-$(GERRIT_BRANCH)/$(LAST_BUILD)/javamelody/javamelody.jar \
	-O ./plugins/javamelody.jar \
	|| { echo >&2 "Cannot download javamelody plugin: Check internet connection. Aborting"; exit 1; }

	@echo "Downloading HA plugin $(GERRIT_BRANCH)"
	wget $(GERRIT_CI)/plugin-high-availability-bazel-$(GERRIT_BRANCH)/$(LAST_BUILD)/high-availability/high-availability.jar \
	-O ./plugins/high-availability.jar \
	|| { echo >&2 "Cannot download high-availability plugin: Check internet connection. Aborting"; exit 1; }

	@echo "Downloading Health Check plugin $(GERRIT_BRANCH)"
	wget $(GERRIT_CI)/plugin-healthcheck-bazel-$(GERRIT_BRANCH)/$(LAST_BUILD)/healthcheck/healthcheck.jar \
	-O ./plugins/healthcheck.jar \
	|| { echo >&2 "Cannot download healthcheck plugin: Check internet connection. Aborting"; exit 1; }

	@echo "Downloading Metrics Reporter Cloudwatch plugin $(GERRIT_BRANCH)"
	wget $(GERRIT_CI)/plugin-metrics-reporter-cloudwatch-bazel-$(GERRIT_BRANCH)/$(LAST_BUILD)/metrics-reporter-cloudwatch/metrics-reporter-cloudwatch.jar \
	-O ./plugins/metrics-reporter-cloudwatch.jar \
	|| { echo >&2 "Cannot download metrics-reporter-cloudwatch plugin: Check internet connection. Aborting"; exit 1; }

ifeq ($(MULTISITE_ENABLED),true)
	@echo "Downloading multi-site plugin $(GERRIT_BRANCH)"
	wget $(GERRIT_CI)/plugin-multi-site-bazel-$(GERRIT_BRANCH)/$(LAST_BUILD)/multi-site/multi-site.jar \
	-O ./plugins/multi-site.jar \
	|| { echo >&2 "Cannot download multi-site plugin: Check internet connection. Aborting"; exit 1; }

	@echo "Symlink multi-site plugin into lib"
	ln -s ./plugins/multi-site.jar ./lib/multi-site.jar

	@echo "Downloading events-broker library"
	wget $(MAVEN_ARCHIVE)/events-broker/$(EVENTSBROKER_LIB_VER)/events-broker-$(EVENTSBROKER_LIB_VER).jar \
	-O lib/events-broker.jar \
	|| { echo >&2 "Cannot download events-broker-library: Check internet connection. Aborting"; exit 1; }

	@echo "Downloading kafka-events plugin $(GERRIT_BRANCH)"
	wget $(GERRIT_CI)/plugin-kafka-events-bazel-$(GERRIT_BRANCH)/$(LAST_BUILD)/kafka-events/kafka-events.jar \
	-O ./plugins/kafka-events.jar \
	|| { echo >&2 "Cannot download kafka-events plugin: Check internet connection. Aborting"; exit 1; }

	@echo "Downloading zookeper-refdb-3.5 plugin $(GERRIT_BRANCH)"
	wget $(GERRIT_CI)/plugin-zookeeper-refdb-bazel-$(GERRIT_BRANCH)/$(LAST_BUILD)/zookeeper-refdb/zookeeper-refdb-zk-3.5.jar \
	-O ./plugins/zookeeper-refdb.jar \
	|| { echo >&2 "Cannot download zookeeper-refdb plugin: Check internet connection. Aborting"; exit 1; }

	@echo "Downloading websession-broker plugin $(GERRIT_BRANCH)"
	wget $(GERRIT_CI)/plugin-websession-broker-bazel-master-$(GERRIT_BRANCH)/$(LAST_BUILD)/websession-broker/websession-broker.jar \
	-O ./plugins/websession-broker.jar \
	|| { echo >&2 "Cannot download websession-broker plugin: Check internet connection. Aborting"; exit 1; }
endif

gerrit-build:
	cat Dockerfile | \
		GERRIT_VERSION=$(GERRIT_VERSION) GERRIT_PATCH=$(GERRIT_PATCH) envsubst | \
		docker build -f - -t aws-gerrit/gerrit:$(IMAGE_TAG) .
	docker tag aws-gerrit/gerrit:$(IMAGE_TAG) $(DOCKER_REGISTRY_URI)/aws-gerrit/gerrit:$(IMAGE_TAG)

gerrit-publish: gerrit-get-plugins docker-registry-login gerrit-build
	docker push $(DOCKER_REGISTRY_URI)/aws-gerrit/gerrit:$(IMAGE_TAG)

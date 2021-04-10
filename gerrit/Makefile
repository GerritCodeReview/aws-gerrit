include ../$(RECIPE)/setup.env
include ../Makefile.common

PLUGINS=javamelody healthcheck metrics-reporter-cloudwatch

docker-registry-login:
	aws ecr get-login-password --region $(AWS_REGION) \
		| docker login --username AWS --password-stdin $(DOCKER_REGISTRY_URI)/aws-gerrit/gerrit

gerrit-get-plugins:
	# Make sure Prometheus Metrics exporter plugin is installed
	mkdir -p $(@D)/{plugins,lib}

	@echo "Ensure no plugins or libraries are left from previous deployments"
	rm -f $(@D)/{plugins,lib}/*.jar

	for plugin in $(PLUGINS); \
	do \
		export pluginname=`echo $$plugin | cut -d '~' -f 1`; \
		export pluginjar=`echo $$plugin | tr '~' '-'`; \
		echo "Downloading $$plugin plugin $(GERRIT_BRANCH)"; \
		wget $(GERRIT_CI)/plugin-$$pluginname-bazel-$(GERRIT_BRANCH)/$(LAST_BUILD)/$$pluginname/$$pluginjar.jar \
		-O ./plugins/$$pluginname.jar || \
		wget $(GERRIT_CI)/plugin-$$pluginname-bazel-master-$(GERRIT_BRANCH)/$(LAST_BUILD)/$$pluginname/$$pluginjar.jar \
		-O ./plugins/$$pluginname.jar || \
		{ echo >&2 "Cannot download $$plugin plugin: Check internet connection. Aborting"; exit 1; }; \
	done

	for pluginlib in $(PLUGINS_LIBS_LINKS); \
	do \
		echo "Symlink $$pluginlib plugin into lib"; \
		ln -sf ../plugins/$$pluginlib.jar ./lib/$$pluginlib.jar; \
	done

	for mavenlib in $(MAVEN_LIBS); \
	do \
		echo "Downloading $$mavenlib library"; \
		export libname=`echo $$mavenlib | cut -d '~' -f 1`; \
		export libver=`echo $$mavenlib | cut -d '~' -f 2`; \
		export libjar=`echo $$mavenlib | tr '~' '-'`; \
		wget $(MAVEN_ARCHIVE)/$$libname/$$libver/$$libjar.jar \
			-O ./lib/$$libname.jar \
		|| { echo >&2 "Cannot download $$mavenlib: Check internet connection. Aborting"; exit 1; } \
	done

gerrit-build: check-gerrit-version-vs-war-url
	cat Dockerfile | \
		GERRIT_VERSION=$(GERRIT_VERSION) GERRIT_PATCH=$(GERRIT_PATCH) GERRIT_WAR_URL=$(GERRIT_WAR_URL) envsubst | \
		docker build -f - -t aws-gerrit/gerrit:$(IMAGE_TAG) .
	docker tag aws-gerrit/gerrit:$(IMAGE_TAG) $(DOCKER_REGISTRY_URI)/aws-gerrit/gerrit:$(IMAGE_TAG)

check-gerrit-version-vs-war-url:
	if [[ "$(GERRIT_WAR_URL)" != "" ]]; \
	then \
		curl $(GERRIT_WAR_URL) > gerrit.war; \
		GERRIT_VERSION_FROM_WAR=$$(java -jar gerrit.war version | awk '{print $$3}' | cut -d '.' -f 1,2); \
		if [[ "$$GERRIT_VERSION_FROM_WAR" != "$(GERRIT_VERSION)" ]]; \
		then \
			echo "GERRIT_VERSION=$(GERRIT_VERSION) is not compatible with $$(java -jar gerrit.war version) from $(GERRIT_WAR_URL)"; \
			exit -1; \
		fi; \
	fi

gerrit-publish: gerrit-get-plugins docker-registry-login gerrit-build
	docker push $(DOCKER_REGISTRY_URI)/aws-gerrit/gerrit:$(IMAGE_TAG)

include ../common.env # Must be included before setup.env because the latter depends on it
include setup.env
include ../Makefile.common

GEO_LOCATION_TEMPLATE:=cf-geo-location-routing.yml

.PHONY: create-all delete-all \
		create-geo-location-routing wait-for-geo-location-routing-creation \
		delete-geo-location-routing wait-for-geo-location-routing-deletion

create-all: create-geo-location-routing wait-for-geo-location-routing-creation
delete-all: delete-geo-location-routing wait-for-geo-location-routing-deletion

create-geo-location-routing:

	$(AWS_FC_COMMAND) create-stack \
		--stack-name $(GEO_LOCATION_ROUTING_STACK_NAME) \
		--capabilities CAPABILITY_IAM  \
		--template-body file://`pwd`/$(GEO_LOCATION_TEMPLATE) \
		--parameters \
			ParameterKey=HostedZoneName,ParameterValue=$(HOSTED_ZONE_NAME) \
			ParameterKey=HostedZoneId,ParameterValue=$(HOSTED_ZONE_ID) \
			ParameterKey=GlobalSubdomainName,ParameterValue=$(GLOBAL_SUBDOMAIN_NAME) \
			ParameterKey=DefaultAliasTarget,ParameterValue=$(DEFAULT_ALIAS_TARGET) \
			ParameterKey=SiteAContinentCode,ParameterValue=$(SITE_A_CONTINENT_CODE) \
			ParameterKey=SiteAAliasTarget,ParameterValue=$(SITE_A_ALIAS_TARGET) \
			ParameterKey=SiteBContinentCode,ParameterValue=$(SITE_B_CONTINENT_CODE) \
			ParameterKey=SiteBAliasTarget,ParameterValue=$(SITE_B_ALIAS_TARGET)


delete-geo-location-routing:
	$(AWS_FC_COMMAND) delete-stack \
	--stack-name $(GEO_LOCATION_ROUTING_STACK_NAME)

wait-for-geo-location-routing-creation:
	@echo "*** Wait for geo-location-routing stack '$(GEO_LOCATION_ROUTING_STACK_NAME)' creation"
	$(AWS_FC_COMMAND) wait stack-create-complete \
	--stack-name $(GEO_LOCATION_ROUTING_STACK_NAME)

	@echo "*** geo-location-routing stack '$(GEO_LOCATION_ROUTING_STACK_NAME)' created"


wait-for-geo-location-routing-deletion:
	@echo "*** Wait for geo-location-routing stack '$(GEO_LOCATION_ROUTING_STACK_NAME)' deletion"
	$(AWS_FC_COMMAND) wait stack-delete-complete \
	--stack-name $(GEO_LOCATION_ROUTING_STACK_NAME)

	@echo "*** geo-location-routing stack '$(GEO_LOCATION_ROUTING_STACK_NAME)' deleted"
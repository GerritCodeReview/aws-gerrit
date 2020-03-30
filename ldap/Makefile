LDAP_TEMPLATE:=cf-ldap.yml
AWS_REGION:=us-east-1
AWS_FC_COMMAND=export AWS_PAGER=;aws cloudformation
LDAP_STACK_NAME:=gerrit-ldap
HOSTED_ZONE_NAME:=mycompany.com

.PHONY: ldap delete-ldap

ldap:
	$(AWS_FC_COMMAND) create-stack \
		--stack-name $(LDAP_STACK_NAME) \
		--capabilities CAPABILITY_IAM  \
		--template-body file://`pwd`/$(LDAP_TEMPLATE) \
		--region $(AWS_REGION) \
		--parameters \
		ParameterKey=HostedZoneName,ParameterValue=$(HOSTED_ZONE_NAME)

delete-ldap:
	$(AWS_FC_COMMAND) delete-stack \
	--stack-name $(LDAP_STACK_NAME) \
	--region $(AWS_REGION)

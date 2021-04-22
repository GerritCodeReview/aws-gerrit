now = $(shell date +%s)
destination-prefix-name = gerrit-export-logs-ts-$(now)
EXPORT_FROM_SECONDS ?= 0000000000

create-s3-export-logs-bucket:
	$(eval CREATE_S3_EXPORT_PARAMS_LOGS_PARAMS := --bucket $(S3_EXPORT_LOGS_BUCKET_NAME))
ifneq ("$(AWS_REGION)", "us-east-1")
		$(eval CREATE_S3_EXPORT_PARAMS_LOGS_PARAMS := $(CREATE_S3_EXPORT_PARAMS_LOGS_PARAMS) --create-bucket-configuration LocationConstraint=$(AWS_REGION))
endif
	@echo "*** Create bucket $(S3_EXPORT_LOGS_BUCKET_NAME)"
	$(AWS) s3api create-bucket $(CREATE_S3_EXPORT_PARAMS_LOGS_PARAMS)

set-bucket-permissions:
	@echo "*** Set permissions to bucket $(S3_EXPORT_LOGS_BUCKET_NAME)"
	cat ../operations/export-logs/s3.bucket.permissions.yaml | \
		AWS_REGION=$(AWS_REGION) EXPORT_LOGS_BUCKET=$(S3_EXPORT_LOGS_BUCKET_NAME) \
		 envsubst > /tmp/$(S3_EXPORT_LOGS_BUCKET_NAME).policy.yaml

	$(AWS) s3api put-bucket-policy --bucket $(S3_EXPORT_LOGS_BUCKET_NAME) \
		--policy file:///tmp/$(S3_EXPORT_LOGS_BUCKET_NAME).policy.yaml

setup-s3-bucket: create-s3-export-logs-bucket set-bucket-permissions

launch-export-task:
	$(eval DESTINATION_PREFIX := $(destination-prefix-name))
	$(eval TASK_ID := $(shell $(AWS) logs create-export-task --task-name $(DESTINATION_PREFIX) \
		--log-group-name $(CLUSTER_STACK_NAME) \
		--destination $(S3_EXPORT_LOGS_BUCKET_NAME) \
		--from $(EXPORT_FROM_SECONDS)000 --to $(now)000 \
		--destination-prefix $(DESTINATION_PREFIX) | jq -r '.taskId'))

	@echo "Launched export task id $(TASK_ID) from $(EXPORT_FROM_SECONDS)000 to $(now)000"

wait_for_export:
	while [[ $$(aws logs describe-export-tasks --task-id "$(TASK_ID)" | jq -r '.exportTasks[0].status.code') =~ RUNNING|PENDING|PENDING_CANCEL ]]; do \
  		echo "Wait for task $(DESTINATION_PREFIX) (id: $(TASK_ID)) to complete"; \
  		sleep 5; \
  	done;

	@echo "Export logs to $(S3_EXPORT_LOGS_BUCKET_NAME)/$(DESTINATION_PREFIX) terminated."
	$(AWS) logs describe-export-tasks --task-id "$(TASK_ID)" | jq -r '.exportTasks[0].status.code'

export-logs: launch-export-task wait_for_export
setup-bucket-and-export-logs: setup-s3-bucket export-logs
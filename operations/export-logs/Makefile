now = $(shell date +%s)
bucket-name = gerrit-export-logs-ts-$(now)

create-s3-export-logs-bucket:
	$(eval S3_EXPORT_LOGS_BUCKET_NAME := $(bucket-name))
	$(eval CREATE_S3_EXPORT_PARAMS_LOGS_PARAMS := --bucket $(S3_EXPORT_LOGS_BUCKET_NAME))
ifneq ("$(AWS_REGION)", "us-east-1")
		$(eval CREATE_S3_EXPORT_PARAMS_LOGS_PARAMS := $(CREATE_S3_EXPORT_PARAMS_LOGS_PARAMS) --create-bucket-configuration LocationConstraint=$(AWS_REGION))
endif
	@echo "*** Create bucket $(bucket-name)"
	$(AWS) s3api create-bucket $(CREATE_S3_EXPORT_PARAMS_LOGS_PARAMS)

set-bucket-permissions:
	@echo "*** Set permissions to bucket $(S3_EXPORT_LOGS_BUCKET_NAME)"
	cat ../operations/export-logs/s3.bucket.permissions.yaml | \
		AWS_REGION=$(AWS_REGION) EXPORT_LOGS_BUCKET=$(S3_EXPORT_LOGS_BUCKET_NAME) \
		 envsubst > /tmp/$(S3_EXPORT_LOGS_BUCKET_NAME).policy.yaml

	$(AWS) s3api put-bucket-policy --bucket $(S3_EXPORT_LOGS_BUCKET_NAME) \
		--policy file:///tmp/$(S3_EXPORT_LOGS_BUCKET_NAME).policy.yaml

prepare-export-logs-bucket: create-s3-export-logs-bucket set-bucket-permissions

launch-export-task: prepare-export-logs-bucket
	$(eval TASK_ID := $(shell $(AWS) logs create-export-task --task-name $(S3_EXPORT_LOGS_BUCKET_NAME) \
		--log-group-name $(CLUSTER_STACK_NAME) \
		--destination $(S3_EXPORT_LOGS_BUCKET_NAME) \
		--from 0 --to $(now)000 | jq -r '.taskId'))

	@echo "Launched export task id $(TASK_ID)"

wait_for_export:
	while [[ $$(aws logs describe-export-tasks --task-id "$(TASK_ID)" | jq -r '.exportTasks[0].status.code') =~ RUNNING|PENDING|PENDING_CANCEL ]]; do \
  		echo "Wait for task $(TASK_ID) to complete"; \
  		sleep 5; \
  	done;

	@echo "Export logs to $(S3_EXPORT_LOGS_BUCKET_NAME) reached a terminal state"
	$(AWS) logs describe-export-tasks --task-id "$(TASK_ID)" | jq -r '.exportTasks[0].status.code'

export-logs: launch-export-task wait_for_export
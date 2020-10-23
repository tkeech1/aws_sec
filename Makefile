# AWS
AWS_ACCESS_KEY_ID?=AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY?=AWS_SECRET_ACCESS_KEY
AWS_REGION?=AWS_REGION
ENVIRONMENT?=dev
# use the env var
ENVIRONMENT?=ENVIRONMENT

test-env:
	echo "environment is ${ENVIRONMENT}"

create-backend:
	cd s3_state && terraform init; terraform fmt; terraform apply -auto-approve -var="environment=${ENVIRONMENT}";

destroy-backend:
	cd s3_state && terraform init; terraform destroy -auto-approve -var="environment=${ENVIRONMENT}";

plan:
	terraform init; terraform validate; terraform plan -var="environment=${ENVIRONMENT}";

apply:
	terraform init; terraform fmt; terraform apply -auto-approve -var="environment=${ENVIRONMENT}";

destroy:
	terraform init; terraform destroy -auto-approve -var="environment=${ENVIRONMENT}"

clean:
	rm -rf .terraform; rm -rf s3_state/.terraform; rm -rf s3_state/terraform.tfstate; rm -rf s3_state/terraform.tfstate.backup;
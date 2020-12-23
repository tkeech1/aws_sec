# AWS
AWS_ACCESS_KEY_ID?=AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY?=AWS_SECRET_ACCESS_KEY
AWS_REGION?=AWS_REGION
AWS_ACCOUNT_ID?=AWS_ACCOUNT_ID
IP_CIDR?=IP_CIDR
ENVIRONMENT?=dev
# use the env var
ENVIRONMENT?=ENVIRONMENT

test-env:
	echo "environment is ${ENVIRONMENT}"

create-backend:
	cd s3_state && terraform init; terraform fmt; terraform apply -auto-approve -var="environment=${ENVIRONMENT}";

destroy-backend:
	cd s3_state && terraform init; terraform destroy -auto-approve -var="environment=${ENVIRONMENT}";

apply:
	terraform init; terraform fmt; terraform apply -auto-approve -var="environment=${ENVIRONMENT}" -var="ip_cidr=${IP_CIDR}";

plan:
	terraform init; terraform fmt; terraform plan -var="environment=${ENVIRONMENT}" -var="ip_cidr=${IP_CIDR}";

apply-s3:
	terraform init; terraform fmt; terraform apply -target=module.s3 -auto-approve -var="environment=${ENVIRONMENT}" -var="ip_cidr=${IP_CIDR}";

destroy:
	terraform init; terraform destroy -auto-approve -var="environment=${ENVIRONMENT}" -var="ip_cidr=${IP_CIDR}";

clean:
	rm -rf .terraform; rm -rf s3_state/.terraform; rm -rf s3_state/terraform.tfstate; rm -rf s3_state/terraform.tfstate.backup;

upload-s3:
	aws s3 cp ./modules/ec2/main.py s3://tdk-awssec-s3-web.io-${ENVIRONMENT}/
	aws s3 cp ./modules/ec2/awslogs.conf s3://tdk-awssec-s3-web.io-${ENVIRONMENT}/

web: apply-s3 upload-s3 apply


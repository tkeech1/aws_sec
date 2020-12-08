# AWS
AWS_ACCESS_KEY_ID?=AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY?=AWS_SECRET_ACCESS_KEY
AWS_REGION?=AWS_REGION
AWS_ACCOUNT_ID?=AWS_ACCOUNT_ID
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

apply-ec2:
	terraform init; terraform fmt; terraform apply -target=module.ec2_webserver -auto-approve -var="environment=${ENVIRONMENT}";

plan-ec2:
	terraform init; terraform fmt; terraform plan -target=module.ec2_webserver -var="environment=${ENVIRONMENT}";

apply-s3:
	terraform init; terraform fmt; terraform apply -target=module.s3 -auto-approve -var="environment=${ENVIRONMENT}";

destroy:
	terraform init; terraform destroy -auto-approve -var="environment=${ENVIRONMENT}"

clean:
	rm -rf .terraform; rm -rf s3_state/.terraform; rm -rf s3_state/terraform.tfstate; rm -rf s3_state/terraform.tfstate.backup;

upload-s3:
	aws s3 cp ./modules/ec2/main.py s3://tdk-awssec-s3-web.io-${ENVIRONMENT}/

web: apply-s3 upload-s3 apply-ec2


# AWS
AWS_ACCESS_KEY_ID?=AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY?=AWS_SECRET_ACCESS_KEY
AWS_REGION?=AWS_REGION
AWS_ACCOUNT_ID?=AWS_ACCOUNT_ID
IP_CIDR?=IP_CIDR
EMAIL_ADDRESS?=EMAIL_ADDRESS
ENVIRONMENT?=dev
# use the env var
ENVIRONMENT?=ENVIRONMENT

test-env:
	echo "environment is ${EMAIL_ADDRESS}"

create-backend:
	cd s3_state && terraform init; terraform fmt; terraform apply -auto-approve -var="environment=${ENVIRONMENT}";

destroy-backend:
	cd s3_state && terraform init; terraform destroy -auto-approve -var="environment=${ENVIRONMENT}";

apply:
	terraform init; terraform fmt; terraform apply -auto-approve -var="environment=${ENVIRONMENT}" -var="ip_cidr=${IP_CIDR}" -var="email_address=${EMAIL_ADDRESS}";

plan:
	terraform init; terraform fmt; terraform plan -var="environment=${ENVIRONMENT}" -var="ip_cidr=${IP_CIDR}" -var="email_address=${EMAIL_ADDRESS}";

# create the S3 buckets for source code and alb logs
apply-s3:
	terraform init; terraform fmt; terraform apply -target=module.s3 -auto-approve -var="environment=${ENVIRONMENT}" -var="ip_cidr=${IP_CIDR}" -var="email_address=${EMAIL_ADDRESS}";

destroy:
	terraform init; terraform destroy -auto-approve -var="environment=${ENVIRONMENT}" -var="ip_cidr=${IP_CIDR}" -var="email_address=${EMAIL_ADDRESS}";

clean:
	rm -rf .terraform; rm -rf s3_state/.terraform; rm -rf s3_state/terraform.tfstate; rm -rf s3_state/terraform.tfstate.backup;

upload-s3:
	aws s3 cp ./modules/ec2/main.py s3://tdk-awssec-s3-web.io-${ENVIRONMENT}/
	aws s3 cp ./modules/ec2/streamlit_app.py s3://tdk-awssec-s3-web.io-${ENVIRONMENT}/
	aws s3 cp ./modules/ec2/awslogs.conf s3://tdk-awssec-s3-web.io-${ENVIRONMENT}/

web: apply-s3 upload-s3 apply

# pretty cool one liner but it's not used. terraform can create self-signed certs. see acm module.
#create-cert:
	#openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=US/ST=US/L=US/O=TK/CN=${ENVIRONMENT}" -keyout certs/${ENVIRONMENT}.key -out certs/${ENVIRONMENT}.cert



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

destroy:
	terraform init; terraform destroy -auto-approve -var="environment=${ENVIRONMENT}" -var="ip_cidr=${IP_CIDR}" -var="email_address=${EMAIL_ADDRESS}";

clean:
	rm -rf .terraform; rm -rf s3_state/.terraform; rm -rf s3_state/terraform.tfstate; rm -rf s3_state/terraform.tfstate.backup;

# create the S3 buckets for source code and alb logs
apply-s3:
	terraform init; terraform fmt; terraform apply -target=module.s3 -auto-approve -var="environment=${ENVIRONMENT}" -var="ip_cidr=${IP_CIDR}" -var="email_address=${EMAIL_ADDRESS}";

apply-ec2:
	terraform init; terraform fmt; terraform apply -target=module.ec2_webserver -auto-approve -var="environment=${ENVIRONMENT}" -var="ip_cidr=${IP_CIDR}" -var="email_address=${EMAIL_ADDRESS}";

apply-code-update:
	terraform init; terraform fmt; terraform destroy -target=module.code_update -auto-approve -var="environment=${ENVIRONMENT}" -var="ip_cidr=${IP_CIDR}" -var="email_address=${EMAIL_ADDRESS}";
	terraform init; terraform fmt; terraform apply -target=module.code_update -auto-approve -var="environment=${ENVIRONMENT}" -var="ip_cidr=${IP_CIDR}" -var="email_address=${EMAIL_ADDRESS}";

apply-ecr:
	terraform init; terraform fmt; terraform apply -target=module.ecr -auto-approve -var="environment=${ENVIRONMENT}" -var="ip_cidr=${IP_CIDR}" -var="email_address=${EMAIL_ADDRESS}";

upload-s3:
	aws s3 cp ./code/main.py s3://tdk-awssec-s3-web.io-${ENVIRONMENT}/
	#aws s3 cp ./code/streamlit_app.py s3://tdk-awssec-s3-web.io-${ENVIRONMENT}/
	aws s3 cp ./modules/ec2/awslogs.conf s3://tdk-awssec-s3-web.io-${ENVIRONMENT}/

build-image:
	#cd code && docker build . -f Dockerfile_fastapi -t ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/bandit_repo/service:latest
	cd code && docker build . -f Dockerfile_streamlit -t ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/bandit_repo/service:latest

authenticate-docker-ecr:
	aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com

push-image: authenticate-docker-ecr
	docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/bandit_repo/service:latest

describe-image-repo:
	aws ecr describe-images --repository-name bandit_repo/service

web: apply-s3 apply-ecr upload-s3 apply-ec2 apply-code-update build-image push-image apply

# pretty cool one liner but it's not used. terraform can create self-signed certs. see acm module.
#create-cert:
	#openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=US/ST=US/L=US/O=TK/CN=${ENVIRONMENT}" -keyout certs/${ENVIRONMENT}.key -out certs/${ENVIRONMENT}.cert



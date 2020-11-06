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

destroy:
	terraform init; terraform destroy -auto-approve -var="environment=${ENVIRONMENT}"

clean:
	rm -rf .terraform; rm -rf s3_state/.terraform; rm -rf s3_state/terraform.tfstate; rm -rf s3_state/terraform.tfstate.backup;

authenticate-docker-ecr:
	aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com

build-image: 
	cd ./code/awswa/module-2/app && docker build . -t ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/mwa_ecr_repo/service:latest

push-image: authenticate-docker-ecr
	docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/mwa_ecr_repo/service:latest

describe-image-repo:
	aws ecr describe-images --repository-name mwa_ecr_repo/service

# run this target outside the devcontainer
run-container:
	docker run -p 8080:8080 ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/mwa_ecr_repo/service:latest
	# browse to http://localhost:8080/mysfits
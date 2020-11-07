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

plan-infra:
	terraform init; terraform validate; terraform plan -target=module.mwa -target=module.mwa_ecr -var="environment=${ENVIRONMENT}";

plan-ecs:
	terraform init; terraform validate; terraform plan -target=module.mwa_ecs -var="environment=${ENVIRONMENT}";

apply-infra:
	terraform init; terraform fmt; terraform apply -target=module.mwa -target=module.mwa_ecr -auto-approve -var="environment=${ENVIRONMENT}";

apply-ecs:
	terraform init; terraform fmt; terraform apply -target=module.mwa_ecs -auto-approve -var="environment=${ENVIRONMENT}";

destroy-ecs:
	terraform init; terraform fmt; terraform destroy -target=module.mwa_ecs -auto-approve -var="environment=${ENVIRONMENT}";

destroy:
	terraform init; terraform destroy -auto-approve -var="environment=${ENVIRONMENT}"

clean:
	rm -rf .terraform

authenticate-docker-ecr:
	aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com

build-image: 
	cd ../../code/awswa/module-2/app && docker build . -t ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/mwa_ecr_repo/service:latest

push-image: authenticate-docker-ecr
	docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/mwa_ecr_repo/service:latest

describe-image-repo:
	aws ecr describe-images --repository-name mwa_ecr_repo/service

# run this target outside the devcontainer
run-container:
	docker run -p 8080:8080 ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/mwa_ecr_repo/service:latest
	# browse to http://localhost:8080/mysfits

apply-all: apply-infra build-image push-image apply-ecs


# TODO - NACLS and Security Group Rules
# TODO - Private subnet

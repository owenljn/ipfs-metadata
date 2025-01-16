## To build and run it locally:
  docker build -t ipfs-metadata:latest . --no-cache
  docker run -d -p 8080:8080 --name ipfs-metadata -e POSTGRES_USER=user -e POSTGRES_PASSWORD=password -e POSTGRES_DB=testdb -e POSTGRES_HOST=host.docker.internal -e POSTGRES_PORT=5432 ipfs-metadata:latest

  Note POSTGRES_HOST is overwritten to be host.docker.internal instead of localhost, because if we are using locally running postgreSQL server, it needs to be point to host.docker.internal

## To trigger the CI/CD pipeline:
  Since we are using GitHub Actions, the workflows are configured locally, when making changes to the source code and commit them to GitHub, the GitHub action will be automatically be triggered and proceed to build the docker image and push it to AWS ECR.

## To deploy the application using Terraform:
  Inside of the Terraform dir of the root dir, run: terraform plan -out -var="aws_region=us-east-1"   -var="db_username=user"  -var="db_password=password" -var="ecr_repository_url=590331242805.dkr.ecr.us-east-1.amazonaws.com/blockparty"

  And when it confirms working, run: terraform apply -auto-approve -var="aws_region=us-east-1"   -var="db_username=blockparty_user"   -var="db_password=blockparty_password"   -var="ecr_repository_url=590331242805.dkr.ecr.us-east-1.amazonaws.com/blockparty"

## To test out the deployed app:
  Go to this link in the browser: http://blockparty-env-alb-460195511.us-east-1.elb.amazonaws.com/metadata

## Notes
  I use my own AWS account to create an IAM user, and uses its Access key and passwords as GitHub Action secrets, the aws region used is us-east-1, during the deployment, I decided to use a dedicated RDS for postgresql service instead of packing it with the container as this is more of the best practice.
  Additionally, I configured the health check endpoint to be /metadata instead of the standard /health since this app has no /health endpoint.

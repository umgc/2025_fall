docker login --username AWS -p $(aws ecr get-login-password --region $env:AWS_REGION) "$env:AWS_REG_ID.dkr.ecr.$env:AWS_REGION.amazonaws.com"
docker build -t edulense-program-grader-ecr-repo .
docker tag edulense-program-grader-ecr-repo:latest $env:AWS_REPO_URL`:latest
docker push $env:AWS_REPO_URL`:latest

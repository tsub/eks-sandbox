# eks-sandbox

## Requirements

* Terraform
* kubectl
* awscli
* aws-iam-authenticator
* curl or wget

## Setup

```
$ cp .envrc{.skeleton,} # and edit .envrc
$ cp .env{.skeleton,} # and edit .env
$ direnv allow
$ aws s3 mb s3://tsub-tfstate
$ aws dynamodb create-table \
    --table-name tsub-tfstate-locking \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --billing-mode PAY_PER_REQUEST
$ terraform -chdir=terraform init
```

## Destroy

```
# Workaround
$ terraform state rm module.eks.kubernetes_config_map.aws_auth
$ terraform state rm kubernetes_service.game-2048
$ terraform state rm kubernetes_namespace.game-2048
$ terraform state rm kubernetes_deployment.game-2048
$ terraform state rm helm_release.aws-load-balancer-controller

$ terraform destroy
```

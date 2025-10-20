set -euo pipefail

REGION="${1:-"us-east-1"}"
BUCKET="${2: devops-rampup-terraform-state-qa-439391123226}"
DYNAMO_TABLE="${3:-devops-rampup-terraform-lock-qa}"
AWS_PROFILE="${AWS_PROFILE:-default}

echo "using the profile: $AWS_PROFILE, region: $REGION"
export AWS_PROFILE

if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
	echo "Bucket $BUCKET already exist"
else
	echo "Creating S3 bucket $BUCKET in $REGION..."
	if [ "$REGION" = "us-east-1" ]; then
		aws s3api create-bucket --bucket "$BUCKET" --region "$REGION"
	else
		aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" --create-bucket-configuration LocationConstraint="$REGION"
	fi
fi

echo "enabling versioning..."
aws s3api put-bucket-versioning --bucket "$BUCKET" \
	--versioning-configuration Status=Enabled

echo "Enabling encryption SSE-S3 by default..."
aws s3api put-bucket-encryption --bucket "$BUCKET" \
	--server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

if aws dynamodb describe-table --table-name "$DYNAMO_TABLE" --region "$REGION" 2>/dev/null; then
	echo "DynamoDB Table $DYNAMO_TABLE already exists"
else 
	echo "Creating DynamoDb table $DYNAMO_TABLE..."
	aws dynamodb create-table \
		--table-name "$DYNAMO_TABLE" \
		--attribute-definitions AttributeName=LockID,AttributeType=S \
		--key-schema AttributeName=LockID,KeyType=HASH \
		--billing-mode PAY_PER_REQUEST \
		--region "$REGION"

fi

echo "Done, please keep an eye at the console or run aws s3 ls / aws dynamodb describe-table to verify it"
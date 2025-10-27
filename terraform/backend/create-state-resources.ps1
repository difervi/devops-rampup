param(
  [string]$Region = 'us-east-1',
  [string]$Bucket = 'devops-rampup-terraform-state-qa-439391123226',
  [string]$DynamoTable = 'devops-rampup-terraform-lock-qa',
  [string]$AwsProfile = $env:AWS_PROFILE
)

if (-not $AwsProfile) { $AwsProfile = 'default' }
Write-Output "using the profile: $AwsProfile, region: $Region"

$null = & aws s3api head-bucket --bucket $Bucket --profile $AwsProfile 2>$null
if ($LASTEXITCODE -eq 0) {
  Write-Output "Bucket $Bucket already exist"
} else {
  Write-Output "Creating S3 bucket $Bucket in $Region..."
  if ($Region -eq 'us-east-1') {
    & aws s3api create-bucket --bucket $Bucket --region $Region --profile $AwsProfile
  } else {
    & aws s3api create-bucket --bucket $Bucket --region $Region --create-bucket-configuration @{LocationConstraint=$Region} --profile $AwsProfile
  }
}

Write-Output "enabling versioning..."
& aws s3api put-bucket-versioning --bucket $Bucket --versioning-configuration Status=Enabled --profile $AwsProfile

Write-Output "Enabling encryption SSE-S3 by default..."
& aws s3api put-bucket-encryption --bucket $Bucket --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' --profile $AwsProfile

$null = & aws dynamodb describe-table --table-name $DynamoTable --region $Region --profile $AwsProfile 2>$null
if ($LASTEXITCODE -eq 0) {
  Write-Output "DynamoDB Table $DynamoTable already exists"
} else {
  Write-Output "Creating DynamoDb table $DynamoTable..."
  & aws dynamodb create-table --table-name $DynamoTable --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region $Region --profile $AwsProfile
}

Write-Output "Done, please keep an eye at the console or run aws s3 ls / aws dynamodb describe-table to verify it"

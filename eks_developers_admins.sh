# Role name
ROLE_NAME="EKS-Developers-Admins"

# Ger User Id & Account Id
user_id=$(aws sts get-caller-identity | jq -r .UserId | cut -d: -f2)
account_id=$(aws sts get-caller-identity | jq -r .Account)

# Assume role
aws sts assume-role --role-arn "arn:aws:iam::${account_id}:role/${ROLE_NAME}" --role-session-name $user_id > creds

# Create sts file if not exists
if ! [ -f 'sts' ]; then
	echo "export AWS_ACCESS_KEY_ID=\$(cat creds | jq -r .Credentials.AccessKeyId)" >> sts
	echo "export AWS_SECRET_ACCESS_KEY=\$(cat creds | jq -r .Credentials.SecretAccessKey)" >> sts
	echo "export AWS_SESSION_TOKEN=\$(cat creds | jq -r .Credentials.SessionToken)" >> sts
fi

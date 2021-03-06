#!/bin/bash
# About: This script automate asume Role process agains AWS IAM to enable ability to operate multiple EKS cluster from deferent federated users
function check_command_exit_status() {
  __EXIT_STATUS=$1
  if [ ${__EXIT_STATUS} != 0 ]; then
    echo "sts-eks.sh failed to to work"
    rm -f ${_AWS_ROLE_NAME}.json
    rm -f ${_CREDS_FILE}
    unset _JSON
    return 1
  fi
}

if [ -z "${AWS_ACCESS_KEY_ID}" ]; then
  echo "AWS Access Key is messing"
  echo "Export federated AWS variables from OKTA"
  echo "Link to Checkmarx OKTA: https://d-93670137ee.awsapps.com/start#/"
  return 1
fi

if [ -z "${AWS_REGION}" ]; then
  echo "AWS_REGION is messing using [eu-west-1] as default"
  export AWS_REGION=eu-west-1  
fi


_AWS_ROLE_NAME="Jenkins-Role"
_CREDS_FILE=$(uuidgen)
_SESSION_NAME=$(uuidgen)

_JSON=$(aws sts get-caller-identity)

user_arn=$(echo ${_JSON} | jq ."Arn")
user_account_id=$(echo ${_JSON} | jq -r ."Account")


# Get existing Role jnos
_JSON=$(aws iam get-role --role-name Jenkins-Role | jq .)
check_command_exit_status $?

echo ${_JSON} | jq ".Role.AssumeRolePolicyDocument.Statement[0].Principal.AWS += [${user_arn}]" | jq ".Role.AssumeRolePolicyDocument" > "${_AWS_ROLE_NAME}.json" && echo "Role json created [ ${_AWS_ROLE_NAME}.json ]"
check_command_exit_status $?

aws iam update-assume-role-policy --role-name ${_AWS_ROLE_NAME} --policy-document file://"${_AWS_ROLE_NAME}.json" && echo "Role updated"
check_command_exit_status $?

aws sts assume-role --role-arn "arn:aws:iam::${user_account_id}:role/${_AWS_ROLE_NAME}" --role-session-name ${_SESSION_NAME} > ${_CREDS_FILE}
check_command_exit_status $?

# export new aws vars
echo "New AWS enviorments exported!"
export AWS_ACCESS_KEY_ID=$(cat ${_CREDS_FILE} | jq -r .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(cat ${_CREDS_FILE} | jq -r .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=$(cat ${_CREDS_FILE} | jq -r .Credentials.SessionToken)

echo "Available cluester in AWS_REGION=eu-west-1"
aws eks list-clusters | jq .

echo "Next: e.g > aws eks update-kubeconfig --name ClusterName --region eu-west-1"
rm -f ${_CREDS_FILE}

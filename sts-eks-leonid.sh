#!/bin/bash
# About: This script automate asume Role process agains AWS IAM to enable ability to operate multiple EKS cluster from deferent federated users
function check_command_exit_status() {
  __EXIT_STATUS=$1
  if [ ${__EXIT_STATUS} != 0 ]; then
    echo "sts-eks.sh failed to to work"
    rm -f ${_AWS_ROLE_NAME}.json
    rm -f ${_CREDS_FILE}
    unset _JSON
    exit 1
  fi
}

if [ -z "${AWS_ACCESS_KEY_ID}" ]; then
  echo "AWS_ACCESS_KEY_ID Access Key is messing"
  echo "Export federated AWS variables from OKTA"
  echo "Link to Checkmarx OKTA: https://d-93670137ee.awsapps.com/start#/"
  exit 1
fi

if [ -z "${AWS_REGION}" ]; then
  echo "AWS_REGION is messing using [eu-west-1] as default"
  export AWS_REGION=eu-west-1  
fi


_AWS_ROLE_NAME="Cx-Components-CI-Role"
_CREDS_FILE=$(uuidgen)
_SESSION_NAME=$(uuidgen)

_JSON=$(aws sts get-caller-identity)

user_arn=$(echo ${_JSON} | jq ."Arn")
user_account_id=$(echo ${_JSON} | jq -r ."Account")

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
rm -f "${_AWS_ROLE_NAME}.json"

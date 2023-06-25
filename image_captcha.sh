#!/bin/bash

# ------------- Credentials ---------------
CLIENT_ID="YOUR_CLIENT_ID" #****CHANGE HERE WITH YOUR VALUE*******
CLIENT_SECRET="YOUR_CLIENT_SECRET" #****CHANGE HERE WITH YOUR VALUE*******
EMAIL="YOUR_ACCOUNT_EMAIL" #****CHANGE HERE WITH YOUR VALUE*******
PASSWORD="YOUR_ACCOUNT_PASSWORD" #****CHANGE HERE WITH YOUR VALUE*******
# ------------- Credentials ---------------


# Token file path
TOKEN_FILE_PATH="$(dirname "$0")/metabypass.token"

if [ -z "$1" ]; then
    cli_img_path=""
else
  cli_img_path="$1"
fi

#ACCESS TOKEN REQUESTER
accessTokenRequester() {
  local url="https://app.metabypass.tech/CaptchaSolver/oauth/token"
  local params="$1"
  local method="$2"

  curl -s -X POST -d "$params" -H 'Content-type: application/json' 'Accept: application/json' https://app.metabypass.tech/CaptchaSolver/oauth/token
}


# ACCESS TOKEN HANDLER
getNewAccessToken() {

  local payload='{"grant_type":"password","client_id":"'"$CLIENT_ID"'","client_secret":"'"$CLIENT_SECRET"'","username":"'"$EMAIL"'","password":"'"$PASSWORD"'"}'
  local response=$(accessTokenRequester "$payload" "POST")

  local access_token=$(echo "$response" | jq -r '.access_token')



  if [ -n "$access_token" ]; then
    echo "$access_token" > "$TOKEN_FILE_PATH"
    echo "$access_token"
  else
    echo "error! unauth"
    exit 1
  fi
}

#REQUESTER
request() {
  local url=$1
  local params="$2"
  local method="$3"
  local access_token="$4"
  curl -s -X POST -d @"$params" -H  "Content-type: application/json" -H "Accept: application/json" -H "Authorization: Bearer $access_token" $url
  rm "$params"
}

# IMAGE CAPTCHA REQUSTER
imageCaptcha() {
  local image_base64_encoded="$1"
  local request_url="https://app.metabypass.tech/CaptchaSolver/api/v1/services/captchaSolver"
  local payload="{\"image\": \"$image_base64_encoded\"}"
  echo "$payload" > "tmp.json"

  # Generate access token
  local access_token=""
  if [ -f "$TOKEN_FILE_PATH" ]; then
    access_token=$(cat "$TOKEN_FILE_PATH")
  else
    access_token=$(getNewAccessToken)
  fi

  local access_token=$access_token
  local response=$(request "$request_url" "tmp.json" "POST" "$access_token")

  local status_code=$(echo "$response" | jq -r '.status_code')


  if [ -n "$status_code" ]; then
    if [ "$status_code" -eq 401 ]; then

      access_token=$(getNewAccessToken)

      response=$(request "$request_url" "$payload" "POST" "$access_token")
    fi

    if [ "$status_code" -eq 200 ]; then
      echo "$response" | jq -r '.data.result'
    else

      echo "$(echo "$response" | jq -r '.message')"
      exit 1
    fi
  else
    exit 1
  fi
}

# HELPER
convert_image_to_base64() {
  local image_path="$1"
  local data=$(base64 -w 0 "$image_path")
  echo "$data"
}



# --------------------------------- USAGE --------------------------------
if [ -z "$cli_img_path" ]; then
    #pass your image captcha pass here like: 'samples/icaptcha1.jpg'
    img_base64_encoded=$(convert_image_to_base64 "samples/icaptcha1.jpg")
else
    #You can path image path from CLI too. like: ./image_captcha.sh 'samples/icaptcha1.jpg'
    img_base64_encoded=$(convert_image_to_base64 "$cli_img_path")
fi

# execute
image_captcha=$(imageCaptcha "$img_base64_encoded")
echo "$image_captcha"

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

#REUESTER
request() {
  local url="$1"
  local params="$2"
  local method="$3"
  local access_token="$4"

  curl -s -X "$method" -d "$params" -H  "Content-type: application/json" -H "Accept: application/json" -H "Authorization: Bearer $access_token" $url

}

# reCAPTCHA v2 REQUESTER
reCaptchaV2() {

  local site_url="$1"
  local site_key="$2"
  local version="2"
  local request_url="https://app.metabypass.tech/CaptchaSolver/api/v1/services/bypassReCaptcha"
  local payload="{\"url\": \"$site_url\",\"sitekey\": \"$site_key\",\"version\": \"$version\"}"

  # Generate access token
  local access_token=""
  if [ -f "$TOKEN_FILE_PATH" ]; then
    access_token=$(cat "$TOKEN_FILE_PATH")
  else
    access_token=$(getNewAccessToken)
  fi

  local access_token=$access_token
  local response=$(request "$request_url" "$payload" "POST" "$access_token")
  local status_code=$(echo "$response" | jq -r '.status_code')
  local message=$(echo "$response" | jq -r '.message')


  if [ -n "$status_code" ]; then
    if [ "$status_code" -eq 401 ]; then

      access_token=$(getNewAccessToken)

      response=$(request "$request_url" "$payload" "POST" "$access_token")
    fi

    if [ "$status_code" -eq 200 ]; then
      echo "$response" | jq -r '.data.RecaptchaId'
      return 0

    else
      echo "$message"
      return 1
    fi

  else
    echo "$message"
    return 1
  fi
}

# GET RESULT REQUESTER
getResult() {

  local recaptcha_id="$1"
  local request_url="https://app.metabypass.tech/CaptchaSolver/api/v1/services/getCaptchaResult"
  local payload="{\"recaptcha_id\": \"$recaptcha_id\"}"

  # Generate access token
  local access_token=""
  if [ -f "$TOKEN_FILE_PATH" ]; then
    access_token=$(cat "$TOKEN_FILE_PATH")
  else
    access_token=$(getNewAccessToken)
  fi

  local access_token=$access_token
  local response=$(request "$request_url" "$payload" "GET" "$access_token")
  local status_code=$(echo "$response" | jq -r '.status_code')


  if [ -n "$status_code" ]; then
    if [ "$status_code" -eq 401 ]; then

      access_token=$(getNewAccessToken)

      response=$(request "$request_url" "$payload" "GET" "$access_token")
    fi

    if [ "$status_code" -eq 200 ]; then
      echo "$response" | jq -r '.data.RecaptchaResponse'
      return 0
    elif  [ "$status_code" -eq 201 ]; then
      echo "$response" | jq -r '.message'
      return 2
    else
      echo "$response" | jq -r '.message'
      return 1
    fi
  else
    echo "error"
    return 1
  fi
}


# AUTO HANDLER
reCaptchaV2Handler() {
    local url="$1"
    local sitekey="$2"

    # request reCaptcha v2 API
    recaptcha_response=$(reCaptchaV2 "$url" "$sitekey")
    status=$?

    if [ $status -eq 1 ]; then
      echo "$recaptcha_response"
      exit 1
    fi

    #handle get result (max: 60 seconds)
    for ((i = 0; i < 6; i++)); do
        # sleep 10 seconds to get result
        sleep 10

        # request get result API
        result=$(getResult "${recaptcha_response}")
        status=$?

        #echo "$result" # show get result response
        if [ $status -eq 1 ]; then
          echo "$result"
          return 1
        elif [ $status -eq 2 ]; then
            continue
        else
          echo "$result"
          return 0
        fi
    done
}



# --------------------------------- USAGE --------------------------------
site_url="SITE_URL"
site_key="SITE_KEY"

# execute
printf "to get recaptcha result wait 10 - 60 seconds\n"
result=$(reCaptchaV2Handler "$site_url" "$site_key")
echo "$result"

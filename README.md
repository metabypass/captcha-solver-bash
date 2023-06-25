# MetaBypass ( AI Captcha Solver )
## Bash script to work with [MetaBypass](https://metabypass.tech) services

Free demo (no credit card required) -> https://app.metabypass.tech/application

<br/>

### Features

Solve image captcha , reCaptcha v2 & v3 , invisible reCaptcha <br/>
Auto handler for reCaptcha v2 <br/>

<br/>
<br/>

## Requirements
if your machine doesn't have the jq package, you should install the jq on your machine <br>
check this [Link](https://jqlang.github.io/jq/download/)

<br/>
<br/>


## Usage

<br/>

at the top of all bash files , exists "Credentials" section <br>
fill these variables with your credentials <br>
to get credentials go to [Application](https://app.metabypass.tech/application) page on [MetaBypass](https://app.metabypass.tech) <br>

**Setup** <br />
 ```bash
 # ------------- Credentials ---------------
CLIENT_ID="YOUR_CLIENT_ID" #****CHANGE HERE WITH YOUR VALUE*******
CLIENT_SECRET="YOUR_CLIENT_SECRET" #****CHANGE HERE WITH YOUR VALUE*******
EMAIL="YOUR_ACCOUNT_EMAIL" #****CHANGE HERE WITH YOUR VALUE*******
PASSWORD="YOUR_ACCOUNT_PASSWORD" #****CHANGE HERE WITH YOUR VALUE*******
# ------------- Credentials ---------------
 ```
<br/>

then go to "USAGE" section at the end of bash script file and set your values like site_key & site_url for reCAPTCHA or image path for image captcha

 ```bash
# for reCAPTCHA ( v1,v2,invisible )
# --------------------------------- USAGE --------------------------------
site_url="SITE_URL"
site_key="SITE_KEY"
```
```bash
# for image captcha
# --------------------------------- USAGE --------------------------------
if [ -z "$cli_img_path" ]; then
    img_base64_encoded=$(convert_image_to_base64 "samples/icaptcha1.jpg") #****CHANGE HERE WITH YOUR VALUE*******
else
    #You can path image path from CLI too. like: ./image_captcha.sh 'samples/icaptcha1.jpg'
    img_base64_encoded=$(convert_image_to_base64 "$cli_img_path")
fi

```
<br/>

then you can call bash scripts

image captcha
```
./image_captcha.sh
```

reCAPTCHA v2
```
./recaptcha_v2.sh
```
reCAPTCHA v3
```
./recaptcha_v3.sh
```

reCAPTCHA invisible
```
./recaptcha_invisible.sh
```

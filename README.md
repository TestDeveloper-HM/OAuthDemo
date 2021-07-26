OAUTH2.0 using Authorisation code Flow

FRONT CHANNEL:  

Used to get a Authorisation Code.

1. /authorize Endpoint

Through OAuth Agents(Browsers)

Request:(To WebSession) (GET)

https://YOUR_DOMAIN/authorize?scope=SCOPE&response_type=code&client_id=YOUR_CLIENT_ID&redirect_uri=https://YOUR_APP/callback&state=STATE&scope=emial+openid&code+verifier=RANDOM_STRING_42-128_CHAR_LONG&code_challenge_method=S256

Query String Param:
response_type = code,
client_id = xxxxxxxx,
code_challenge_method  = S256,
code_challenge = SHA256_RANDOM_STRING_42-128_CHAR_LONG,
state = anything,
scope = openid email,
redirect_uri = oauthDemo://home,

Response(From Redirect):
URLComponents -
oauthDemo://home&code=AUTHORIZATION_CODE&state=anything

Parsing Athorization Grant to get Authorozation Code

BACK CHANNEL:  (Direct Client to Server/Machine Communication)

Used to redeem access token in exchange of authorisation code.

2. /oauth/token Endpoint

Through client to machine http request.

Request:(POST) 

HTTP BODY:
grant_type=authorization_code
client_id=xxxxxxxx
code_verifier=RANDOM_STRING_42-128_CHAR_LONG

Response:
We get the refresh token, Access token,  id_token with expire date

Refresh Token - Longer lived than refresh token

Can use the /oauth/token endpoint to get a new access token after it is expired by the help of refresh token.

HTTP Body:
grant_type =  refresh_token
refresh_token = REFRESH_TOKEN
client_id = xxxxxxxx

Response:
New Access token & expire time



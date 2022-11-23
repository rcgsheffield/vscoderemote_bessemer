#!/bin/sh

# [ global parameters ]
# certificate configuration
readonly CERT_DAYS=36500
readonly RSA_STR_LEN=4096
readonly PREFIX=vscode_remote_ssl-
readonly CERT_DIR=$HOME/.ssl/vscoderemote
readonly KEY_DIR=$HOME/.ssl/vscoderemote/private
# certificate content definition
readonly ADDRESS_COUNTRY_CODE=UK
readonly ADDRESS_PREFECTURE=SY
readonly ADDRESS_CITY=Sheffield
readonly COMPANY_NAME=NA
readonly COMPANY_SECTION=NA
readonly CERT_PASSWORD= # no password
# - ca
readonly CA_DOMAIN=localhost
CA_EMAIL=ca@email.address
# - server
readonly SERVER_DOMAIN=localhost
SERVER_EMAIL=server@email.address
# - client
readonly CLIENT_DOMAIN=localhost
CLIENT_EMAIL=client@email.address

# [ functions ]
echo_cert_params() {
    local company_domain="$1"
    local company_email="$2"

    echo $ADDRESS_COUNTRY_CODE
    echo $ADDRESS_PREFECTURE
    echo $ADDRESS_CITY
    echo $COMPANY_NAME
    echo $COMPANY_SECTION
    echo $company_domain
    echo $company_email
    echo $CERT_PASSWORD     # password
    echo $CERT_PASSWORD     # password (again)
}
echo_ca_cert_params() {
    echo_cert_params "$CA_DOMAIN" "$CA_EMAIL"
}
echo_server_cert_params() {
    echo_cert_params "$SERVER_DOMAIN" "$SERVER_EMAIL"
}
echo_client_cert_params() {
    echo_cert_params "$CLIENT_DOMAIN" "$CLIENT_EMAIL"
}


# [ main ]

#echo $CERT_DIR
#echo $KEY_DIR

read -p 'Email address: ' EMAIL_ADDRESS

if [ -z "$EMAIL_ADDRESS" ]
then
      echo "No email entered using defaults."
else
        CLIENT_EMAIL=$EMAIL_ADDRESS
        SERVER_EMAIL=$EMAIL_ADDRESS
        CA_EMAIL=$EMAIL_ADDRESS
fi

if [ ! -d "$CERT_DIR" ]; then
        echo -e "Making Certificate directory."
        mkdir -p $CERT_DIR
fi

if [ ! -d "$KEY_DIR" ]; then
        echo -e "Making Key directory."
        mkdir -p $KEY_DIR
fi

# generate certificates
# - ca
openssl genrsa $RSA_STR_LEN > $KEY_DIR/${PREFIX}ca-key.pem
echo_ca_cert_params | \
    openssl req -new -x509 -nodes -days $CERT_DAYS -key $KEY_DIR/${PREFIX}ca-key.pem -out $CERT_DIR/${PREFIX}ca-cert.pem
# - server
echo_server_cert_params | \
    openssl req -newkey rsa:$RSA_STR_LEN -days $CERT_DAYS -nodes -keyout $KEY_DIR/${PREFIX}server-key.pem -out $CERT_DIR/${PREFIX}server-req.pem
openssl rsa -in $KEY_DIR/${PREFIX}server-key.pem -out $KEY_DIR/${PREFIX}server-key.pem
openssl x509 -req -in $CERT_DIR/${PREFIX}server-req.pem -days $CERT_DAYS -CA $CERT_DIR/${PREFIX}ca-cert.pem -CAkey $KEY_DIR/${PREFIX}ca-key.pem -set_serial 01 -out $CERT_DIR/${PREFIX}server-cert.pem
# - client
echo_client_cert_params | \
    openssl req -newkey rsa:$RSA_STR_LEN -days $CERT_DAYS -nodes -keyout $KEY_DIR/${PREFIX}client-key.pem -out $CERT_DIR/${PREFIX}client-req.pem
openssl rsa -in $KEY_DIR/${PREFIX}client-key.pem -out $KEY_DIR/${PREFIX}client-key.pem
openssl x509 -req -in $CERT_DIR/${PREFIX}client-req.pem -days $CERT_DAYS -CA $CERT_DIR/${PREFIX}ca-cert.pem -CAkey $KEY_DIR/${PREFIX}ca-key.pem -set_serial 01 -out $CERT_DIR/${PREFIX}client-cert.pem

# clean up (before permission changed)
#rm $KEY_DIR/${PREFIX}ca-key.pem
rm $CERT_DIR/${PREFIX}server-req.pem
rm $CERT_DIR/${PREFIX}client-req.pem

# validate permission
chmod -R 500 $CERT_DIR/
chmod -R 500 $KEY_DIR/
chmod 400 $KEY_DIR/${PREFIX}server-key.pem
chmod 400 $KEY_DIR/${PREFIX}client-key.pem


# verify relationship among certificates
openssl verify -CAfile $CERT_DIR/${PREFIX}ca-cert.pem $CERT_DIR/${PREFIX}server-cert.pem $CERT_DIR/${PREFIX}client-cert.pem


# Inform user of certificate fingerprints

echo -e "=============================================================\n"

echo -e "Your server certificate has the following fingerprints: \n"
openssl x509 -in ~/.ssl/vscoderemote/vscode_remote_ssl-server-cert.pem -fingerprint -sha256 -noout
openssl x509 -in ~/.ssl/vscoderemote/vscode_remote_ssl-server-cert.pem -fingerprint -sha1 -noout

echo -e "=============================================================\n"

echo -e  "To see these fingerprints again please run the following commands: \n
openssl x509 -in ~/.ssl/vscoderemote/vscode_remote_ssl-server-cert.pem -fingerprint -sha256 -noout
openssl x509 -in ~/.ssl/vscoderemote/vscode_remote_ssl-server-cert.pem -fingerprint -sha1 -noout \n"

echo -e "=============================================================\n"

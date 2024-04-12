echo "Running .profile script"

mkdir -p ~/.postgresql/

echo "$VCAP_SERVICES" | jq -r '.["csb-google-postgres"][0].credentials.sslrootcert' > ~/.postgresql/root.crt
echo "$VCAP_SERVICES" | jq -r '.["csb-google-postgres"][0].credentials.sslcert' > ~/.postgresql/postgresql.crt
echo "$VCAP_SERVICES" | jq -r '.["csb-google-postgres"][0].credentials.sslkey' > ~/.postgresql/postgresql-key.pem
openssl pkcs8 -topk8 -inform PEM -in ~/.postgresql/postgresql-key.pem -outform DER -out ~/.postgresql/postgresql.pk8 -v1 PBE-MD5-DES -nocrypt
chmod 0600 ~/.postgresql/postgresql-key.pem ~/.postgresql/postgresql.pk8

export VCAP_SERVICES="$(echo "$VCAP_SERVICES" | jq '."csb-google-postgres"[0].credentials.jdbcUrl += "&sslrootcert=/home/vcap/app/.postgresql/root.crt&sslcert=/home/vcap/app/.postgresql/postgresql.crt&sslkey=/home/vcap/app/.postgresql/postgresql.pk8&sslmode=verify-ca"')"
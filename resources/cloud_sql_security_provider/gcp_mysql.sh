#!/bin/this-script-should-be-sourced-not-executed-directly
# This script will be run automatically by the Cloud Foundry Java Buildpack before the app is launched

RESTORE_OPTIONS=$(set +o)
set -euo pipefail

echo "Running .profile script for PostGres service"

# Trapping RETURN is necessary for sourced script, otherwise successful runs won't trigger the trap.
trap 'catch $?' EXIT RETURN
catch() {
  eval "$RESTORE_OPTIONS"

  if [ "$1" != "0" ]; then
    >&2 cat .profile.log     # Some error occurred: cat logs to stderr.
  else
    cat .profile.log         # No error occurred: cat logs to stdout.
  fi
  rm .profile.log
}

# keytool is bundled in the java-buildpack however their location is not exported in the PATH by default.
export PATH="$PATH:$(ls -d /app/.java-buildpack/*/bin/)"

mkdir -p "$HOME/.mysql/"


echo "$VCAP_SERVICES" | jq -r '.["csb-google-mysql"][0].credentials.sslrootcert' > "$HOME/.mysql/ca.pem"
echo "$VCAP_SERVICES" | jq -r '.["csb-google-mysql"][0].credentials.sslcert' > "$HOME/.mysql/client-cert.pem"
echo "$VCAP_SERVICES" | jq -r '.["csb-google-mysql"][0].credentials.sslkey' > "$HOME/.mysql/client-key.pem"

# keytool seems to be writing information messages to stderr.
# To counteract it, redirect all outputs to a file and let the trap above cat the file to stdout/stderr based on the exit code.
{
keytool -importcert                       \
  -alias MySQLCACert                      \
  -file "$HOME/.mysql/ca.pem"             \
  -noprompt                               \
  -keystore "$HOME/.mysql/truststore"     \
  -storepass "${KEYSTORE_PASSWORD}"

openssl pkcs12 -export                    \
  -in "$HOME/.mysql/client-cert.pem"      \
  -inkey "$HOME/.mysql/client-key.pem"    \
  -name "mysqlclient"                     \
  -passout "pass:${KEYSTORE_PASSWORD}"    \
  -out "$HOME/.mysql/client-keystore.p12"

keytool -importkeystore                           \
  -srckeystore "$HOME/.mysql/client-keystore.p12" \
  -srcstoretype pkcs12                            \
  -srcstorepass "${KEYSTORE_PASSWORD}"            \
  -destkeystore "$HOME/.mysql/keystore"           \
  -deststoretype pkcs12                           \
  -deststorepass "${KEYSTORE_PASSWORD}"

openssl pkcs8 -topk8 -inform PEM -in "$HOME/.mysql/client-key.pem" -outform DER -out "$HOME/.mysql/client.pk8" -v1 PBE-MD5-DES -nocrypt
chmod 0600 "$HOME/.mysql/client-key.pem" "/$HOME/.mysql/client.pk8"

export VCAP_SERVICES="$(echo "$VCAP_SERVICES" | jq --arg HOME "$HOME" --arg KEYSTORE_PASSWORD "$KEYSTORE_PASSWORD" '."csb-google-mysql"[0].credentials.jdbcUrl += "&trustCertificateKeyStoreUrl=file://\($HOME)/.mysql/truststore&trustCertificateKeyStorePassword=\($KEYSTORE_PASSWORD)&clientCertificateKeyStoreUrl=file://\($HOME)/.mysql/keystore&clientCertificateKeyStorePassword=\($KEYSTORE_PASSWORD)"')"

rm "$HOME/.mysql/ca.pem"
rm "$HOME/.mysql/client-cert.pem"
rm "$HOME/.mysql/client-key.pem"
} > .profile.log 2>&1
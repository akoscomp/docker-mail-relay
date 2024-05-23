#! /usr/bin/env ash
set -e # exit on error

# Variables
if [ -z "$SMTP_LOGIN" -o -z "$SMTP_PASSWORD" ] ; then
	echo "SMTP_LOGIN and SMTP_PASSWORD _must_ be defined"
	exit 1
fi
export SMTP_LOGIN SMTP_PASSWORD
export EXT_RELAY_HOST=${EXT_RELAY_HOST:-"mail.smtp2go.com"}
export EXT_RELAY_PORT=${EXT_RELAY_PORT:-"25"}
export RELAY_HOST_NAME=${RELAY_HOST_NAME:-"relay.example.com"}
export ACCEPTED_NETWORKS=${ACCEPTED_NETWORKS:-"192.168.0.0/16 172.16.0.0/12 10.0.0.0/8"}
export USE_TLS=${USE_TLS:-"no"}
export TLS_VERIFY=${TLS_VERIFY:-"may"}
export INBOUND_TLS=${INBOUND_TLS:-"yes"}
export RAW_CONFIG=${RAW_CONFIG:-""}

echo $RELAY_HOST_NAME > /etc/mailname

# Generate default certificates for tls support
if [ "${INBOUND_TLS}" == "yes" ] ; then
	echo "generate self signed ssl cert only if all cert files are empty or nonexistent"
	if [ -s /etc/ssl/cert.crt ] || [ -s /etc/ssl/key.pem ]; then
		echo "Skipping SSL certificate generation"
	else
		echo "Generating self-signed certificate"

		mkdir -p /etc/ssl
		cd /etc/ssl

		# Generating signing SSL private key
		openssl genrsa -des3 -passout pass:x -out key.pem 2048

		# Removing passphrase from private key
		cp key.pem key.pem.orig
		openssl rsa -passin pass:x -in key.pem.orig -out key.pem

		# Generating certificate signing request
		openssl req -new -key key.pem -out cert.csr -subj "/C=GB/ST=GB/L=London/O=MailRelay/OU=MailRelay/CN=default"

		# Generating self-signed certificate
		openssl x509 -req -days 3650 -in cert.csr -signkey key.pem -out cert.crt
	fi
fi

# Templates
jinjanate /root/conf/postfix-main.cf > /etc/postfix/main.cf
jinjanate /root/conf/sasl_passwd > /etc/postfix/sasl_passwd
postmap /etc/postfix/sasl_passwd

# Custom aliases
newaliases

# Launch
rm -f /var/spool/postfix/pid/*.pid
#exec /usr/bin/supervisord -n -c /etc/supervisord.conf
echo "Starting postfix"
exec /usr/sbin/postfix start-fg
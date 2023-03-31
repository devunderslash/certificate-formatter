FROM bash:latest

#  install openssl
RUN apk add --no-cache openssl

# copy bash script to container
COPY . /app

# set working directory
WORKDIR /app

RUN chmod +x format_cert.sh

# run bash script
CMD ["bash", "format_cert.sh", "vault_grab.txt"]
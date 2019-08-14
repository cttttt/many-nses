FROM ubuntu:18.04
RUN apt update && apt install -y bind9 bind9utils bind9-doc dnsutils
COPY entrypoint /usr/local/bin/entrypoint
RUN chmod u+x /usr/local/bin/entrypoint
CMD [ "/usr/local/bin/entrypoint" ]

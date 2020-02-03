FROM ubuntu:18.04
COPY client.sh proxy.sh /usr/local/bin/
RUN apt-get update && apt install -y \
    iptables \
    net-tools \
    curl \
    iputils-ping \
    tcpdump \
    traceroute \
    netcat \
    iproute2 \
    ssh \
    dnstop
#CMD python /app/app.py
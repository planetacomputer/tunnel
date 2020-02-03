#!/bin/bash
docker-compose up -d
docker exec -it client bash -c /usr/local/bin/client.sh
docker exec -it proxy bash -c /usr/local/bin/proxy.sh
docker exec -it proxy bash -c "chmod +x /usr/local/bin/proxy.sh"
docker exec -it client bash -c "chmod +x /usr/local/bin/client.sh"

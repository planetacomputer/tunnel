[TOC]

#### Objectius

- Conèixer els diferents tipus de túnels SSH (local estàtic, local dinàmic i revers) en un entorn Docker i en base a casuístiques d'ús basades en gestió de la seguretat. Per això es creen dos contenidors (proxy i client) sistemes operatius Ubuntu en una xarxa virtual. S'ha creat una configuració de xarxa en què les connexions de client s'enruten a través de *proxy*, de forma que amb els diversos sniffers instal·lats en aquest contenidors som capaços de veure les peticions de *client*. 
1. Quin túnel ha d'establir *client* per tal d'evitar que *proxy* pugui veure les seves adreces url de connexió (curl)
2. Quin túnel ha d'establir *client* per tal d'evitar que *proxy* pugui veure el contingut dels seus missatges de chat amb la connexió nc
3. Quin túnel ha d'establir *client* per tal de publicar la seva pàgina web de manera que pugui ser visible des de qualsevol dispositiu amb connexió a Internet?

- Serà necessari que l'alumne disposi d'un altre servidor extern on dur a terme la creació de túnnels SSH;

#### Conceptes
- Docker Compose;
- IPTables;
- route -n;
- Sniffing (dnshost, tcpdump, etc.);

#### Descarrega el projecte
         `git clone planetacomputer/tunnel`
#### Creació de la imatge
- Fes el build del Docker per crear la imatge, la mateix en proxy i client:
        `docker build -t planetacomputer/tunnel .`
    
- Comprova que s'ha creat amb la comanda:\
        `docker images`
    
#### Arrencada
- Executa l'script que arrenca els contenidors amb Docker Compose. NO cridis directament docker-compose perquè l'script conté algunes tasques més: 
        `./start-docker-compose.sh`
    
- Introdueix-te en la consola bash d'ambdós contenidors, cada un en un terminal diferent:\
		`docker exec -it client bash`\
		`docker exec -it proxy bash`
    
#### Connectivitat
- Comprova que ambdos contenidors tenen connectivitat entre sí:
        	`ping client`\
		`ping proxy` \
		`docker inspect client | grep IPAddress`\
		`docker inspect proxy | grep IPAddress` 
- Compara la taula de rutes d'ambdós contenidors i comenta-les. Executa traceroute a cadascuna d'elles i comenta la diferència:  
            `route -n`\
	    `traceroute 8.8.8.8`\
![Alt text](images/traceroute.png?raw=true "Title")
            
- Per comprovar que el tràfic de client passa per proxy, iniciem en aquest últim dnstop:  
`dnstop eth0 -l 3`  
Un cop arrencat amb la tecla num 3 podrem veure el llistat de dominis que va resolent, i que aniran apareixent a mesura que client va fent pings o curls a dominis.


#### Repte 1. Evitar sniffing de proxy sobre chat netcat en un determinat port (túnel local estàtic)
Per aquest repte obrim un servei netcat en el servidor AWS (yum install nmap-ncat):  
`nc -l 4444`  
Ens connectem des del client  
`netcat ec2-35-175-200-4.compute-1.amazonaws.com 4444`  
i podem sniffar des del proxy i veure el text amb la comanda:  
`tcpdump -Aq -i eth0 tcp port 4444`  
Per evitar això, crearem un túnel local estàtic entre el port 10125 del remot i el port 22 local (s'ha de permetre connexions a AWS per 10125):  
`ssh -N -f -i tunel.pem ec2-user@35.175.200.4 -L 10125:35.175.200.4:4444`\
`nc localhost 10125`  
El client ara s'ha de connectar al port 10125 del local
`netcat localhost 10125`\
Tornem a aplicar sniffer sobre el port 22 (sobre 4444 no hi ha cap connexió):  
`tcpdump -Aq -i eth0 tcp port 22`  
... però els missatges sortiran encriptats.

#### Repte 2. Evitar sniffing de proxy sobre les peticions web de client (túnel local dinàmic)
Comprovació  
	Arrenca dnshost de proxy i, mentre es fan peticions a diferents dominis des de client amb curl i ping, observa'ls a proxy:  
	`dnshost eth0 -l 3`  
	Descarrega la clau privada *tunel.pem* del servidor remot **i dona-li permisos 400**
	Crea un túnel local dinàmic adient per poder fer peticions http:  
	`ssh -i tunel.pem -D 9090 -f -C -q -N ec2-user@35.175.200.4`  
	Comprova el nou port local 9090 en estat listen  
	`ss -ntulp`  
	Fes servir curl amb l'opció socks i comprova que el dnstop del proxy ja no és capaç de veure l'adreça demanada:  
	`curl --socks5-hostname localhost:9090 www.google.jp`\
	De nou el proxy no veurà les peticions per dnstop, donat que les realitza la màquina AWS. Si sniffem el port 80 amb tcpdump no hi ha tràfic. Tot passa pel port 22... encriptat.

#### Repte 3. Obrir a internet un determinat port d'una màquina dins una xarxa NAT, i sense possibilitat de modificar proxy (túnel invers)
Arrenquem el servidor web python al client (a la carpeta on fem això hem de tenir un index.html):  
`python3 -m http.server 8000`

Obrim el túnel invers (atenció obrir el port 8080 a AWS):  
`ssh -fN -R 0.0.0.0:8080:localhost:8000 -v -i tunel.pem ec2-user@35.175.200.4`\
o també  
`autossh -M 0 -N -R 0.0.0.0:8080:localhost:8000 ec2-user@35.175.200.4 -v -i tunel.pem`  
comprovacions a AWS:\
`iptables -L -n`

`lsof -i :8080`

`netstat -natlp`

`http://ec2-35-175-200-4.compute-1.amazonaws.com:8080/`

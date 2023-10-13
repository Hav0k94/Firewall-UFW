# Firewall UFW
## Commandes lancés pour configurer UFW sur VPS/Serveur Debian Baded

### Installation et règles par défaut

Installe UFW | Refuse les connexions entrantes par défaut | Accepte les connexions sortantes par défaut

```
sudo apt install ufw rsyslog -y
sudo ufw default deny incoming
sudo ufw default allow outgoing
```
### UFW & Docker 

Petit tuto inspirer de ce problème pour faire cohabiter UFW & Docker : https://stackoverflow.com/questions/30383845/what-is-the-best-practice-of-docker-ufw-under-ubuntu

A ajouter dans /etc/ufw/after.rules :

```
vim /etc/ufw/after.rules

#### BEGIN UFW AND DOCKER
*filter
:ufw-user-forward - [0:0]
:DOCKER-USER - [0:0]
-A DOCKER-USER -j RETURN -s 10.0.0.0/8
-A DOCKER-USER -j RETURN -s 172.16.0.0/12
-A DOCKER-USER -j RETURN -s 192.168.0.0/16

-A DOCKER-USER -j ufw-user-forward

-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 192.168.0.0/16
-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 10.0.0.0/8
-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 172.16.0.0/12
-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 192.168.0.0/16
-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 10.0.0.0/8
-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 172.16.0.0/12

-A DOCKER-USER -j RETURN
COMMIT
# END UFW AND DOCKER
```
Après cette modification il faut reload UFW
```
sudo ufw reload
```

### Configurer ses règles 
#### SSH
```
sudo ufw allow proto tcp from $IP_SOURCE to any port $PORT_SSH
```
$IP_SOURCE = IP qui doit accéder au service \
$PORT_SSH = Port utilisé par SSH (22 par défaut, ou autre si conf modifié) 

#### Portainer
```
sudo ufw route allow proto tcp from $IP_SOURCE to $IP_PORTAINER port $PORT_PORTAINER
```
$IP_SOURCE = IP qui doit accéder au service \
$IP_PORTAINER = IP utilisé par le docker portainer \
$PORT_PORTAINER = Port utilisé par Portainer (⚠️ Il s'agit du port utilisé par le conteneur et non celui publié) 

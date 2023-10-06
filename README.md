# Firewall UFW
## Commandes lancé pour configurer UFW sur VPS/Serveur Debian Baded

Installe UFW | Refuse les connexions entrantes par défaut | Accepte les connexions sortantes par défaut

```shell
sudo apt install ufw rsyslog -y
sudo ufw default deny incoming
sudo ufw default allow outgoing
```
## UFW & Docker 

Petit tuto inspirer de ce problème pour faire cohabiter UFW & Docker : https://stackoverflow.com/questions/30383845/what-is-the-best-practice-of-docker-ufw-under-ubuntu

A ajouter dans /etc/ufw/after.rules :

```shell
vim /etc/ufw/adter.rules

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
## Configurer ses règles 
### SSH
```shell
sudo ufw allow from $IP_SOURCE to any port $PORT_SSH
```
### Portainer
```shell
sudo ufw route allow from $IP_SOURCE to $IP_PORTAINER port $PORT_PORTAINER
```

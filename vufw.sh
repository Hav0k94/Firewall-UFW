#!/bin/bash

# Vérifier si l'utilisateur exécute le script en tant que superutilisateur (root)
if [ "$EUID" -ne 0 ]; then
  echo "Ce script doit être exécuté en tant que superutilisateur (root)."
  exit 1
fi

# Check si UFW est installé et si il ne l'est pas => l'installer

if ! command -v ufw &>/dev/null; then
    read -p "UFW n'est pas installé. Voulez-vous l'installer maintenant ? (y/n) " install_ufw
    if [ "$install_ufw" == "y" ] || [ "$install_ufw" == "Y" ]; then
        sudo apt update
        sudo apt install ufw rsyslog
        echo "UFW a été installé."
        # Vérifier la politique par défaut pour les règles entrantes (incoming)
        ufw_incoming_policy=$(ufw status | grep -i "Default: incoming (")
        if [ -z "$ufw_incoming_policy" ]; then
            read -p "La politique par défaut pour les règles entrantes n'est pas configurée. Voulez-vous la définir ? (y/n) " set_incoming_policy
            if [ "$set_incoming_policy" == "y" ] || [ "$set_incoming_policy" == "Y" ]; then
                read -p "Entrez la politique par défaut pour les règles entrantes (allow/deny/reject) : " incoming_policy
                ufw default $incoming_policy incoming
                echo "La politique par défaut pour les règles entrantes a été définie sur '$incoming_policy'."
            else
                echo "La politique par défaut pour les règles entrantes n'est pas configurée. Le script ne peut pas continuer sans la définir. Abandon."
                exit 1
            fi
        fi
        # Vérifier la politique par défaut pour les règles sortantes (outgoing)
        ufw_outgoing_policy=$(ufw status | grep -i "Default: outgoing (")
        if [ -z "$ufw_outgoing_policy" ]; then
            read -p "La politique par défaut pour les règles sortantes n'est pas configurée. Voulez-vous la définir ? (y/n) " set_outgoing_policy
            if [ "$set_outgoing_policy" == "y" ] || [ "$set_outgoing_policy" == "Y" ]; then
                read -p "Entrez la politique par défaut pour les règles sortantes (allow/deny/reject) : " outgoing_policy
                ufw default $outgoing_policy outgoing  
                echo "La politique par défaut pour les règles sortantes a été définie sur '$outgoing_policy'."
            else
                echo "La politique par défaut pour les règles sortantes n'est pas configurée. Le script ne peut pas continuer sans la définir. Abandon."
                exit 1
            fi
        fi
    else
        echo "UFW n'est pas installé. Le script ne peut pas continuer sans UFW. Abandon."
        exit 1
    fi
fi

# Le nom du fichier où vous voulez sauvegarder les règles UFW
ufw_rules_file="ufw_custom_rules.txt"

# Vérification si le fichier existe pour sauvegarder les commandes
if [ -f "ufw_custom_rules.txt" ];then
    echo "Le fichier $ufw_rules_file existe, pour sauvegarder les commande UFW."
else
    while [ ! -f "$ufw_rules_file" ]; do
        echo "Le fichier $ufw_rules_file n'existe pas."
        read -p "Voulez-vous le créer ? (y/n) " create_file
        if [ "$create_file" == "y" ] || [ "$create_file" == "Y" ]; then
            touch "$ufw_rules_file"
            echo "Le fichier $ufw_rules_file a été créé."
        else
            echo "Le fichier n'a pas été créé."
            exit 1 # Quitte le script
        fi
    done
fi

# Demander le nombre d'adresses IP sources à configurer
read -p "Combien d'adresses IP sources voulez-vous configurer ? " num_ips

# Parcourir chaque adresse IP source
for ((i=1; i<=num_ips; i++))
do
    read -p "La règle doit-elle être ajoutée pour un conteneur ? (y/n) " ufw_docker
        if [ "$ufw_docker" == "y" ] || [ "$ufw_docker" == "Y" ]; then
            # Demander l'adresse IP source autorisée
            read -p "Saisissez l'adresse IP source #$i : " source_ip_for_docker

            # Demande l'adresse IP du conteneur
            read -p "Saisissez l'adresse IP du conteneur : " ip_docker

            # Demande le port utilisé par le conteneur
            read -p "Quels ports devraient être autorisés pour cette adresse IP ? (séparés par des virgules) (/!\ Attention il s'agit du port du conteneur et non celui exposé) " allowed_ports_for_docker
            
            # Ajoute la règle
            ufw route allow proto tcp from $source_ip_for_docker to $ip_docker port $allowed_ports_for_docker
           
            # Ecris la règle dans un fichier
            echo "ufw route allow proto tcp from $source_ip_for_docker to $ip_docker port $allowed_ports_for_docker" >> $ufw_rules_file
            
            echo "La règle UFW pour l'adresse IP $source_ip_for_docker sur les ports $allowed_ports_for_docker a été configurée."
        
        elif [ "$ufw_docker" == "n" ] || [ "$ufw_docker" == "N" ]; then
            read -p "Saisissez l'adresse IP source #$i : " source_ip

            # Demander les ports autorisés pour cette adresse IP
            read -p "Quels ports devraient être autorisés pour cette adresse IP ? (séparés par des virgules) " allowed_ports

            # Créer la règle UFW pour l'adresse IP source
            ufw allow from $source_ip to any port $allowed_ports

            # Ajouter la règle au fichier
            echo "ufw allow from $source_ip to any port $allowed_ports" >> $ufw_rules_file

            echo "La règle UFW pour l'adresse IP $source_ip sur les ports $allowed_ports a été configurée."
        else 
            echo "Vous devez répondre par (Y)es ou (N)o "
            exit 1 # Quitte le script
        fi
done

# Activer UFW si ce n'est pas déjà fait
ufw_status=$(ufw status | grep -i "Status: active")
if [ -z "$ufw_status" ]; then
    read -p "UFW n'est pas actif. Voulez-vous l'activer maintenant ? (y/n) " enable_ufw
    if [ "$enable_ufw" == "y" ] || [ "$enable_ufw" == "Y" ]; then
        ufw enable
        echo "UFW a été activé."
    fi
fi

# Montrer les règles UFW configurées
ufw status

echo "Configuration terminée. Les règles de firewall UFW ont été mises à jour en fonction des adresses IP sources et des ports que vous avez spécifiés."

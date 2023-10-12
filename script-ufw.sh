#!/bin/bash

# Le nom du fichier où vous voulez sauvegarder les règles UFW
ufw_rules_file="ufw_custom_rules.txt"

# Demander le nombre d'adresses IP sources à configurer
read -p "Combien d'adresses IP sources voulez-vous configurer ? " num_ips

# Parcourir chaque adresse IP source
for ((i=1; i<=num_ips; i++))
do
    read -p "Saisissez l'adresse IP source #$i : " source_ip

    # Demander les ports autorisés pour cette adresse IP
    read -p "Quels ports devraient être autorisés pour cette adresse IP ? (séparés par des virgules) " allowed_ports

    # Créer la règle UFW pour l'adresse IP source
    ufw allow from $source_ip to any port $allowed_ports

    # Ajouter la règle au fichier
    echo "ufw allow from $source_ip to any port $allowed_ports" >> $ufw_rules_file

    echo "La règle UFW pour l'adresse IP $source_ip sur les ports $allowed_ports a été configurée."
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

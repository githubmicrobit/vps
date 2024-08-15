#!/bin/bash

# Solicitar la IP de la VM
read -p "Introduce la IP de la VM: " vm_ip

echo "Recuerda que el último octeto de la IP del servidor padre debe ser 254."

# Solicitar la IP del servidor padre
read -p "Introduce la IP del servidor padre: " parent_ip

# Configuración de la red estática en /etc/network/interfaces
cat <<EOL >/etc/network/interfaces
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo ens18
iface lo inet loopback

allow-hotplug ens18
iface ens18 inet static
    address $vm_ip    # IP de la VM
    netmask 255.255.255.255  # Máscara
    broadcast $vm_ip  # Broadcast de la VM
    gateway $parent_ip    # IP del servidor padre

dns-nameservers 127.0.0.1 8.8.8.8 8.8.4.4  # DNS
EOL

# Reiniciar la interfaz de red para aplicar los cambios
ifdown ens18 && ifup ens18

echo "Configuración de red estática completada con éxito."

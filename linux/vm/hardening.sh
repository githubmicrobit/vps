#!/bin/bash

# Antes de iniciar, confirmar que ya se ha configurado una contraseña segura para el usuario root
echo "Por favor, asegúrese de haber configurado una contraseña segura para el usuario root antes de continuar."
echo "Si aún no ha configurado una contraseña segura, por favor hágalo antes de continuar."
echo "Recuerda el manejo de contraseña recomendado por la empresa."
echo ""
echo "¿Desea continuar con el hardening de la máquina? (y/n): "
read continue_hardening
continue_hardening=$(echo $continue_hardening | tr '[:lower:]' '[:upper:]')

if [ "$continue_hardening" != "Y" ]; then
    echo "Hardening cancelado."
    exit 0
fi


echo "Iniciando hardening de la máquina..."

# Habilitar la salida inmediata ante errores
set -e


# Agregar servidores DNS para la resolución de nombres de dominio
echo "Configurando servidores DNS..."
echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" > /etc/resolv.conf

# Actualización de definiciones y repositorios
echo "Actualizando repositorios y paquetes..."
apt-get update && apt-get upgrade -y


# --------------------------------------------------------------------------------


# Función para manejar errores y continuar
function install_package() {
    package=$1
    if ! apt-get -y install "$package"; then
        echo "Error instalando $package. Continuando con el siguiente paquete."
    fi
}

# Instalación de paquetes de uso cotidiano
echo "Instalando paquetes de uso cotidiano..."
packages=(
    htop ufw nmon mtr bmon rkhunter nmap rsync whois ncdu sysstat vim nload curl unzip vim-nox byobu btop ufw speedtest-cli btop wget nmap openssh-server 
)
for package in "${packages[@]}"; do
    install_package "$package"
done


# --------------------------------------------------------------------------------

# Preguntar el hostname de la máquina
echo "Introduce el hostname de la máquina: "
read hostname

# Modificar el hostname
echo "Modificando el hostname..."
hostnamectl set-hostname $hostname
echo $hostname > /etc/hostname

# --------------------------------------------------------------------------------

# Preguntar si desea instalar Tailscale
echo "¿Desea instalar Tailscale? (y/n): "
read install_tailscale
install_tailscale=$(echo $install_tailscale | tr '[:lower:]' '[:upper:]')

if [ "$install_tailscale" == "Y" ]; then
    echo "Instalando Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
fi


# --------------------------------------------------------------------------------

# Preguntar si desea configurar el firewall UFW
echo "¿Desea configurar el firewall UFW? (y/n): "
read configure_ufw
configure_ufw=$(echo $configure_ufw | tr '[:lower:]' '[:upper:]')

if [ "$configure_ufw" == "Y" ]; then
    echo "Configurando UFW..."
    ufw reset --force
    ufw allow from 198.27.126.229 comment 'VPN D'
    ufw allow from 107.173.154.26 comment 'dan-vpn'
    ufw allow from 141.95.75.216 comment 'nieto-vpn'
    ufw allow from 217.182.140.17 comment 'isauro-vpn'
    ufw allow from 141.95.47.34 to any port 54322 comment 'b.omv'
    ufw allow proto tcp from 158.69.72.147 to any port 9000:9999 comment 'Argos'
    ufw allow proto tcp from any to any port 54322,8006 comment 'Admin ports'
    ufw --force enable

    echo "Configuración de UFW completada con éxito."
    
    # Preguntar si desea habilitar el firewall UFW para HTTP y HTTPS
    echo "¿Desea habilitar el firewall UFW para HTTP y HTTPS? (y/n): "
    read enable_http_https
    enable_http_https=$(echo $enable_http_https | tr '[:lower:]' '[:upper:]')

    if [ "$enable_http_https" == "Y" ]; then
        echo "Habilitando UFW para HTTP y HTTPS..."
        ufw allow 80
        ufw allow 443
        echo "UFW habilitado para HTTP y HTTPS."
    fi

fi


# --------------------------------------------------------------------------------

# Modificar la configuración de UFW
echo "Configurando UFW..."
sed -i 's/IPV6=yes/IPV6=no/' /etc/default/ufw

# Deshabilitar IPv6
echo "Deshabilitando IPv6..."
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf

# Generar y configurar locales
echo "Configurando locales..."
locale-gen en_US.UTF-8
dpkg-reconfigure locales

# Modificar el archivo /root/.bashrc
echo "Modificando /root/.bashrc..."
cat <<EOL >> /root/.bashrc

export LANG=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
alias ls='ls --color=auto'
alias dir='ls --color=auto --format=vertical'
alias vdir='ls --color=auto --format=long'
eval \`dircolors\`
alias ls='ls \$LS_OPTIONS'
LS_COLORS='no=00:fi=00:di=01;35:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:su=37;41:sg=30;43:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.flac=01;35:*.mp3=01;35:*.mpc=01;35:*.ogg=01;35:*.wav=01;35:';
PS1='\${debian_chroot:+(\$debian_chroot)}\[\033[0;37m\][\t\[\033[0;37m\]]\[\033[0;33m\][\[\033[0;36m\]\u\[\033[0;36m\]@\[\033[0;36m\]\H \[\033[1;31m\]\w\[\033[0;33m\]]\[\033[0;31m\]\[\033[0;37m\]\\$ \[\033[00m\]'
export LS_OPTIONS='--color=auto'
export CLICOLOR=1
export LSCOLORS=ExFxCxDxBxegedabagacad
export GIT_PS1_SHOWDIRTYSTATE=true
export GIT_PS1_SHOWUNTRACKEDFILES=true
export GIT_PS1_SHOWSTASHSTATE=true
export PROMPT_DIRTRIM=3
export EDITOR="vim"
export VISUAL=vi
EOL


# Deshabilitar y rehabilitar byobu para que se apliquen los cambios
echo "Reiniciando byobu..."
byobu-disable
byobu-enable

# enable root ssh login
echo "Permitiendo acceso SSH al usuario root..."
sed -i 's/PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config

# añadir linea al archivo nano /etc/ssh/sshd_config para permitir acceso root por password
echo "Permitiendo acceso SSH al usuario root por contraseña..."
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config


# Reiniciar el servicio SSH
echo "Reiniciando el servicio SSH..."
systemctl restart sshd


# Preguntar si se desea eliminar algun usuario adicional, en caso de que si intentarlo bajo un try para caso de que no exista
echo "¿Desea eliminar algún usuario adicional? (y/n): "
read delete_user
delete_user=$(echo $delete_user | tr '[:lower:]' '[:upper:]')

if [ "$delete_user" == "Y" ]; then
    echo "Introduce el nombre del usuario a eliminar: "
    read user_to_delete
    user_to_delete=$(echo $user_to_delete | tr '[:upper:]' '[:lower:]')
    if id "$user_to_delete" &>/dev/null; then
        echo "Eliminando usuario $user_to_delete..."
        userdel -r $user_to_delete
        rm -rf /home/$user_to_delete
        echo "Usuario $user_to_delete eliminado con éxito."
    else
        echo "El usuario $user_to_delete no existe."
    fi
fi


# --------------------------------------------------------------------------------

# Preguntar si desea configurar la Swap
base=1024
echo "¿Desea configurar la Swap? (y/n): "
read configure_swap
configure_swap=$(echo $configure_swap | tr '[:lower:]' '[:upper:')

if [ "$configure_swap" == "Y" ]; then
    echo "Introduce el tamaño de la Swap en GB: "
    read swap_size
    swap_size=$(($swap_size * $base))

    echo "Configurando la Swap..."
    swapon -s
    dd if=/dev/zero of=/swapfile bs=1M count=$swap_size
    chown root:root /swapfile
    chmod 0600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    swapon -s

    # echo "/swapfile none swap sw 0 0" >> /etc/fstab
    echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
    echo "Swap configurada con éxito."
fi



# Indicar al usuario que cierre las sesiones SSH
echo "Por favor, cierre todas las sesiones SSH y vuelva a ingresar para aplicar los cambios."


# Dar instrucciones para configurar el acceso por SSH mandando llave al servidor
echo "Para configurar el acceso por SSH, ejecute el siguiente comando en su máquina local:"
echo "ssh-copy-id -i ~/.ssh/id_rsa.pub root@$(curl -s ifconfig.me)"
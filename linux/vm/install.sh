

# Preguntar si desea restaurar los repositorios de debian con los default del sistema

read -p "¿Desea restaurar los repositorios de Debian con los valores por defecto? (y/n): " restore_repositories

restore_repositories=$(echo $restore_repositories | tr '[:lower:]' '[:upper:]')


# Si la respuesta es si restauramos con cat lo default y salimo de lo contrario continua para red
if [ "$restore_repositories" == "Y" ]; then
    cat /usr/share/doc/apt/examples/sources.list > /etc/apt/sources.list
    echo "Repositorios restaurados con éxito."
    exit 0
fi


# Preguntar y almacenar la version de debian instalado el valor se almacena en version_debian
read -p "Introduce la versión de Debian instalada (11, 12): " version_debian 


# url para bajar los repositorios actualizados
url="https://raw.githubusercontent.com/githubmicrobit/vps/main/linux/repositories/$version_debian"


# verificar si tiene instalado curl o wget si no lo tiene trabajaremos con python3
if [ -x "$(command -v curl)" ]; then
    echo "Se descargaran los repositorios actualizados con Curl."
    curl -o /etc/apt/sources.list $url
elif [ -x "$(command -v wget)" ]; then
    echo "Se descargaran los repositorios actualizados con Wget."
    wget -O /etc/apt/sources.list $url
else
    echo "No cuenta con curl ni wget. intentando con python3."
    python3 -c "import urllib.request; urllib.request.urlretrieve('$url', '/etc/apt/sources.list')"
fi


# preguntar si desea comenzar con el hardening de la maquina
read -p "¿Desea comenzar con el hardening de la máquina? (y/n): " hardening
hardening=$(echo $hardening | tr '[:lower:]' '[:upper:')

hardening_command= "curl -fsSL https://raw.githubusercontent.com/githubmicrobit/vps/main/linux/vm/hardening.sh | bash"

if [ "$hardening" == "Y" ]; then
    echo "Comenzando con el hardening de la máquina..."
    bash -c $hardening_command
else
    echo "Hardening cancelado."
    echo "Si desea comenzar con el hardening de la máquina en otro momento ejecute el siguiente comando:"
    echo $hardening_command
fi
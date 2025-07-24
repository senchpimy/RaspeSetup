#!/bin/bash

set -e

if [[ -z "$SUDO_USER" ]]; then
    echo "ERROR: Este script debe ser ejecutado con sudo."
    exit 1
fi
USERNAME="$SUDO_USER"
USER_HOME=$(eval echo "~$USERNAME")
SHARE_DIR="$USER_HOME/Disco"

function initial_setup() {
    echo ">>> [1/6] Realizando configuración inicial y actualizando el sistema..."
    apt-get update
    apt-get install -y curl git ufw \
        python3 python3-pip python3-dev python3-setuptools python3-venv \
        build-essential libyaml-dev libffi-dev libssl-dev \
        vsftpd
    echo "--- Configuración inicial completada."
}

function setup_firewall() {
    echo ">>> [2/6] Configurando el firewall (UFW)..."
    ufw allow ssh
    
    ufw allow 8384/tcp
    ufw allow 22000/tcp
    ufw allow 21027/udp
    
    ufw allow 5000/tcp
    
    ufw allow 8001/tcp
    
    ufw allow 21/tcp
    ufw allow 40000:50000/tcp

    ufw --force enable
    ufw reload
    echo "--- Firewall configurado y activado. Reglas aplicadas:"
    ufw status verbose
}

function setup_syncthing() {
    echo ">>> [3/6] Instalando y configurando Syncthing..."
    mkdir -p /etc/apt/keyrings
    curl -L -o /etc/apt/keyrings/syncthing-archive-keyring.gpg https://syncthing.net/release-key.gpg
    echo "deb [signed-by=/etc/apt/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable" | tee /etc/apt/sources.list.d/syncthing.list
    
    apt-get update
    apt-get install -y syncthing
    
    #TODO verificar el .service
    cat <<EOF > /etc/systemd/system/syncthing@.service
[Unit]
Description=Syncthing - Continuous File Synchronization
After=network-online.target
Wants=network-online.target

[Service]
Environment="LC_ALL=C.UTF-8"
Environment="LANG=C.UTF-8"
Type=simple
User=plof
ExecStart=/usr/bin/syncthing --gui-address=0.0.0.0:8384
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable "syncthing@$USERNAME.service"
    systemctl start "syncthing@$USERNAME.service"
    
    echo "fs.inotify.max_user_watches=204800" | tee -a /etc/sysctl.conf
    sysctl -p
    
    echo "--- Syncthing instalado y configurado."
}

function setup_octoprint() {
    echo ">>> [4/6] Instalando y configurando OctoPrint..."
    usermod -a -G tty "$USERNAME"
    usermod -a -G dialout "$USERNAME"
    
    sudo -u "$USERNAME" mkdir -p "$USER_HOME/OctoPrint"
    sudo -u "$USERNAME" python3 -m venv "$USER_HOME/OctoPrint/venv"
    
    sudo -u "$USERNAME" "$USER_HOME/OctoPrint/venv/bin/pip" install --upgrade pip wheel
    sudo -u "$USERNAME" "$USER_HOME/OctoPrint/venv/bin/pip" install octoprint
    
    cat <<EOF > /etc/systemd/system/octoprint.service
[Unit]
Description=The snappy web interface for your 3D printer
After=network-online.target
Wants=network-online.target

[Service]
Environment="LC_ALL=C.UTF-8"
Environment="LANG=C.UTF-8"
Type=exec
User=plof
ExecStart=/home/plof/OctoPrint/venv/bin/octoprint serve

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable octoprint.service
    systemctl start octoprint.service
    
    echo "--- OctoPrint instalado y configurado."
}

function setup_dufs() {
    echo ">>> [5/6] Instalando y configurando DUFS (Servidor de archivos web)..."
    sudo -u "$USERNAME" curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sudo -u "$USERNAME" sh -s -- -y
    
    sudo -u "$USERNAME" "$USER_HOME/.cargo/bin/cargo" install dufs #TODO verificar version
    
    sudo -u "$USERNAME" mkdir -p "$SHARE_DIR"
    
    #TODO verificar .service
    cat <<EOF > /etc/systemd/system/dufs.service
[Unit]
Description=DUFS - Simple HTTP File Server
After=network-online.target
Wants=network-online.target

[Service]
Environment="LC_ALL=C.UTF-8"
Environment="LANG=C.UTF-8"
Type=simple
User=plof
ExecStart=dufs /home/plof/Disco -p 8000 -A
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable dufs.service
    systemctl start dufs.service
    
    echo "--- DUFS instalado y configurado."
}

function setup_ftp() {
    echo ">>> Configurando vsftpd con una jaula chroot segura..."

    apt-get install -y vsftpd

    groupadd --force sftp_users
    usermod -aG sftp_users "$USERNAME"

    mkdir -p "/srv/sftp/$USERNAME"
    chown root:root "/srv/sftp/$USERNAME"
    chmod 755 "/srv/sftp/$USERNAME"
    
    mkdir -p "/srv/sftp/$USERNAME/Disco"

    sudo -u "$USERNAME" mkdir -p "$SHARE_DIR"

    mount --bind "$SHARE_DIR" "/srv/sftp/$USERNAME/Disco"

    cp /etc/vsftpd.conf /etc/vsftpd.conf.bak

    cat <<EOF > /etc/vsftpd.conf
listen=NO
listen_ipv6=YES
anonymous_enable=NO
local_enable=YES
write_enable=YES
chroot_local_user=YES
pam_service_name=vsftpd
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=50000
allow_writeable_chroot=YES
user_sub_token=$USER
local_root=/home/$USER/Disco
EOF

    systemctl restart vsftpd
    systemctl enable vsftpd
    echo "--- vsftpd instalado y configurado con jaula chroot en /srv/sftp/$USERNAME."
}

function setup_oled(){
    cd OledFanButtonRasp/

    echo "Installing necessary system tools (i2c-tools, git, python3-pip)..."
    sudo apt-get update
    sudo apt-get install -y i2c-tools git python3-pip

    echo "Installing Python dependencies with pip..."
    PACKAGES="board busio adafruit-blinka pillow adafruit-circuitpython-ssd1306 RPi.GPIO subprocess.run"
    sudo pip3 install --break-system-packages $PACKAGES

    echo "Enabling I2C interface via raspi-config..."
    sudo raspi-config nonint do_i2c 0
    sudo raspi-config nonint do_ssh 0

    echo "Verifying I2C devices. Deberías ver una dirección como '3c' en la tabla."
    sudo i2cdetect -y 1
    sudo cp ofb.service /etc/systemd/system/ofb.service

    cd ..
}


function main() {
    echo "#################################################"
    echo "Iniciando configuración del servidor..."
    echo "Usuario de ejecución: $USERNAME"
    echo "Directorio compartido: $SHARE_DIR"
    echo "#################################################"
    
    initial_setup
    setup_firewall
    setup_syncthing
    setup_octoprint
    setup_dufs
    setup_ftp
    setup_oled
}

main

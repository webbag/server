#!/bin/bash

# Zmienna z nazwą użytkownika do utworzenia
NEW_USER="kris"
SSH_PORT=2222

# Funkcja do sprawdzania czy komenda została wykonana poprawnie
function check_success {
    if [ $? -ne 0 ]; then
        echo "Wystąpił błąd. Sprawdź logi i spróbuj ponownie."
        exit 1
    fi
}

# 1. Aktualizacja systemu
sudo apt update && sudo apt upgrade -y
check_success

# 2. Tworzenie nowego użytkownika
sudo adduser --disabled-password --gecos "" $NEW_USER
check_success

# Dodanie użytkownika do grupy sudo
sudo usermod -aG sudo $NEW_USER
check_success

# 3. Konfiguracja uwierzytelniania kluczem SSH
sudo mkdir -p /home/$NEW_USER/.ssh
if [ -f ~/.ssh/authorized_keys ]; then
    sudo cp ~/.ssh/authorized_keys /home/$NEW_USER/.ssh/
else
    echo "Brak pliku authorized_keys w katalogu domowym. Uwierzytelnianie kluczem SSH nie zostało skonfigurowane."
fi
sudo chown -R $NEW_USER:$NEW_USER /home/$NEW_USER/.ssh
sudo chmod 700 /home/$NEW_USER/.ssh
sudo chmod 600 /home/$NEW_USER/.ssh/authorized_keys

# 4. Wyłączenie logowania root przez SSH
sudo sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
check_success

# 5. Zmiana domyślnego portu SSH
sudo sed -i "s/^#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config
check_success

# Dodanie nowego portu do zapory UFW
sudo ufw allow $SSH_PORT/tcp
check_success

# 6. Włączenie UFW i dodanie podstawowych reguł
sudo ufw allow OpenSSH
sudo ufw --force enable
check_success

# 7. Instalacja i konfiguracja Fail2Ban
sudo apt install fail2ban -y
check_success

# Start i włączenie fail2ban
sudo systemctl enable --now fail2ban
check_success

# 8. Instalacja logwatch
sudo apt install logwatch -y
check_success

# 9. Instalacja unattended-upgrades
sudo apt install unattended-upgrades -y
check_success

# Włączenie unattended-upgrades
echo -e "Unattended-Upgrade::Allowed-Origins {
        \"\${distro_id}:\${distro_codename}-security\";
};" | sudo tee /etc/apt/apt.conf.d/50unattended-upgrades

# 10. Instalacja ClamAV
sudo apt install clamav -y
check_success

# Aktualizacja definicji wirusów
sudo freshclam
check_success

# 11. Wyłączenie logowania hasłem przez SSH
sudo sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
check_success

# Restart usługi SSH w celu zastosowania zmian
sudo systemctl restart ssh
check_success

# 12. Instalacja i konfiguracja OpenVPN
sudo apt install openvpn easy-rsa -y
check_success

# Tworzenie katalogu dla Easy-RSA
easy_rsa_dir="/etc/openvpn/easy-rsa"
sudo make-cadir $easy_rsa_dir
check_success

# Konfiguracja Easy-RSA i generowanie certyfikatów
cd $easy_rsa_dir
source vars
./clean-all
./build-ca --batch
./build-key-server --batch server
./build-dh
check_success

# Kopiowanie certyfikatów do katalogu OpenVPN
sudo cp $easy_rsa_dir/keys/{server.crt,server.key,ca.crt,dh2048.pem} /etc/openvpn/

# Generowanie certyfikatu i klucza dla klienta
./build-key --batch klient
check_success

# Kopiowanie certyfikatów klienta do katalogu dostępnego dla pobrania
sudo mkdir -p /etc/openvpn/clients
sudo cp $easy_rsa_dir/keys/{klient.crt,klient.key,ca.crt} /etc/openvpn/clients/
check_success

# Tworzenie pliku konfiguracyjnego OpenVPN
sudo bash -c 'cat > /etc/openvpn/server.conf <<EOF
port 1194
dev tun
proto udp
ca ca.crt
cert server.crt
key server.key
dh dh2048.pem
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
keepalive 10 120
comp-lzo
persist-key
persist-tun
status openvpn-status.log
log-append /var/log/openvpn.log
verb 3
EOF'

# Włączenie i uruchomienie OpenVPN
sudo systemctl enable openvpn@server
sudo systemctl start openvpn@server
check_success

# Podsumowanie
echo "Konfiguracja bezpieczeństwa zakończona. Zaloguj się za pomocą nowego użytkownika: $NEW_USER na porcie SSH: $SSH_PORT"
echo "OpenVPN został zainstalowany i uruchomiony. Certyfikaty klienta dostępne w /etc/openvpn/clients. Skonfiguruj klienta VPN, aby połączyć się z serwerem."

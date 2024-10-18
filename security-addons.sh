#!/bin/bash

## Security Enhancements for Debian Server - security.sh Addons

# Funkcja do sprawdzania czy komenda została wykonana poprawnie
function check_success {
    if [ $? -ne 0 ]; then
        echo "Wystąpił błąd. Sprawdź logi i spróbuj ponownie."
        exit 1
    fi
}

# 1. Limitowanie Dostępu na Podstawie Adresu IP dla SSH
echo "Ograniczanie dostępu SSH do wybranych użytkowników..."
read -p "Podaj adres IP dozwolony dla SSH: " ALLOWED_IP
if [[ -z "$ALLOWED_IP" ]]; then
    echo "Adres IP nie może być pusty."
    exit 1
fi
sudo bash -c "echo 'AllowUsers *@$ALLOWED_IP' >> /etc/ssh/sshd_config"
check_success
sudo systemctl restart ssh
check_success

# 2. Konfiguracja Fail2Ban dla SSH
echo "Konfiguracja Fail2Ban dla SSH..."
if [[ -z "$SSH_PORT" ]]; then
    echo "Port SSH nie został ustawiony. Ustaw domyślny port (22)."
    SSH_PORT=22
fi
cat <<EOL | sudo tee /etc/fail2ban/jail.local
[sshd]
enabled = true
port = $SSH_PORT
logpath = /var/log/auth.log
maxretry = 3
EOL
check_success
sudo systemctl restart fail2ban
check_success

# 3. Instalacja Google Authenticator dla 2FA
echo "Instalacja Google Authenticator..."
sudo apt install libpam-google-authenticator -y
check_success
sudo -u $(logname) google-authenticator -t -d -f -r 3 -R 30 -W
check_success
sudo sed -i '/@include common-auth/a auth required pam_google_authenticator.so' /etc/pam.d/sshd
sudo sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart ssh
check_success

# 4. Dodatkowe Reguły Firewalla - Ograniczenia Limitu Połączeń
echo "Dodawanie limitu połączeń do reguł UFW..."
sudo ufw limit $SSH_PORT/tcp
check_success

# 5. Monitorowanie Skanowania Portów z PSAD
echo "Instalacja PSAD do monitorowania skanowania portów..."
sudo apt install psad -y
check_success
sudo psad -A
check_success

# Konfiguracja PSAD do automatycznego blokowania adresów IP podczas skanowania
echo "Konfiguracja PSAD do automatycznego blokowania adresów IP podczas skanowania..."
sudo sed -i 's/^AUTO_IDS.*/AUTO_IDS="Y";/g' /etc/psad/psad.conf
sudo sed -i 's/^AUTO_IPT_THRESHOLD_LEVEL.*/AUTO_IPT_THRESHOLD_LEVEL="1";/g' /etc/psad/psad.conf
sudo systemctl restart psad
check_success

# 6. Zmiana Uprawnień Do Krytycznych Plików Systemowych
echo "Zmiana uprawnień do krytycznych plików konfiguracyjnych..."
sudo chmod 600 /etc/ssh/sshd_config
sudo chmod 600 /etc/fail2ban/jail.local
check_success

# 7. Usuwanie Nieużywanych Usług
echo "Usuwanie nieużywanych usług..."
sudo apt purge apache2 -y
check_success
sudo apt purge xinetd -y
check_success

# 8. Wyłączenie IPv6
echo "Wyłączanie IPv6..."
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
check_success
sudo bash -c "echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf"
check_success

# 9. Regularne Skrypty do Aktualizacji
echo "Dodawanie cotygodniowych aktualizacji do crona..."
echo "0 4 * * 1 root apt update && apt upgrade -y" | sudo tee /etc/cron.d/weekly-upgrades
check_success

# 10. Konfiguracja ulimit dla Zasobów Systemowych
if [[ -z "$NEW_USER" ]]; then
    echo "Zmiennej NEW_USER nie ustawiono. Ustaw nowego użytkownika."
    exit 1
fi
echo "Konfiguracja ulimit dla użytkowników..."
echo "$NEW_USER hard nofile 5000" | sudo tee -a /etc/security/limits.conf
check_success

# 11. Centralizacja Logów
echo "Skonfiguruj centralizację logów na zewnętrzny serwer, jeśli jest dostępny (opcja manualna)."

# 12. Wyłączenie USB Storage
echo "Wyłączanie obsługi pamięci USB..."
echo "blacklist usb-storage" | sudo tee /etc/modprobe.d/usb-storage.conf
check_success

# Restartowanie usług po konfiguracji
sudo systemctl restart ssh
sudo systemctl restart fail2ban
sudo systemctl restart psad

# Podsumowanie
echo "Dodatkowe zabezpieczenia zostały zastosowane. Serwer jest teraz lepiej chroniony przed potencjalnymi zagrożeniami."

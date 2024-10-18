#!/bin/bash

## Debian Security Configuration

# Funkcja do sprawdzania czy komenda została wykonana poprawnie
function check_success {
    if [ $? -ne 0 ]; then
        echo "Wystąpił błąd. Sprawdź logi i spróbuj ponownie."
        exit 1
    fi
}

# Sprawdzenie, czy podano odpowiednią liczbę argumentów lub --help
if [[ "$1" == "--help" ]]; then
    echo "Użycie:"
    echo "$0 <nazwa_użytkownika> <port_ssh>"
    echo "Przykład: $0 webbag 2222"
    exit 0
elif [ $# -ne 2 ]; then
    echo "Błędne użycie. Musisz podać nazwę użytkownika oraz port SSH. Użyj --help, aby uzyskać informacje na temat poprawnego użycia."
    exit 1
fi

# Zmienne z nazwą użytkownika do utworzenia i portem SSH
NEW_USER="$1"
SSH_PORT="$2"

# 1. Aktualizacja systemu
sudo apt update && sudo apt upgrade -y
check_success

# 2. Tworzenie nowego użytkownika
if id "$NEW_USER" &>/dev/null; then
    echo "Użytkownik $NEW_USER już istnieje."
else
    sudo adduser --disabled-password --gecos "" $NEW_USER
    check_success
    # Dodanie użytkownika do grupy sudo
    sudo usermod -aG sudo $NEW_USER
    check_success
fi

# 3. Konfiguracja uwierzytelniania kluczem SSH
sudo mkdir -p /home/$NEW_USER/.ssh
if [ -f ~/.ssh/authorized_keys ]; then
    sudo cp ~/.ssh/authorized_keys /home/$NEW_USER/.ssh/
    sudo chown $NEW_USER:$NEW_USER /home/$NEW_USER/.ssh/authorized_keys
    sudo chmod 600 /home/$NEW_USER/.ssh/authorized_keys
else
    echo "Brak pliku authorized_keys w katalogu domowym. Uwierzytelnianie kluczem SSH nie zostało skonfigurowane."
fi
sudo chown -R $NEW_USER:$NEW_USER /home/$NEW_USER/.ssh
sudo chmod 700 /home/$NEW_USER/.ssh

# 4. Wyłączenie logowania root przez SSH
sudo sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
check_success

# 5. Zmiana domyślnego portu SSH
if ! grep -q "^Port $SSH_PORT" /etc/ssh/sshd_config; then
    sudo sed -i "s/^#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config
    check_success
fi

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

# Podsumowanie konfiguracji bezpieczeństwa
echo "Konfiguracja bezpieczeństwa zakończona. Zaloguj się za pomocą nowego użytkownika: $NEW_USER na porcie SSH: $SSH_PORT"

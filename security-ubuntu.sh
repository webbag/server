#!/bin/bash
# Skrypt konfiguracyjny dla Ubuntu 24 - aktualizacja, zmiana portu SSH, instalacja Fail2ban i podstawowa konfiguracja

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
elif [[ $# -lt 2 ]]; then
    echo "Błędne użycie. Parametry <nazwa_użytkownika> i <port_ssh> są wymagane. Użyj --help, aby uzyskać informacje na temat poprawnego użycia."
    exit 1
fi

# Zmienne z nazwą użytkownika do utworzenia i portem SSH
NEW_USER="$1"
NEW_SSH_PORT="$2"
# Zmienne z nazwą użytkownika do utworzenia i portem SSH
NEW_USER="$1"
NEW_SSH_PORT="$2"

# Aktualizacja systemu operacyjnego
echo "Aktualizacja systemu operacyjnego..."
sudo apt update && sudo apt upgrade -y
check_success

# Sprawdzanie, czy podany port SSH jest używany
echo "Sprawdzanie, czy port $NEW_SSH_PORT jest używany..."
if sudo ss -tuln | grep -q ":$NEW_SSH_PORT"; then
  echo "Port $NEW_SSH_PORT jest już zajęty. Skrypt zakończony."
  exit 1
else
  echo "Port $NEW_SSH_PORT jest wolny. Używanie tego portu dla SSH."
fi

# Edycja pliku konfiguracyjnego ssh.socket dla systemu Ubuntu 23.04 i nowszych wersji (Socket)
UBUNTU_VERSION=$(lsb_release -rs)
if dpkg --compare-versions "$UBUNTU_VERSION" "ge" "23.04"; then
  echo "Wykryto wersję Ubuntu >= 23.04, aktualizacja pliku ssh.socket..."
  if sudo grep -q "^ListenStream=22" /lib/systemd/system/ssh.socket; then
    sudo sed -i "s/^ListenStream=22/ListenStream=$NEW_SSH_PORT/" /lib/systemd/system/ssh.socket
    check_success
  else
    echo "ListenStream=22 nie został znaleziony w pliku ssh.socket, dodawanie nowej linii..."
    echo "ListenStream=$NEW_SSH_PORT" | sudo tee -a /lib/systemd/system/ssh.socket > /dev/null
    check_success
  fi
  sudo systemctl daemon-reload
  check_success
  sudo systemctl restart ssh.socket
  check_success
else
  # Zmiana domyślnego portu SSH
  echo "Zmiana domyślnego portu SSH na $NEW_SSH_PORT..."
  if sudo grep -q "^#Port 22" /etc/ssh/sshd_config; then
    sudo sed -i "s/^#Port 22/Port $NEW_SSH_PORT/" /etc/ssh/sshd_config
    check_success
  elif sudo grep -q "^Port 22" /etc/ssh/sshd_config; then
    sudo sed -i "s/^Port 22/Port $NEW_SSH_PORT/" /etc/ssh/sshd_config
    check_success
  else
    echo "Port 22 nie został znaleziony w pliku konfiguracyjnym, dodawanie nowej linii..."
    echo "Port $NEW_SSH_PORT" | sudo tee -a /etc/ssh/sshd_config > /dev/null
    check_success
  fi
  echo "Restart usługi SSH..."
  sudo systemctl restart ssh.socket
  check_success
fi

# Utworzenie użytkownika z ograniczonymi prawami
if id "$NEW_USER" &>/dev/null; then
    echo "Użytkownik $NEW_USER już istnieje."
else
    echo "Tworzenie nowego użytkownika: $NEW_USER ... bez hasła"
    sudo adduser --disabled-password --gecos "" $NEW_USER
    sudo passwd -d $NEW_USER
    check_success
    # Dodanie użytkownika do grupy sudo
    sudo usermod -aG sudo $NEW_USER
    check_success

    # Konfiguracja uwierzytelniania kluczem SSH
    sudo mkdir -p /home/$NEW_USER/.ssh
    check_success
    if [ -f /home/$SUDO_USER/.ssh/authorized_keys ]; then
        sudo cp /home/$SUDO_USER/.ssh/authorized_keys /home/$NEW_USER/.ssh/
        check_success
        sudo chown $NEW_USER:$NEW_USER /home/$NEW_USER/.ssh/authorized_keys
        check_success
        sudo chmod 600 /home/$NEW_USER/.ssh/authorized_keys
        check_success
    else
        echo "Brak pliku authorized_keys w katalogu domowym. Uwierzytelnianie kluczem SSH nie zostało skonfigurowane."
    fi
    sudo chown -R $NEW_USER:$NEW_USER /home/$NEW_USER/.ssh
    check_success
    sudo chmod 700 /home/$NEW_USER/.ssh
    check_success
fi

# Wyłączenie logowania root przez SSH
sudo sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
check_success

# Instalacja Fail2ban
echo "Instalacja Fail2ban..."
sudo apt install fail2ban -y
check_success

# Konfiguracja Fail2ban
echo "Konfiguracja Fail2ban..."
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
check_success
sudo sed -i "s/^enabled = false/enabled = true/" /etc/fail2ban/jail.local
sudo sed -i "s/^bantime  = 10m/bantime  = 30m/" /etc/fail2ban/jail.local
sudo sed -i "s/^maxretry = 5/maxretry = 3/" /etc/fail2ban/jail.local


# Restartowanie usługi Fail2ban
echo "Restart usługi Fail2ban..."
sudo systemctl restart fail2ban
check_success

# Komunikat końcowy
echo "Skrypt zakończony. Pamiętaj, aby logować się na serwer z użyciem nowego portu SSH: ssh $NEW_USER@TwojeIP -p $NEW_SSH_PORT"

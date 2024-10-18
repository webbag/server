#!/bin/bash

# Skrypt do sprawdzania i wyłączania nieużywanych usług na serwerze VPS

# Funkcja do sprawdzania czy komenda została wykonana poprawnie
function check_success {
    if [ $? -ne 0 ]; then
        echo "Wystąpił błąd. Sprawdź logi i spróbuj ponownie."
        exit 1
    fi
}

# Lista nieużywanych usług do wyłączenia i usunięcia
SERVICES=(
    "apache2"
    "nginx"
    "lighttpd"
    "xinetd"
    "exim4"
    "postfix"
    "bluetooth"
    "avahi-daemon"
    "cups"
    "lightdm"
    "gdm3"
    "NetworkManager"
    "systemd-resolved"
    "gnome-shell"
    "alsa-utils"
    "pulseaudio"
    "bluez"
)

# Sprawdzanie i wyłączanie usług
for SERVICE in "${SERVICES[@]}"; do
    if systemctl list-units --type=service --all | grep -q $SERVICE; then
        if systemctl is-active --quiet $SERVICE; then
            echo "Wyłączanie usługi: $SERVICE"
            sudo systemctl stop $SERVICE
            check_success
        fi
        echo "Wyłączanie usługi $SERVICE z automatycznego uruchamiania..."
        sudo systemctl disable $SERVICE
        check_success
    else
        echo "Usługa $SERVICE nie istnieje lub nie jest zainstalowana."
    fi

    # Usunięcie usługi, jeśli jest zainstalowana
    if dpkg -l | grep -qw $SERVICE; then
        echo "Usuwanie pakietu: $SERVICE"
        sudo apt purge $SERVICE -y
        check_success
    else
        echo "Pakiet $SERVICE nie jest zainstalowany."
    fi
done

# Wyłączenie IPv6
echo "Wyłączanie IPv6..."
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
check_success
sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=1
check_success
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
check_success

# Usunięcie nieużywanych pakietów sieciowych
echo "Usuwanie nieużywanych pakietów sieciowych..."
NETWORK_PACKAGES=("ppp" "wvdial" "pptpd")
for PACKAGE in "${NETWORK_PACKAGES[@]}"; do
    if dpkg -l | grep -qw $PACKAGE; then
        echo "Usuwanie pakietu: $PACKAGE"
        sudo apt purge $PACKAGE -y
        check_success
    else
        echo "Pakiet $PACKAGE nie jest zainstalowany."
    fi
done

# Usunięcie zbędnych pakietów multimedialnych
echo "Usuwanie zbędnych pakietów multimedialnych..."
MULTIMEDIA_PACKAGES=("vlc" "totem" "rhythmbox" "cheese")
for PACKAGE in "${MULTIMEDIA_PACKAGES[@]}"; do
    if dpkg -l | grep -qw $PACKAGE; then
        echo "Usuwanie pakietu: $PACKAGE"
        sudo apt purge $PACKAGE -y
        check_success
    else
        echo "Pakiet $PACKAGE nie jest zainstalowany."
    fi
done

# Wyłączenie usługi CUPS dla drukarek
echo "Wyłączanie usługi CUPS (drukarki)..."
if systemctl list-units --type=service --all | grep -q cups; then
    if systemctl is-active --quiet cups; then
        sudo systemctl stop cups
        check_success
    fi
    sudo systemctl disable cups
    check_success
else
    echo "Usługa CUPS nie istnieje lub nie jest zainstalowana."
fi

# Usunięcie zbędnych środowisk graficznych
echo "Usuwanie zbędnych środowisk graficznych..."
GRAPHICAL_PACKAGES=("ubuntu-desktop" "kde-plasma-desktop" "xfce4" "mate-desktop")
for PACKAGE in "${GRAPHICAL_PACKAGES[@]}"; do
    if dpkg -l | grep -qw $PACKAGE; then
        echo "Usuwanie pakietu: $PACKAGE"
        sudo apt purge $PACKAGE -y
        check_success
    else
        echo "Pakiet $PACKAGE nie jest zainstalowany."
    fi
done

# Potwierdzenie zakończenia działania skryptu
echo "Sprawdzenie i wyłączanie nieużywanych usług oraz pakietów zakończone."

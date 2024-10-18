#!/bin/bash

## Debian OpenVPN Installation and Configuration

# Funkcja do sprawdzania czy komenda została wykonana poprawnie
function check_success {
    if [ $? -ne 0 ]; then
        echo "Wystąpił błąd. Sprawdź logi i spróbuj ponownie."
        exit 1
    fi
}

# Funkcja do instalacji i konfiguracji OpenVPN
install_openvpn() {
    # 1. Instalacja i konfiguracja OpenVPN
    sudo apt install openvpn easy-rsa -y
    check_success

    # Tworzenie katalogu dla Easy-RSA
    easy_rsa_dir="/etc/openvpn/easy-rsa"
    sudo mkdir -p $easy_rsa_dir
    sudo cp -r /usr/share/easy-rsa/* $easy_rsa_dir
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
    sudo cp $easy_rsa_dir/keys/{server.crt,server.key,ca.crt,dh.pem} /etc/openvpn/

    # Generowanie certyfikatu i klucza dla klienta początkowego
    CLIENT_NAME="klient"
    generate_client $CLIENT_NAME

    # Tworzenie pliku konfiguracyjnego OpenVPN
    sudo bash -c 'cat > /etc/openvpn/server.conf <<EOF
port 1194
dev tun
proto udp
ca ca.crt
cert server.crt
key server.key
dh dh.pem
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

    # Podsumowanie konfiguracji OpenVPN
    echo "OpenVPN został zainstalowany i uruchomiony. Certyfikaty klienta dostępne w /etc/openvpn/clients. Skonfiguruj klienta VPN, aby połączyć się z serwerem."
}

# Funkcja do dodawania nowych klientów
generate_client() {
    CLIENT_NAME=$1
    cd $easy_rsa_dir
    source vars
    ./build-key --batch $CLIENT_NAME
    check_success

    # Kopiowanie certyfikatów klienta do katalogu dostępnego dla pobrania
    sudo mkdir -p /etc/openvpn/clients
    sudo cp $easy_rsa_dir/keys/{$CLIENT_NAME.crt,$CLIENT_NAME.key,ca.crt} /etc/openvpn/clients/
    check_success

    echo "Certyfikaty dla klienta $CLIENT_NAME zostały wygenerowane i zapisane w /etc/openvpn/clients"
}

# Obsługa argumentów skryptu
if [[ "$1" == "--help" ]]; then
    echo "Użycie:"
    echo "$0 install - aby zainstalować OpenVPN"
    echo "$0 add-client <nazwa_klienta> - aby dodać nowego klienta"
    exit 0
elif [[ "$1" == "add-client" && -n "$2" ]]; then
    CLIENT_NAME="$2"
    generate_client $CLIENT_NAME
elif [[ "$1" == "install" ]]; then
    install_openvpn
else
    echo "Błędne użycie. Użyj --help, aby uzyskać informacje na temat poprawnego użycia."
    exit 1
fi

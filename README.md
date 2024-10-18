# Instalacja OpenVPN i Konfiguracja Bezpieczeństwa na Debianie

## Wstęp

Ten dokument opisuje ogólny proces instalacji i konfiguracji serwera OpenVPN oraz wzmocnienia bezpieczeństwa serwera Debian przy użyciu dwóch skryptów: `security.sh` oraz `openvpn.sh`.

- Skrypt `security.sh` służy do skonfigurowania podstawowych aspektów bezpieczeństwa serwera, takich jak zmiana portu SSH, wyłączenie logowania root, ustawienie zapory ogniowej i instalacja dodatkowych narzędzi zabezpieczających.
- Skrypt `openvpn.sh` przeprowadza instalację i konfigurację serwera OpenVPN, aby umożliwić bezpieczne połączenia VPN.

## Wymagania

- Debian 10 lub nowszy
- Uprawnienia root lub dostęp do `sudo`

## Użycie Skryptów

### Skrypt `security.sh`

Skrypt `security.sh` służy do skonfigurowania serwera pod kątem bezpieczeństwa.

Użycie:

```bash
sudo ./security.sh <nazwa_użytkownika> <port_ssh>
```

- **nazwa\_użytkownika**: Nazwa nowego użytkownika, który będzie miał dostęp do serwera.
- **port\_ssh**: Numer portu, na którym będzie działać usługa SSH.

Przykład:

```bash
sudo ./security.sh webbag 2222
```

Skrypt wykonuje takie czynności jak aktualizacja systemu, tworzenie nowego użytkownika, konfiguracja SSH, włączenie UFW, instalacja `fail2ban`, `logwatch`, `unattended-upgrades` oraz `ClamAV`.

### Skrypt `openvpn.sh`

Skrypt `openvpn.sh` służy do instalacji i konfiguracji serwera OpenVPN.

Użycie:

```bash
sudo ./openvpn.sh
```

Po uruchomieniu skryptu:

- Zostaną zainstalowane pakiety `openvpn` oraz `easy-rsa`.
- Zostaną wygenerowane odpowiednie certyfikaty serwera i klienta.
- Serwer OpenVPN zostanie skonfigurowany i uruchomiony.

### Dodawanie Nowych Klientów VPN

Aby dodać nowego klienta do OpenVPN, uruchom skrypt `openvpn.sh` z odpowiednią opcją:

```bash
sudo ./openvpn.sh add-client <nazwa_klienta>
```

To polecenie wygeneruje nowe certyfikaty dla klienta, które mogą być wykorzystane do skonfigurowania połączenia VPN.

## Konfiguracja Klienta OpenVPN

Po dodaniu nowego klienta certyfikaty (`client1.crt`, `client1.key`, `ca.crt`) muszą zostać skopiowane na urządzenie klienta. Następnie można utworzyć plik konfiguracyjny klienta (`client.ovpn`) zawierający niezbędne informacje do połączenia z serwerem.

## Podsumowanie

Ten przewodnik opisuje sposób konfiguracji serwera Debian z naciskiem na bezpieczeństwo oraz uruchomienie serwera OpenVPN. Skrypty `security.sh` i `openvpn.sh` automatyzują większość czynności, co czyni proces konfiguracji szybszym i bardziej niezawodnym.


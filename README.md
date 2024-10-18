# Instalacja OpenVPN i Zaawansowana Konfiguracja Bezpieczeństwa na Debianie

## Wstęp

Niniejszy dokument przedstawia złożony proces instalacji oraz konfiguracji serwera OpenVPN, wraz ze wzmocnieniem bezpieczeństwa serwera Debian przy użyciu czterech skryptów: `security.sh`, `security-addons.sh`, `openvpn.sh` oraz `disable_unused_services.sh`.

- **Skrypt `security.sh`** koncentruje się na implementacji podstawowych aspektów bezpieczeństwa systemowego, takich jak zmiana portu SSH, wyłączenie logowania root, konfiguracja zapory ogniowej oraz instalacja podstawowych narzędzi bezpieczeństwa.
- **Skrypt `security-addons.sh`** wprowadza dodatkowe warstwy zabezpieczeń, zwiększając odporność serwera na różnorodne zagrożenia, w tym skanowanie portów oraz ataki typu brute force.
- **Skrypt `openvpn.sh`** odpowiada za kompleksową instalację i konfigurację serwera OpenVPN, umożliwiając bezpieczne połączenia VPN dla użytkowników.
- **Skrypt `disable_unused_services.sh`** służy do sprawdzania i wyłączania nieużywanych usług na serwerze VPS, co pomaga zoptymalizować jego wydajność oraz zredukować powierzchnię ataku.

## Wymagania

- Debian 10 lub nowszy
- Uprawnienia root lub dostęp do `sudo`

## Instrukcja Użycia Skryptów

### Skrypt `security.sh`

Skrypt `security.sh` służy do skonfigurowania podstawowych mechanizmów bezpieczeństwa na serwerze.

**Użycie:**

```bash
sudo ./security.sh <nazwa_użytkownika> <port_ssh>
```

- **nazwa\_użytkownika**: Nowy użytkownik, który uzyska uprawnienia do serwera.
- **port\_ssh**: Numer portu, na którym działać będzie usługa SSH.

**Przykład:**

```bash
sudo ./security.sh webbag 2222
```

Skrypt realizuje czynności takie jak aktualizacja systemu, tworzenie nowego użytkownika, konfiguracja SSH, włączenie zapory ogniowej UFW, a także instalacja `fail2ban`, `logwatch`, `unattended-upgrades` oraz `ClamAV`.

### Skrypt `security-addons.sh`

Skrypt `security-addons.sh` stanowi rozszerzenie podstawowego skryptu `security.sh`. Jego celem jest zapewnienie bardziej zaawansowanych zabezpieczeń, dodatkowo zwiększających ochronę serwera przed zagrożeniami.

**Użycie:**

```bash
sudo ./security-addons.sh
```

Skrypt `security-addons.sh` obejmuje poniższe funkcje:

1. **Limitowanie dostępu do SSH na podstawie adresu IP**: Ograniczenie dostępu do serwera SSH tylko do wybranych adresów IP.
2. **Konfiguracja Fail2Ban**: Implementacja reguł, które wykrywają oraz blokują próby nieautoryzowanego logowania do serwera poprzez SSH.
3. **Google Authenticator dla 2FA**: Instalacja oraz konfiguracja uwierzytelniania dwuskładnikowego (2FA) z użyciem Google Authenticator dla SSH.
4. **Ograniczenie liczby połączeń SSH przy użyciu UFW**: Dodanie limitu liczby połączeń do reguł zapory ogniowej, aby zapobiec atakom brute force.
5. **Monitorowanie skanowania portów za pomocą PSAD**: Instalacja i konfiguracja PSAD, narzędzia monitorującego skanowanie portów oraz automatycznie blokującego podejrzane adresy IP.
6. **Zmiana uprawnień do krytycznych plików konfiguracyjnych**: Zapewnienie odpowiedniej ochrony krytycznych plików konfiguracyjnych, takich jak `/etc/ssh/sshd_config`.
7. **Usunięcie zbędnych usług**: Eliminacja niepotrzebnych usług, takich jak Apache2 i xinetd, co pozwala zredukować potencjalną powierzchnię ataku.
8. **Wyłączenie IPv6**: Dezaktywacja IPv6, jeśli nie jest używane, w celu zminimalizowania potencjalnych wektorów ataków.
9. **Dodanie automatycznych aktualizacji**: Konfiguracja `cron` w celu regularnego przeprowadzania automatycznych aktualizacji systemowych.
10. **Konfiguracja `ulimit` dla użytkowników**: Ustawienie limitów zasobów systemowych dla użytkowników, aby zapobiec nadużyciom i przeciążeniom serwera.
11. **Wyłączenie USB Storage**: Dezaktywacja obsługi pamięci USB, co wzmacnia bezpieczeństwo fizyczne serwera.

### Skrypt `openvpn.sh`

Skrypt `openvpn.sh` realizuje pełen proces instalacji oraz konfiguracji serwera OpenVPN.

**Użycie:**

```bash
sudo ./openvpn.sh
```

Po uruchomieniu skryptu:

- Instalowane są pakiety `openvpn` oraz `easy-rsa`.
- Generowane są odpowiednie certyfikaty serwera oraz klienta.
- Skrypt kończy się uruchomieniem serwera OpenVPN, który jest gotowy do obsługi połączeń klientów.

### Dodawanie Nowych Klientów VPN

Aby dodać nowego klienta do OpenVPN, należy uruchomić skrypt `openvpn.sh` z odpowiednim argumentem:

```bash
sudo ./openvpn.sh add-client <nazwa_klienta>
```

Polecenie to generuje nowe certyfikaty klienta, które mogą być następnie wykorzystane do konfiguracji połączenia VPN.

### Skrypt `disable_unused_services.sh`

Skrypt `disable_unused_services.sh` służy do sprawdzania, wyłączania i usuwania nieużywanych usług na serwerze VPS. Dzięki temu można zoptymalizować wydajność serwera oraz zmniejszyć jego powierzchnię ataku, ograniczając liczbę uruchomionych procesów do absolutnego minimum wymaganego dla serwera VPN.

**Użycie:**

```bash
sudo ./disable_unused_services.sh
```

Skrypt `disable_unused_services.sh` sprawdza status nieużywanych usług, takich jak:

- Serwery WWW: `apache2`, `nginx`, `lighttpd`
- Usługi sieciowe: `xinetd`, `exim4`, `postfix`
- Usługi multimedialne i inne: `bluetooth`, `avahi-daemon`, `cups`, `lightdm`, `gdm3`
- Menedżery sieci: `NetworkManager`, `systemd-resolved`

Jeśli te usługi są uruchomione, skrypt je wyłącza i usuwa, co pomaga w poprawie bezpieczeństwa i wydajności serwera.

## Konfiguracja Klienta OpenVPN

Po dodaniu nowego klienta certyfikaty (`client1.crt`, `client1.key`, `ca.crt`) muszą zostać skopiowane na urządzenie klienckie. Następnie należy utworzyć plik konfiguracyjny (`client.ovpn`), zawierający wszystkie niezbędne informacje do połączenia z serwerem.

## Podsumowanie

Przewodnik ten prezentuje procedurę konfiguracji serwera Debian z uwzględnieniem kluczowych aspektów bezpieczeństwa oraz uruchomieniem serwera OpenVPN. Skrypty `security.sh`, `security-addons.sh`, `openvpn.sh` i `disable_unused_services.sh` automatyzują większość zadań, co znacząco ułatwia cały proces i zwiększa jego niezawodność.

W przypadku potrzeby uzyskania dalszych informacji, zaleca się skorzystanie z dokumentacji Debiana oraz OpenVPN lub kontakt z administratorem sieci.

# MQTT (Mosquitto) con TLS – configurazione di esempio

> Supporto a **Prima Parte – Punto 1** (dispositivi azionabili) e **Quesito II** (gestione remota).

## Scopo

- Telemetria e comandi near-real-time (pub/sub) per dispositivi (semafori, barriere, pannelli).
- Riduzione polling HTTP; HTTP resta per API “stateful” e audit.

## Porte

- `8883/TCP` MQTTS (obbligatoria)
- `1883/TCP` MQTT in chiaro (**disabilitata**)

## Mosquitto – `/etc/mosquitto/conf.d/secure.conf`

```conf
listener 8883
protocol mqtt

# TLS
cafile /etc/mosquitto/certs/ca.crt
certfile /etc/mosquitto/certs/server.crt
keyfile /etc/mosquitto/certs/server.key
require_certificate true
use_identity_as_username true

# AuthZ (ACL)
allow_anonymous false
password_file /etc/mosquitto/passwd   # opzionale se mTLS basta
acl_file /etc/mosquitto/acl

# Hardening
persistence true
persistence_location /var/lib/mosquitto/
log_type error
log_type warning
log_type notice

# Limitazioni
max_connections 2000
message_size_limit 1048576
```

## ACL – `/etc/mosquitto/acl`

```text
# Ogni dispositivo pubblica solo il proprio stato
pattern write devices/%u/status

# Il server centrale può scrivere comandi
user iot-control
topic write devices/+/cmd

# Il server centrale legge tutto lo stato
user iot-control
topic read devices/+/status
```

## Topic convention

- Stato: `devices/<deviceId>/status`
- Comandi: `devices/<deviceId>/cmd`

Esempio payload `status`:

```json
{
  "ts": "2024-07-15T14:30:00Z",
  "deviceId": "SEM-001",
  "type": "traffic_light",
  "state": "green",
  "health": "ok",
  "uptime": 86400
}
```

Esempio payload `cmd`:

```json
{
  "cmdId": "CMD-20240715-0001",
  "action": "set_state",
  "state": "red",
  "durationSec": 300,
  "reason": "Sovraffollamento zona A",
  "operator": "OP-042"
}
```

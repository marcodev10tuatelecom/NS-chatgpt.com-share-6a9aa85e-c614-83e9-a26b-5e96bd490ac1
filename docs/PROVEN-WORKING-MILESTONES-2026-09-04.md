# TPS / StudioSat — Marcos comprovadamente funcionais

Este documento guarda somente estados que foram comprovados por saída de comandos ou certificações durante o recovery. Ele **não representa o estado atual** do ambiente se posteriormente houve falha; é um ledger histórico de fatos que funcionaram e podem ser reutilizados na reconstrução.

## NS1 GCP — identidade comprovada

- VM GCP: `tpsolutionshost01`
- Hostname usado no recovery: `ns1.tpsolutions.com.br`
- IP privado: `10.142.0.2`
- IP público: `35.231.174.46`
- Ubuntu 24.04.4 LTS, amd64

## MediaMTX — instalação e baseline comprovados

- Serviço: `tps-mediamtx.service`
- Binário: `/opt/tpsmedia/mediamtx/current/mediamtx`
- Configuração: `/etc/tpsmedia/mediamtx/mediamtx.yml`
- API local: `127.0.0.1:9997`
- RTMP: `*:1935`
- HLS: `127.0.0.1:8888`
- WebRTC HTTP: `127.0.0.1:8889`
- WebRTC UDP/ICE: `*:8189`

Em uma certificação anterior, o serviço permaneceu com PID `54168` durante a ativação dos sites e os 10 HLS abaixo responderam com manifesto válido:

- `radio-main`
- `radio-pop-main`
- `radio-rock-main`
- `radio-classicas-main`
- `radio-country-main`
- `radiotv-main`
- `tvkids-main`
- `tvteens-main`
- `tv-crista-main`
- `tv-jovem-main`

## Nginx / sites — ativação comprovada por IP

O pacote `TPS-STUDIOSAT-SITES-v2` foi ativado em `/srv/tpsweb/www/tps-media-test` com backup anterior em:

`/srv/tpsweb/backups/sites-pre-v2-20260904T013301Z`

Na certificação imediatamente posterior, responderam HTTP 200 pelo IP `35.231.174.46`:

- `/`
- `/radio/`
- `/radio-pop/`
- `/radio-rock/`
- `/radio-classicas/`
- `/radio-country/`
- `/radiotv/`
- `/tvkids/`
- `/tvteens/`
- `/tv-crista/`
- `/tv-jovem/`

Nessa mesma ativação, Nginx permaneceu no PID `56033`, MediaMTX no PID `54168` e SSH no PID `50120`, sem restart registrado.

## DNS autoritativo NS1 — zona StudioSat comprovada

`studiosatweb.com.br` foi comprovada no NS1 como:

- `type: primary`
- arquivo-fonte: `/var/cache/bind/tps-primary/studiosatweb.com.br/db.studiosatweb.com.br`
- `dynamic: no`
- `dnssec-policy default`
- `inline signing: yes`
- `secure: yes`
- key directory: `/var/cache/bind/tps-dnssec/studiosatweb.com.br`

Na leitura de 2026-09-04, os registros A comprovadamente existentes no NS1 incluíam:

- `studiosatweb.com.br -> 35.231.174.46`
- `www.studiosatweb.com.br -> 35.231.174.46`
- `radio.studiosatweb.com.br -> 35.231.174.46`
- `radiotv.studiosatweb.com.br -> 35.231.174.46`

A chave DNSSEC nova comprovada no recovery tinha key tag `29180`, algoritmo 13, com DS:

`29180 13 2 A39BD784FB5D0E194BF23791842244B34939672C03FCEFF8375D8F59A21D004D`

O DS antigo no pai ainda era `55043`, portanto o cutover DNSSEC externo não estava concluído naquele ponto.

## Biblioteca canônica de programação — criação comprovada

O serviço destacado `tps-media-library-20260904T020304Z.service` concluiu com:

`TPS_MEDIA_CANONICAL_LIBRARY=PASS`

Sem alteração de SSH, rede, UFW, Nginx, MediaMTX ou BIND. Os PIDs permaneceram:

- SSH `50120 -> 50120`
- Nginx `56033 -> 56033`
- MediaMTX `54168 -> 54168`
- named `49187 -> 49187`

Diretórios canônicos criados:

### Rádios

- `/srv/tpsmedia/library/radio/studiosat/music`
- `/srv/tpsmedia/library/radio-pop/music`
- `/srv/tpsmedia/library/radio-rock/music`
- `/srv/tpsmedia/library/radio-classicas/music`
- `/srv/tpsmedia/library/radio-country/music`

Cada rádio também recebeu subdiretórios de `jingles`, `commercials`, `ids` e `playlists`.

### RadioTV

- `/srv/tpsmedia/library/radiotv/visuals`
- `/srv/tpsmedia/library/radiotv/ids`
- `/srv/tpsmedia/library/radiotv/overlays`
- `/srv/tpsmedia/library/radiotv/commercials`
- `/srv/tpsmedia/library/radiotv/playlists`

### TVs

- `/srv/tpsmedia/library/tvkids/programs`
- `/srv/tpsmedia/library/tvteens/programs`
- `/srv/tpsmedia/library/tv-crista/programs`
- `/srv/tpsmedia/library/tv-jovem/programs`

Cada TV também recebeu `commercials`, `bumpers`, `ids`, `trailers` e `playlists`.

## Método comprovado para tarefas que não devem depender do SSH

A criação da biblioteca foi executada com `systemd-run --no-block`, e o processo continuou sob o PID 1 independentemente da sessão SSH. Esse método é aprovado para tarefas longas de diagnóstico/recovery.

## Regra de uso deste documento

- Use apenas como fonte de **fatos historicamente comprovados**.
- Antes de qualquer mutação, o estado atual deve ser medido novamente.
- Não reutilizar configurações antigas cegamente.
- Não restaurar autoridades duplicadas.
- Não publicar credenciais, TSIG secrets, chaves privadas TLS/DNSSEC ou tokens no repositório.

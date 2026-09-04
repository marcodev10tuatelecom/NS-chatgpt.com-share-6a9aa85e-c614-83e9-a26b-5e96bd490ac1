# TPS / StudioSat — Recovery State — 2026-09-04

> Arquivo de continuidade operacional. Não substitui o transcript bruto da conversa.

## Situação declarada pelo usuário

Produção em falha no momento atual:

- sites oficiais em `studiosatweb.com.br` e subdomínios não estão acessíveis publicamente;
- `www.radio.studiosatweb.com.br` e `www.tvkidsweb.studiosatweb.com.br` foram observados no navegador retornando `DNS_PROBE_FINISHED_NXDOMAIN`;
- SSH público do NS1 não está conectando de forma confiável; conexão direta observada com `Connection reset by 35.231.174.46 port 22`;
- IAP/SSH também apresentou encerramentos de sessão durante o recovery;
- RadioBOSS não está conseguindo publicar;
- OBS não está conseguindo publicar;
- placeholders e playout contínuo das TVs não devem ser considerados funcionalmente certificados no estado atual;
- o usuário exige que scripts não dependam da sessão SSH permanecer aberta.

## Arquitetura alvo

### NS1 GCP — primário

- recurso GCP: `tpsolutionshost01`
- hostname: `ns1.tpsolutions.com.br`
- projeto: `project-5fa502b6-8909-4e17-a40`
- zona: `us-east1-d`
- IP privado: `10.142.0.2`
- IP público: `35.231.174.46`
- SO: Ubuntu 24.04.4 LTS, amd64
- funções alvo:
  - BIND autoritativo primário;
  - DNSSEC;
  - MediaMTX;
  - Nginx Edge;
  - ingest e distribuição das rádios/RadioTV/TVs;
  - biblioteca e playout persistente das emissoras.

### NS2 GCP — secundário

- recurso: `tpsolutions-ns2`
- zona: `us-east1-d`
- IP privado: `10.142.0.5`
- IP público: `34.24.141.159`
- função alvo: BIND autoritativo secundário + futura redundância de mídia.
- estado conhecido no último probe: BIND ativo, mas sem TSIG GCP, sem configuração secondary e sem zonas TPS carregadas.

## DNS / studiosatweb.com.br

Último estado comprovado diretamente no NS1:

- zona `studiosatweb.com.br`: `type: primary`;
- arquivo fonte: `/var/cache/bind/tps-primary/studiosatweb.com.br/db.studiosatweb.com.br`;
- `dynamic: no`;
- `inline signing: yes`;
- `dnssec-policy default`;
- key-directory: `/var/cache/bind/tps-dnssec/studiosatweb.com.br`;
- serial fonte observado: `2026090301`;
- signed serial observado: `2026090305`;
- DNSSEC seguro/inline ativo.

Nova chave DNSSEC GCP observada anteriormente:

- key tag: `29180`
- algoritmo: `13`
- DS SHA-256:
  `A39BD784FB5D0E194BF23791842244B34939672C03FCEFF8375D8F59A21D004D`

O pai ainda foi observado com DS antigo `55043`; portanto cutover DNSSEC não deve ser considerado concluído.

Registros A que já foram observados no NS1:

- `studiosatweb.com.br -> 35.231.174.46`
- `www.studiosatweb.com.br -> 35.231.174.46`
- `radio.studiosatweb.com.br -> 35.231.174.46`
- `radiotv.studiosatweb.com.br -> 35.231.174.46`

Foram identificados nomes adicionais usados pelo rebuild, mas o usuário também utiliza aliases oficiais/legados como:

- `www.radio.studiosatweb.com.br`
- `tvkidsweb.studiosatweb.com.br`
- `www.tvkidsweb.studiosatweb.com.br`

Há necessidade de reconciliar todos os hostnames oficiais e aliases no DNS e Nginx sem criar autoridades paralelas.

## Serviços NS1 — último estado técnico anteriormente certificado

Em fases anteriores do recovery foram observados:

- SSH `MainPID=50120`, `NRestarts=0`;
- Nginx `MainPID=56033`;
- MediaMTX `MainPID=54168`;
- BIND/named `MainPID=49187`.

Esses PIDs não devem ser tratados como estado atual sem nova coleta.

## MediaMTX

Instalação conhecida:

- versão alvo: MediaMTX v1.20.1 amd64;
- binário: `/opt/tpsmedia/mediamtx/current/mediamtx`;
- configuração: `/etc/tpsmedia/mediamtx/mediamtx.yml`;
- serviço: `tps-mediamtx.service`;
- API local: `127.0.0.1:9997`;
- RTMP: `*:1935`;
- HLS: `127.0.0.1:8888`;
- WebRTC: `127.0.0.1:8889`;
- ICE UDP: `*:8189`.

Paths construídos no recovery:

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

A porta pública RTMP 1935 não deve ser considerada liberada/certificada no estado atual. Isso é um provável bloqueador para RadioBOSS/OBS e precisa ser medido antes de qualquer alteração.

## Sites temporários construídos no recovery

Foi construído um site v2 estático e houve certificação anterior por IP em:

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

Root usado no Nginx durante o recovery:

`/srv/tpsweb/www/tps-media-test`

Backup anterior preservado:

`/srv/tpsweb/backups/sites-pre-v2-20260904T013301Z`

O fato de esses caminhos terem retornado HTTP 200 anteriormente não deve ser usado para afirmar que os domínios oficiais estão funcionando agora.

## Biblioteca canônica criada

A criação foi concluída via `systemd-run`, destacada do SSH, com resultado:

- `TPS_MEDIA_CANONICAL_LIBRARY=PASS`
- SSH PID preservado;
- Nginx PID preservado;
- MediaMTX PID preservado;
- named PID preservado.

Diretório base:

`/srv/tpsmedia/library`

### Rádios

- StudioSat Rádio: `/srv/tpsmedia/library/radio/studiosat/music/`
- Rádio POP: `/srv/tpsmedia/library/radio-pop/music/`
- Rádio ROCK: `/srv/tpsmedia/library/radio-rock/music/`
- Rádio Clássicas: `/srv/tpsmedia/library/radio-classicas/music/`
- Rádio Country: `/srv/tpsmedia/library/radio-country/music/`

Complementos por rádio:

- `commercials/`
- `jingles/`
- `ids/`
- `playlists/`

### TVs

- TV Kids: `/srv/tpsmedia/library/tvkids/programs/`
- TV Teens: `/srv/tpsmedia/library/tvteens/programs/`
- TV Cristã: `/srv/tpsmedia/library/tv-crista/programs/`
- TV Jovem Popular: `/srv/tpsmedia/library/tv-jovem/programs/`

Complementos por TV:

- `commercials/`
- `bumpers/`
- `ids/`
- `trailers/`
- `playlists/`

### Placeholders

Diretório temporário:

`/var/lib/tpsmedia/placeholders/`

Não deve receber programação definitiva.

## Playout alvo

Cada TV deverá possuir um único playout persistente que:

1. lê os vídeos da pasta canônica em ordem determinística;
2. reproduz todos sequencialmente;
3. ao terminar o último, volta ao primeiro;
4. publica no path MediaMTX específico da emissora;
5. continua funcionando independentemente de SSH;
6. substitui o placeholder apenas depois de catálogo real validado;
7. não cria múltiplos publishers para o mesmo path.

## Política de SSH obrigatória

Os scripts de produção não podem depender de uma sessão SSH permanecer aberta.

Regra operacional adotada:

- SSH serve apenas para disparar e consultar;
- mutações mais longas devem rodar destacadas, preferencialmente via `systemd-run --no-block`;
- não executar `ufw reset`;
- não reiniciar/reconfigurar SSH durante recovery;
- não alterar interface, rota, firewall ou reboot junto com mudanças de aplicação;
- qualquer perda de sessão durante operação deve ser tratada como falha operacional até prova em contrário;
- preservar IAP e acesso público como caminhos administrativos independentes enquanto o recovery estiver instável.

## Próxima ação correta

Executar um Raio-X read-only do estado atual antes de qualquer nova mutação, cobrindo:

- GCP firewall e tags;
- TCP público 22/53/80/443/1935;
- SSH público e IAP;
- listeners locais;
- UFW/nftables;
- BIND, zonas, DNSSEC e aliases oficiais;
- Nginx, vhosts e `server_name` duplicados/conflitantes;
- certificados;
- MediaMTX e paths;
- publishers ativos/duplicados;
- RadioBOSS/OBS ingress;
- placeholders;
- biblioteca;
- playouts/timers/services;
- serviços duplicados/legados.

Nenhuma correção deve ser feita até o RX distinguir AS-IS comprovado de TO-BE.

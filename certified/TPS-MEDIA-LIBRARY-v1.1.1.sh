#!/usr/bin/env bash
set -Eeuo pipefail
umask 027

BASE="/srv/tpsmedia/library"
LOCK="/run/lock/tps-media-library.lock"

exec 9>"$LOCK"
flock -n 9 || {
    echo "FATAL=ANOTHER_RUN_ACTIVE"
    exit 1
}

echo "============================================================"
echo " TPS MEDIA CANONICAL LIBRARY v1.1.1"
echo " DETACHED / IDEMPOTENT"
echo "============================================================"

[[ "$(id -u)" -eq 0 ]] || {
    echo "FATAL=ROOT_REQUIRED"
    exit 1
}

[[ "$(hostname -f)" == "ns1.tpsolutions.com.br" ]] || {
    echo "FATAL=WRONG_HOST"
    exit 1
}

getent passwd tpsmedia >/dev/null || {
    echo "FATAL=TPSMEDIA_USER_MISSING"
    exit 1
}

getent group tpsmedia >/dev/null || {
    echo "FATAL=TPSMEDIA_GROUP_MISSING"
    exit 1
}

SSH_PID_BEFORE="$(systemctl show ssh -p MainPID --value)"
SSH_NR_BEFORE="$(systemctl show ssh -p NRestarts --value)"
NGINX_PID_BEFORE="$(systemctl show nginx -p MainPID --value)"
MTX_PID_BEFORE="$(systemctl show tps-mediamtx -p MainPID --value)"
NAMED_PID_BEFORE="$(systemctl show named -p MainPID --value)"

DIRS=(
    "$BASE"

    "$BASE/radio/studiosat"/{music,jingles,commercials,ids,playlists}

    "$BASE/radio-pop"/{music,jingles,commercials,ids,playlists}
    "$BASE/radio-rock"/{music,jingles,commercials,ids,playlists}
    "$BASE/radio-classicas"/{music,jingles,commercials,ids,playlists}
    "$BASE/radio-country"/{music,jingles,commercials,ids,playlists}

    "$BASE/radiotv"/{visuals,ids,overlays,commercials,playlists}

    "$BASE/tvkids"/{programs,commercials,bumpers,ids,trailers,playlists}
    "$BASE/tvteens"/{programs,commercials,bumpers,ids,trailers,playlists}
    "$BASE/tv-crista"/{programs,commercials,bumpers,ids,trailers,playlists}
    "$BASE/tv-jovem"/{programs,commercials,bumpers,ids,trailers,playlists}
)

echo
echo "=== PRECHECK ==="

for D in "${DIRS[@]}"; do
    if [[ -L "$D" ]]; then
        echo "FATAL=SYMLINK_NOT_ALLOWED PATH=$D"
        exit 1
    fi

    if [[ -e "$D" && ! -d "$D" ]]; then
        echo "FATAL=NON_DIRECTORY_PATH PATH=$D"
        exit 1
    fi
done

echo "PRECHECK=PASS"

echo
echo "=== CREATE ==="

for D in "${DIRS[@]}"; do
    install \
        -d \
        -o root \
        -g tpsmedia \
        -m 2750 \
        "$D"

    echo "READY=$D"
done

cat >"$BASE/README-PATHS.txt" <<'EOF'
TPS MEDIA — DIRETORIOS CANONICOS

STUDIOSAT RADIO
/srv/tpsmedia/library/radio/studiosat/music

RADIO POP
/srv/tpsmedia/library/radio-pop/music

RADIO ROCK
/srv/tpsmedia/library/radio-rock/music

RADIO CLASSICAS
/srv/tpsmedia/library/radio-classicas/music

RADIO COUNTRY
/srv/tpsmedia/library/radio-country/music

TV KIDS
/srv/tpsmedia/library/tvkids/programs

TV TEENS
/srv/tpsmedia/library/tvteens/programs

TV CRISTA
/srv/tpsmedia/library/tv-crista/programs

TV JOVEM POPULAR
/srv/tpsmedia/library/tv-jovem/programs

RADIOTV — ELEMENTOS VISUAIS
/srv/tpsmedia/library/radiotv/visuals

PLACEHOLDERS TEMPORARIOS
/var/lib/tpsmedia/placeholders

NAO COLOCAR PROGRAMACAO DEFINITIVA EM PLACEHOLDERS.
EOF

chown root:tpsmedia "$BASE/README-PATHS.txt"
chmod 0640 "$BASE/README-PATHS.txt"

echo
echo "=== VALIDATION ==="

for D in "${DIRS[@]}"; do
    test -d "$D" || {
        echo "FATAL=MISSING_DIRECTORY PATH=$D"
        exit 1
    }
done

echo "DIRECTORIES=PASS"

SSH_PID_AFTER="$(systemctl show ssh -p MainPID --value)"
SSH_NR_AFTER="$(systemctl show ssh -p NRestarts --value)"
NGINX_PID_AFTER="$(systemctl show nginx -p MainPID --value)"
MTX_PID_AFTER="$(systemctl show tps-mediamtx -p MainPID --value)"
NAMED_PID_AFTER="$(systemctl show named -p MainPID --value)"

echo
echo "=== SERVICE SURVIVAL ==="
echo "SSH_PID=$SSH_PID_BEFORE->$SSH_PID_AFTER"
echo "SSH_NRESTARTS=$SSH_NR_BEFORE->$SSH_NR_AFTER"
echo "NGINX_PID=$NGINX_PID_BEFORE->$NGINX_PID_AFTER"
echo "MEDIAMTX_PID=$MTX_PID_BEFORE->$MTX_PID_AFTER"
echo "NAMED_PID=$NAMED_PID_BEFORE->$NAMED_PID_AFTER"

[[ "$SSH_PID_BEFORE" == "$SSH_PID_AFTER" ]]
[[ "$SSH_NR_BEFORE" == "$SSH_NR_AFTER" ]]
[[ "$NGINX_PID_BEFORE" == "$NGINX_PID_AFTER" ]]
[[ "$MTX_PID_BEFORE" == "$MTX_PID_AFTER" ]]
[[ "$NAMED_PID_BEFORE" == "$NAMED_PID_AFTER" ]]

echo
echo "============================================================"
echo "TPS_MEDIA_CANONICAL_LIBRARY=PASS"
echo "SSH_TOUCHED=NO"
echo "NETWORK_TOUCHED=NO"
echo "UFW_TOUCHED=NO"
echo "NGINX_TOUCHED=NO"
echo "MEDIAMTX_TOUCHED=NO"
echo "BIND_TOUCHED=NO"
echo "============================================================"

#!/bin/bash

username=$1
password=$2
dias=$3
sshlimiter=$4

# Se limite ou dias vierem vazios ou não forem números, define valores padrão
if ! [[ "$sshlimiter" =~ ^[0-9]+$ ]]; then sshlimiter=1; fi
if ! [[ "$dias" =~ ^[0-9]+$ ]]; then dias=30; fi

# Calcula as datas
dias=$(($dias+1))
final=$(date "+%Y-%m-%d" -d "+$dias days")

# Criptografa a senha com perl
pass=$(perl -e 'print crypt($ARGV[0], "password")' "$password")

# 1. Cria o usuário no sistema Linux
useradd -e "$final" -M -s /bin/false -p "$pass" "$username"

if [ $? -eq 0 ]; then
    saved=0
    DIR_PRINCIPAL="/etc/sshcore/senha"
    DIR_SECUNDARIO="/etc/SSHPlus/senha"

    # Salva no sshcore se o diretório existir
    if [ -d "$DIR_PRINCIPAL" ]; then
        echo "$password" > "$DIR_PRINCIPAL/$username"
        saved=1
    fi

    # Salva no SSHPlus se o diretório existir
    if [ -d "$DIR_SECUNDARIO" ]; then
        echo "$password" > "$DIR_SECUNDARIO/$username"
        saved=1
    fi

    # Se nenhum dos dois diretórios existir no sistema
    if [ $saved -eq 0 ]; then
        echo "ERRO: Nenhum dos diretórios de senha foi encontrado."
        exit 1
    fi

    # 2. Grava no banco em texto (/root/usuarios.db)
    echo "$username $sshlimiter" >> /root/usuarios.db

    # 3. Atualiza o banco do SSH CORE (/opt/sshcore/usuarios.db)
    if [ -f "/opt/sshcore/usuarios.db" ]; then
        echo "$username $sshlimiter" >> /opt/sshcore/usuarios.db 2>/dev/null
    fi

    # Se a ferramenta sqlite3 estiver instalada, insere no banco nativo
    if command -v sqlite3 >/dev/null 2>&1 && [ -f "/opt/sshcore/usuarios.db" ]; then
        sqlite3 /opt/sshcore/usuarios.db "INSERT OR REPLACE INTO usuarios (username, limiter) VALUES ('$username', '$sshlimiter');" 2>/dev/null
    fi

    echo "SUCCESS"
    exit 0
else
    echo "ERROR_USERADD_FAILED"
    exit 1
fi

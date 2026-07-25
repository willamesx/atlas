#!/bin/bash

username=$1
password=$2
sshlimiter=$3  # <--- Invertido
dias=$4        # <--- Invertido

# Se limite ou dias vierem vazios, define valores padrão
if [ -z "$sshlimiter" ]; then sshlimiter=1; fi
if [ -z "$dias" ]; then dias=30; fi

# Calcula a data de expiração
dias=$(($dias+1))
final=$(date "+%Y-%m-%d" -d "+$dias days")

# 1. Cria o usuário no sistema Linux
useradd -e "$final" -M -s /bin/false -p "$(openssl passwd -1 "$password")" "$username"

if [ $? -eq 0 ]; then
    
    saved=0
    DIR_PRINCIPAL="/etc/sshcore/senha"
    DIR_SECUNDARIO="/etc/SSHPlus/senha"
    
    # Testa se o diretório principal EXISTE
    if [ -d "$DIR_PRINCIPAL" ]; then
        echo "$password" > "$DIR_PRINCIPAL/$username"
        saved=1
    fi
    
    # Testa se o diretório secundário EXISTE
    if [ -d "$DIR_SECUNDARIO" ]; then
        echo "$password" > "$DIR_SECUNDARIO/$username"
        saved=1
    fi
    
    # Se nenhum dos dois diretórios existia no sistema
    if [ $saved -eq 0 ]; then
        echo "ERRO: Nenhum dos diretórios de senha foi encontrado."
        exit 1
    fi

    # Adiciona ao banco de limites de usuários
    echo "$username $sshlimiter" >> /root/usuarios.db
    
    echo "SUCCESS"
    exit 0
else
    echo "ERROR_USERADD_FAILED"
    exit 1
fi

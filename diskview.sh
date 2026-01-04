#!/bin/bash

# Importar configurações se existirem
APP_PATH=$(dirname "$(readlink -f "$0")")
[ -f "$APP_PATH/config.sh" ] && source "$APP_PATH/config.sh"

LINHA=5
COLUNA=20
LARGURA_BOX=55
MODO="resumido"
RESET='\033[0m'
FG_CYAN='\033[36m'
FG_YELLOW='\033[33m'

mover_cursor() { echo -ne "\033[$((LINHA + $1));${COLUNA}H"; }

limpar_area() {
    for i in {0..20}; do
        mover_cursor $i
        printf '%*s' "$LARGURA_BOX" ""
    done
}

imprimir_linha_box() {
    local num_linha=$1
    local texto="$2"
    local texto_puro=$(echo -e "$texto" | sed 's/\x1b\[[0-9;]*m//g')
    local tam_visivel=${#texto_puro}
    local espacos=$(( (LARGURA_BOX - 5) - tam_visivel ))

    mover_cursor $num_linha
    echo -ne "│  $texto"
    [ $espacos -gt 0 ] && printf '%*s' "$espacos" ""
    echo -ne " │"
}

desenhar_painel() {
    limpar_area

    # 1. Topo da Caixa
    mover_cursor 0
    echo -ne "┌"
    printf '─%.0s' $(seq 1 $((LARGURA_BOX - 2)))
    echo -ne "┐"

    if [ "$MODO" == "resumido" ]; then
        # --- MODO RESUMIDO ---
        DISCO_RAIZ=$(lsblk -no PKNAME $(findmnt -nvo SOURCE /) | head -n1)
        # Se não encontrar o pai (ex: em algumas VPS), usa o próprio disco do /
        [ -z "$DISCO_RAIZ" ] && DISCO_RAIZ=$(findmnt -nvo SOURCE / | sed 's|/dev/||')

        MODELO=$(lsblk -dno MODEL "/dev/$DISCO_RAIZ" 2>/dev/null | xargs)
        DISK_INFO=$(df -h / | tail -1)
        DISK_TOTAL=$(echo $DISK_INFO | awk '{print $2}')
        DISK_PERC=$(echo $DISK_INFO | awk '{print $5}' | tr -d '%')

        imprimir_linha_box 1 "SISTEMA ATUAL"
        imprimir_linha_box 2 "Hardware: ${MODELO:-Disco Virtual / SSD}"

        BAR_SIZE=25
        FILLED=$((DISK_PERC * BAR_SIZE / 100))
        EMPTY=$((BAR_SIZE - FILLED))
        BAR_COLOR='\033[42m'; [ $DISK_PERC -gt 75 ] && BAR_COLOR='\033[43m'; [ $DISK_PERC -gt 88 ] && BAR_COLOR='\033[41m'

        BARRA="["
        for ((i=0; i<FILLED; i++)); do BARRA+="${BAR_COLOR} ${RESET}"; done
        for ((i=0; i<EMPTY; i++)); do BARRA+="░"; done
        BARRA+="] ${DISK_PERC}%"

        imprimir_linha_box 3 "$BARRA"
        imprimir_linha_box 4 "Capacidade: $DISK_TOTAL"
        L_FIM=6
    else
        # --- MODO EXPANDIDO (ÁRVORE REAL) ---
        imprimir_linha_box 1 "ESTRUTURA DE DISCOS (FÍSICOS)"
        imprimir_linha_box 2 "───────────────────────────────────────────────"

        curr_l=3
        # -e 7 filtra o major number 7, que são os dispositivos de LOOP (Snaps)
        # -o define as colunas, -n remove o cabeçalho
        while IFS= read -r line; do
            # Se a linha começa com um nome de disco (sem espaços antes), é o Pai
            if [[ "$line" =~ ^[a-z0-9] ]]; then
                # Pega apenas o nome do disco para buscar o modelo
                nome_disco=$(echo "$line" | awk '{print $1}')
                modelo_disco=$(lsblk -dno MODEL "/dev/$nome_disco" 2>/dev/null | xargs)
                imprimir_linha_box $curr_l "${FG_YELLOW}💾 ${modelo_disco:-DISCO} ($nome_disco)${RESET}"
            else
                # Se tem espaços ou símbolos de árvore, é partição
                imprimir_linha_box $curr_l "$line"
            fi
            ((curr_l++))
            [ $curr_l -gt 18 ] && break
        done < <(lsblk -e 7 -o NAME,SIZE,MOUNTPOINT -i -n)

        L_FIM=$curr_l
    fi

    # 3. Rodapé
    mover_cursor $L_FIM
    echo -ne "└"
    printf '─%.0s' $(seq 1 $((LARGURA_BOX - 2)))
    echo -ne "┘"
    mover_cursor $((L_FIM + 1))
    echo -e " ${FG_CYAN}[E] Expandir  [R] Resumo  [Q] Sair${RESET}"
}

# --- LOOP PRINCIPAL ---
clear
while true; do
    desenhar_painel
    mover_cursor $((LARGURA_BOX/2))
    read -rsn1 -t 10 tecla
    case "$tecla" in
        [Ee]) MODO="expandido" ;;
        [Rr]) MODO="resumido" ;;
        [Qq]) break ;;
    esac
done
clear

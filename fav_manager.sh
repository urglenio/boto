#!/bin/bash

# --- CONFIGURAÇÃO ---
APP_PATH=$(dirname "$(readlink -f "$0")")
[ -f "$APP_PATH/config.sh" ] && source "$APP_PATH/config.sh"
FAV_FILE="$HOME/.config/boto/favoritos.txt"

# Função para repetir caracteres
repetir() {
    local char="$1"
    local count="$2"
    local str=""
    for ((i=0; i<count; i++)); do str+="$char"; done
    echo -n "$str"
}

mover_cursor() { printf "\033[%s;%sH" "$1" "$2"; }

# Inicialização do cursor
FAV_CURSOR=0

# --- CÁLCULO DE LARGURA ---
LARGURA_POPUP=$(( (COL_LARGURA * 2) ))
COL_INI=4
TAM_TEXTO=$((LARGURA_POPUP - 6))

while true; do
    # Lê os favoritos removendo linhas vazias
    mapfile -t LISTA_FAV < <(sed '/^$/d' "$FAV_FILE")

    if [ ${#LISTA_FAV[@]} -eq 0 ]; then exit 0; fi

    # Proteção para garantir que FAV_CURSOR seja sempre número
    [[ ! "$FAV_CURSOR" =~ ^[0-9]+$ ]] && FAV_CURSOR=0
    [ "$FAV_CURSOR" -ge "${#LISTA_FAV[@]}" ] && FAV_CURSOR=$((${#LISTA_FAV[@]}-1))
    [ "$FAV_CURSOR" -lt 0 ] && FAV_CURSOR=0

    LIN_INI=5

    # --- DESENHO DO POPUP (ESTILO REFORÇADO) ---

    # Topo (====)
    mover_cursor $LIN_INI $COL_INI
    echo -e "${MENU_BG}${TL}$(repetir "$HL" "$LARGURA_POPUP")${TR}${RESET}"

    # Título
    mover_cursor $((LIN_INI+1)) $COL_INI
    printf "${MENU_BG}${VL} %-${LARGURA_POPUP}s ${VL}${RESET}\n" "⭐ FAVORITOS ([Enter] Ir | [D] Del)"

    # Divisória (====)
    mover_cursor $((LIN_INI+2)) $COL_INI
    echo -e "${MENU_BG}${VL}$(repetir "$HL" "$LARGURA_POPUP")${VL}${RESET}"

    # Itens
    for f_idx in "${!LISTA_FAV[@]}"; do
        mover_cursor $((LIN_INI+3+f_idx)) $COL_INI
        CAMINHO_CURTO="${LISTA_FAV[$f_idx]}"

        # Encurta se necessário
        if [ ${#CAMINHO_CURTO} -gt $TAM_TEXTO ]; then
            CAMINHO_CURTO="...${CAMINHO_CURTO: -$((TAM_TEXTO-3))}"
        fi

        if [ "$f_idx" -eq "$FAV_CURSOR" ]; then
            # Destaque
            printf "${MENU_BG}${VL} ${HIGHLIGHT} > %-${TAM_TEXTO}s ${RESET}${MENU_BG} ${VL}${RESET}\n" "$CAMINHO_CURTO"
        else
            # Normal
            printf "${MENU_BG}${VL}   %-${TAM_TEXTO}s   ${VL}${RESET}\n" "$CAMINHO_CURTO"
        fi
    done

    # Rodapé (====)
    mover_cursor $((LIN_INI+3+${#LISTA_FAV[@]})) $COL_INI
    echo -e "${MENU_BG}${BL}$(repetir "$HL" "$LARGURA_POPUP")${BR}${RESET}"

    # --- CAPTURA DE TECLA ---
    stty -icanon -echo
    f_tecla=$(dd bs=1 count=1 2>/dev/null)
    stty echo icanon

    case "$f_tecla" in
        $'\x1b')
            read -rsn2 -t 0.01 f_resto
            [ "$f_resto" == "[A" ] && ((FAV_CURSOR--))
            [ "$f_resto" == "[B" ] && ((FAV_CURSOR++))
            ;;
        "")
            echo "${LISTA_FAV[$FAV_CURSOR]}" > /tmp/boto_fav_result
            exit 0
            ;;
        d|D)
            sed -i "$(($FAV_CURSOR + 1))d" "$FAV_FILE"
            echo "REFRESH" > /tmp/boto_fav_result
            ;;
        q|Q) exit 0 ;;
    esac
done

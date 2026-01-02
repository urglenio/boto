#!/bin/bash

APP_PATH=$(dirname "$(readlink -f "$0")")

# --- EXIBIR LOGO DE ENTRADA ---
if [ -f "$APP_PATH/logo.sh" ]; then
    bash "$APP_PATH/logo.sh"
    sleep 2  # Espera 2 segundos para o usuário ver o desenho
fi

APP_PATH=$(dirname "$(readlink -f "$0")")
[ -f "$APP_PATH/config.sh" ] && source "$APP_PATH/config.sh" || {
    BG_BLUE='\033[44m'; FG_WHITE='\033[37;1m'; FG_YELLOW='\033[33;1m'; FG_GREEN='\033[32;1m'
    RESET='\033[0m'; HIGHLIGHT='\033[47;30m'; INFOBG='\033[40;37m'; FG_CYAN='\033[36;1m'
    TL="+"; TR="+"; BL="+"; BR="+"; HL="-"; VL="|"; DIV="+"; B_DIV="+"
}

CURSOR_P=0; CURSOR_A=0; OFFSET_P=0; OFFSET_A=0
FOCO="PASTAS"; COL_LARGURA=30; MAX_VIEW=15
FILTRO="" # Variável para armazenar o termo de busca

TERM_STATE=$(stty -g)
cleanup() { stty "$TERM_STATE"; clear; exit; }
trap cleanup SIGINT SIGTERM

while true; do
    # 1. COLETA DE DADOS FILTRADA
    # Se FILTRO não estiver vazio, o grep filtra os resultados
    LISTA_BRUTA=$(ls -1F --group-directories-first 2>/dev/null | grep -i "$FILTRO")

    PASTAS=("..")
    mapfile -t -O 1 PASTAS < <(echo "$LISTA_BRUTA" | grep '/$')
    mapfile -t ARQUIVOS < <(echo "$LISTA_BRUTA" | grep -v '/$')

    total_p=${#PASTAS[@]}; total_a=${#ARQUIVOS[@]}
    [ $CURSOR_P -ge $total_p ] && CURSOR_P=$((total_p - 1))
    [ $CURSOR_A -ge $total_a ] && CURSOR_A=$((total_a - 1))
    [ $CURSOR_P -lt 0 ] && CURSOR_P=0; [ $CURSOR_A -lt 0 ] && CURSOR_A=0

    clear
    # --- INTERFACE ---
    printf "${BG_BLUE}${FG_WHITE}%s%s%s${RESET}\n" "$TL" "$(printf '%*s' $((COL_LARGURA*2+5)) | tr ' ' "$HL")" "$TR"
    printf "${BG_BLUE}${FG_WHITE}${VL} %-$(($COL_LARGURA+1))s ${VL} %-$(($COL_LARGURA+1))s ${VL}${RESET}\n" \
        "$([ "$FOCO" == "PASTAS" ] && echo "> DIRETORIOS <" || echo "  DIRETORIOS  ")" \
        "$([ "$FOCO" == "ARQUIVOS" ] && echo "> ARQUIVOS <" || echo "  ARQUIVOS  ")"
    printf "${BG_BLUE}${FG_WHITE}${VL}%s%s%s${VL}${RESET}\n" "$(printf '%*s' $((COL_LARGURA+2)) | tr ' ' "$HL")" "$DIV" "$(printf '%*s' $((COL_LARGURA+2)) | tr ' ' "$HL")"

    for ((i=0; i<MAX_VIEW; i++)); do
        echo -ne "${BG_BLUE}${FG_WHITE}${VL} "
        # Coluna Pastas... (Lógica de exibição idêntica à sua estável)
        IDX_P=$((i + OFFSET_P))
        if [ $IDX_P -lt $total_p ]; then
            N_P="${PASTAS[$IDX_P]:0:$COL_LARGURA}"
            [ "$FOCO" == "PASTAS" ] && [ $IDX_P -eq $CURSOR_P ] && \
                echo -ne "${HIGHLIGHT}${N_P}$(printf '%*s' $((COL_LARGURA - ${#N_P})) "")${RESET}${BG_BLUE}${FG_WHITE}" || \
                echo -ne "${FG_YELLOW}${N_P}${FG_WHITE}$(printf '%*s' $((COL_LARGURA - ${#N_P})) "")"
            echo -ne "$([ $i -eq $(( (CURSOR_P * (MAX_VIEW-1)) / (total_p > 1 ? total_p-1 : 1) )) ] && echo "█" || echo "░")"
        else printf "%-$(($COL_LARGURA+1))s" ""; fi

        echo -ne " ${VL} "

        # Coluna Arquivos... (Lógica de exibição idêntica à sua estável)
        IDX_A=$((i + OFFSET_A))
        if [ $IDX_A -lt $total_a ]; then
            N_A="${ARQUIVOS[$IDX_A]:0:$COL_LARGURA}"
            [ "$FOCO" == "ARQUIVOS" ] && [ $IDX_A -eq $CURSOR_A ] && \
                echo -ne "${HIGHLIGHT}${N_A}$(printf '%*s' $((COL_LARGURA - ${#N_A})) "")${RESET}${BG_BLUE}${FG_WHITE}" || \
                echo -ne "${FG_GREEN}${N_A}${FG_WHITE}$(printf '%*s' $((COL_LARGURA - ${#N_A})) "")"
            echo -ne "$([ $i -eq $(( (CURSOR_A * (MAX_VIEW-1)) / (total_a > 1 ? total_a-1 : 1) )) ] && echo "█" || echo "░")"
        else printf "%-$(($COL_LARGURA+1))s" ""; fi
        echo -e " ${VL}${RESET}"
    done
    printf "${BG_BLUE}${FG_WHITE}%s%s%s%s%s${RESET}\n" "$BL" "$(printf '%*s' $((COL_LARGURA+2)) | tr ' ' "$HL")" "$B_DIV" "$(printf '%*s' $((COL_LARGURA+2)) | tr ' ' "$HL")" "$BR"

    # --- BARRA DE STATUS E BUSCA ---
    if [ -n "$FILTRO" ]; then
        echo -e "${HIGHLIGHT} BUSCANDO: $FILTRO (Pressione ESC para limpar) ${RESET}"
    else
        [ "$FOCO" == "PASTAS" ] && ALVO="${PASTAS[$CURSOR_P]}" || ALVO="${ARQUIVOS[$CURSOR_A]}"
        ALVO_LIMPO=$(echo "$ALVO" | tr -d '*/')
        if [ -n "$ALVO" ] && [ -e "$ALVO_LIMPO" ]; then
            PERM=$(stat -c '%A' "$ALVO_LIMPO"); TAM=$([ -d "$ALVO_LIMPO" ] && echo "DIR" || ls -lh "$ALVO_LIMPO" | awk '{print $5}')
            echo -e "${INFOBG} PERM: $PERM | TAM: $TAM | DATA: $(stat -c '%y' "$ALVO_LIMPO" | cut -c1-16) ${RESET}"
        fi
    fi
    echo -e "${FG_CYAN} [/] Buscar | [ENTER] Ação | [Q] Sair ${RESET}"

    # --- CAPTURA DE TECLA ---
    stty -icanon -echo
    tecla=$(dd bs=1 count=1 2>/dev/null)
    stty "$TERM_STATE"

    case "$tecla" in
        "/") # Ativa o modo de busca
            echo -ne "\033[s" # Salva posição do cursor
            echo -ne "\033[1;1H\033[2K Buscar: " # Vai para o topo e limpa linha
            stty echo icanon
            read FILTRO
            stty -echo -icanon
            CURSOR_P=0; CURSOR_A=0; OFFSET_P=0; OFFSET_A=0
            ;;
        $'\x1b') # ESC para limpar o filtro
            FILTRO=""
            read -rsn2 -t 0.01 resto # Captura setas
            [ "$resto" == "[A" ] && { [ "$FOCO" == "PASTAS" ] && ((CURSOR_P--)) || ((CURSOR_A--)); }
            [ "$resto" == "[B" ] && { [ "$FOCO" == "PASTAS" ] && ((CURSOR_P++)) || ((CURSOR_A++)); }
            ;;
        $'\t') [ "$FOCO" == "PASTAS" ] && FOCO="ARQUIVOS" || FOCO="PASTAS" ;;
        "")
            if [ "$FOCO" == "PASTAS" ]; then
                ITEM=$(echo "${PASTAS[$CURSOR_P]}" | tr -d '*/')
                [ "$ITEM" == ".." ] && cd .. || cd "$ITEM"
                FILTRO=""; CURSOR_P=0; CURSOR_A=0
            else
                bash "$APP_PATH/menu.sh" "$(echo "${ARQUIVOS[$CURSOR_A]}" | tr -d '*/')"
            fi ;;
        q|Q) cleanup ;;
    esac
done

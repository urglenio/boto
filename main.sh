#!/bin/bash

# --- 1. GUARDA O CAMINHO ONDE O GERENCIADOR ESTÁ INSTALADO ---
# Isso garante que o menu.sh e o config.sh sejam achados em qualquer lugar
APP_PATH=$(dirname "$(readlink -f "$0")")

# --- 2. IMPORTAÇÃO USANDO CAMINHO FIXO ---
if [ -f "$APP_PATH/config.sh" ]; then
    source "$APP_PATH/config.sh"
else
    BG_BLUE='\033[44m'; FG_WHITE='\033[37;1m'; FG_YELLOW='\033[33;1m'; FG_GREEN='\033[32;1m'
    RESET='\033[0m'; HIGHLIGHT='\033[47;30m'; INFOBG='\033[40;37m'; FG_CYAN='\033[36;1m'
    TL="+"; TR="+"; BL="+"; BR="+"; HL="-"; VL="|"; DIV="+"; B_DIV="+"
fi

CURSOR_P=0; CURSOR_A=0; OFFSET_P=0; OFFSET_A=0
FOCO="PASTAS"; COL_LARGURA=30; MAX_VIEW=15

TERM_STATE=$(stty -g)
cleanup() { stty "$TERM_STATE"; clear; exit; }
trap cleanup SIGINT SIGTERM

while true; do
    # 3. COLETA DE DADOS
    LISTA_BRUTA=$(ls -1F --group-directories-first 2>/dev/null)
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
    TIT_P=" DIRETORIOS "; [ "$FOCO" == "PASTAS" ] && TIT_P="> DIRETORIOS <"
    TIT_A=" ARQUIVOS ";   [ "$FOCO" == "ARQUIVOS" ] && TIT_A="> ARQUIVOS <"
    printf "${BG_BLUE}${FG_WHITE}${VL} %-$(($COL_LARGURA+1))s ${VL} %-$(($COL_LARGURA+1))s ${VL}${RESET}\n" "$TIT_P" "$TIT_A"
    printf "${BG_BLUE}${FG_WHITE}${VL}%s%s%s${VL}${RESET}\n" "$(printf '%*s' $((COL_LARGURA+2)) | tr ' ' "$HL")" "$DIV" "$(printf '%*s' $((COL_LARGURA+2)) | tr ' ' "$HL")"

    for ((i=0; i<MAX_VIEW; i++)); do
        echo -ne "${BG_BLUE}${FG_WHITE}${VL} "
        # Coluna Pastas
        IDX_P=$((i + OFFSET_P))
        if [ $IDX_P -lt $total_p ]; then
            N_P="${PASTAS[$IDX_P]:0:$COL_LARGURA}"
            SP_P=$((COL_LARGURA - ${#N_P}))
            if [ "$FOCO" == "PASTAS" ] && [ $IDX_P -eq $CURSOR_P ]; then
                echo -ne "${HIGHLIGHT}${N_P}$(printf '%*s' $SP_P "")${RESET}${BG_BLUE}${FG_WHITE}"
            else
                echo -ne "${FG_YELLOW}${N_P}${FG_WHITE}$(printf '%*s' $SP_P "")"
            fi
            pos_p=$(( (CURSOR_P * (MAX_VIEW-1)) / (total_p > 1 ? total_p-1 : 1) ))
            [ $i -eq $pos_p ] && echo -ne "█" || echo -ne "░"
        else printf "%-$(($COL_LARGURA+1))s" ""; fi
        echo -ne " ${VL} "
        # Coluna Arquivos
        IDX_A=$((i + OFFSET_A))
        if [ $IDX_A -lt $total_a ]; then
            N_A="${ARQUIVOS[$IDX_A]:0:$COL_LARGURA}"
            SP_A=$((COL_LARGURA - ${#N_A}))
            if [ "$FOCO" == "ARQUIVOS" ] && [ $IDX_A -eq $CURSOR_A ]; then
                echo -ne "${HIGHLIGHT}${N_A}$(printf '%*s' $SP_A "")${RESET}${BG_BLUE}${FG_WHITE}"
            else
                echo -ne "${FG_GREEN}${N_A}${FG_WHITE}$(printf '%*s' $SP_A "")"
            fi
            pos_a=$(( (CURSOR_A * (MAX_VIEW-1)) / (total_a > 1 ? total_a-1 : 1) ))
            [ $i -eq $pos_a ] && echo -ne "█" || echo -ne "░"
        else printf "%-$(($COL_LARGURA+1))s" ""; fi
        echo -e " ${VL}${RESET}"
    done
    printf "${BG_BLUE}${FG_WHITE}%s%s%s%s%s${RESET}\n" "$BL" "$(printf '%*s' $((COL_LARGURA+2)) | tr ' ' "$HL")" "$B_DIV" "$(printf '%*s' $((COL_LARGURA+2)) | tr ' ' "$HL")" "$BR"

    # --- INFO BAR (PERMISSÕES E DATA) ---
    if [ "$FOCO" == "PASTAS" ]; then ALVO="${PASTAS[$CURSOR_P]}"; else ALVO="${ARQUIVOS[$CURSOR_A]}"; fi
    ALVO_LIMPO=$(echo "$ALVO" | tr -d '*/')
    if [ -n "$ALVO" ] && [ -e "$ALVO_LIMPO" ]; then
        PERM=$(stat -c '%A' "$ALVO_LIMPO")
        DONO=$(stat -c '%U' "$ALVO_LIMPO")
        DATA=$(stat -c '%y' "$ALVO_LIMPO" | cut -d. -f1 | cut -c1-16)
        [ -d "$ALVO_LIMPO" ] && TAM="DIR" || TAM=$(ls -lh "$ALVO_LIMPO" | awk '{print $5}')
        echo -e "${INFOBG} PERM: $PERM | DONO: $DONO | TAM: $TAM ${RESET}"
        echo -e "${INFOBG} DATA: $DATA | ROTA: $(realpath "$ALVO_LIMPO" | rev | cut -c1-45 | rev) ${RESET}"
    fi
    echo -e "${FG_CYAN} [TAB] Lado | [ENTER] Ação | [Q] Sair ${RESET}"

    # --- CAPTURA DE TECLA ---
    stty -icanon -echo
    tecla=$(dd bs=1 count=1 2>/dev/null)
    stty "$TERM_STATE"

    case "$tecla" in
        $'\t' | $'\x09') [ "$FOCO" == "PASTAS" ] && FOCO="ARQUIVOS" || FOCO="PASTAS" ;;
        $'\x1b')
            read -rsn2 -t 0.01 resto
            case "$resto" in
                "[A") if [ "$FOCO" == "PASTAS" ]; then
                        ((CURSOR_P--)); [ $CURSOR_P -lt $OFFSET_P ] && [ $OFFSET_P -gt 0 ] && ((OFFSET_P--))
                      else
                        ((CURSOR_A--)); [ $CURSOR_A -lt $OFFSET_A ] && [ $OFFSET_A -gt 0 ] && ((OFFSET_A--))
                      fi ;;
                "[B") if [ "$FOCO" == "PASTAS" ]; then
                        ((CURSOR_P++)); [ $CURSOR_P -ge $((OFFSET_P + MAX_VIEW)) ] && ((OFFSET_P++))
                      else
                        ((CURSOR_A++)); [ $CURSOR_A -ge $((OFFSET_A + MAX_VIEW)) ] && ((OFFSET_A++))
                      fi ;;
            esac ;;
        "" | $'\x0a' | $'\x0d')
            if [ "$FOCO" == "PASTAS" ]; then
                ITEM_P="${PASTAS[$CURSOR_P]}"
                if [ "$ITEM_P" == ".." ]; then cd ..; else cd "$(echo "$ITEM_P" | tr -d '*/')"; fi
                CURSOR_P=0; OFFSET_P=0; CURSOR_A=0; OFFSET_A=0
            else
                if [ $total_a -gt 0 ]; then
                    ARQ_FINAL=$(echo "${ARQUIVOS[$CURSOR_A]}" | tr -d '*/')
                    # CHAMA O MENU USANDO O CAMINHO ABSOLUTO SALVO NO INÍCIO
                    bash "$APP_PATH/menu.sh" "$ARQ_FINAL"
                fi
            fi ;;
        q|Q) cleanup ;;
    esac
done

#!/bin/bash

# --- CONFIGURAÇÃO DE CAMINHO ---
APP_PATH=$(dirname "$(readlink -f "$0")")

# --- FUNÇÃO DE SAÍDA (SALVA DIRETÓRIO PARA O ALIAS) ---
TERM_STATE=$(stty -g)
cleanup() {
    stty "$TERM_STATE"
    # Salva o diretório atual em um arquivo temporário para o terminal ler ao sair
    pwd > /tmp/boto_last_dir
    chmod 777 /tmp/boto_last_dir 2>/dev/null
    clear
    exit
}
trap cleanup SIGINT SIGTERM

# --- CARREGAR CONFIGURAÇÕES ---
# Padrões de segurança (caso o config.sh seja apagado ou esteja incompleto)
BG_BLUE='\033[44m'; FG_WHITE='\033[37;1m'; FG_YELLOW='\033[33;1m'; FG_GREEN='\033[32;1m'
RESET='\033[0m'; HIGHLIGHT='\033[47;30m'; INFOBG='\033[40;37m'; FG_CYAN='\033[36;1m'
TL="+"; TR="+"; BL="+"; BR="+"; HL="-"; VL="|"; DIV="+"; B_DIV="+"
MAX_VIEW=15
COL_LARGURA=30

# Carrega as configurações reais do arquivo
if [ -f "$APP_PATH/config.sh" ]; then
    source "$APP_PATH/config.sh"
fi

# Variáveis de Navegação
CURSOR_P=0; CURSOR_A=0; OFFSET_P=0; OFFSET_A=0
FOCO="PASTAS"
FILTRO=""

# Função auxiliar para mover cursor
mover_cursor() { printf "\033[%s;%sH" "$1" "$2"; }

# --- EXIBIR LOGO DE ENTRADA ---
if [ -f "$APP_PATH/logo.sh" ]; then
    bash "$APP_PATH/logo.sh"
    sleep 2
fi

while true; do
    # Atualiza o nome da pasta atual no cabeçalho
    NOME_PASTA_ATUAL=$(basename "$(pwd)")
    [ "$NOME_PASTA_ATUAL" == "/" ] && NOME_PASTA_ATUAL="RAIZ"

    # 1. COLETA DE DADOS FILTRADA
    LISTA_BRUTA=$(ls -1F --group-directories-first 2>/dev/null | grep -i "$FILTRO")
    PASTAS=("..")
    mapfile -t -O 1 PASTAS < <(echo "$LISTA_BRUTA" | grep '/$')
    mapfile -t ARQUIVOS < <(echo "$LISTA_BRUTA" | grep -v '/$')

    total_p=${#PASTAS[@]}; total_a=${#ARQUIVOS[@]}

    # Ajuste de cursores
    [ $CURSOR_P -ge $total_p ] && CURSOR_P=$((total_p - 1))
    [ $CURSOR_A -ge $total_a ] && CURSOR_A=$((total_a - 1))
    [ $CURSOR_P -lt 0 ] && CURSOR_P=0; [ $CURSOR_A -lt 0 ] && CURSOR_A=0

    clear
    # --- INTERFACE ---
    LARGURA_TOTAL=$((COL_LARGURA * 2 + 5))
    printf "${BG_BLUE}${FG_WHITE}%s%s%s${RESET}\n" "$TL" "$(printf '%*s' "$LARGURA_TOTAL" | tr ' ' "$HL")" "$TR"

    TIT_P=" DIRETORIOS "; [ "$FOCO" == "PASTAS" ] && TIT_P="> DIRETORIOS <"
    FOLDER_LABEL="${NOME_PASTA_ATUAL:0:$((COL_LARGURA-2))}"
    TIT_A=" $FOLDER_LABEL "; [ "$FOCO" == "ARQUIVOS" ] && TIT_A="> $FOLDER_LABEL <"

    printf "${BG_BLUE}${FG_WHITE}${VL} %-$(($COL_LARGURA+1))s ${VL} %-$(($COL_LARGURA+1))s ${VL}${RESET}\n" "$TIT_P" "$TIT_A"
    printf "${BG_BLUE}${FG_WHITE}${VL}%s%s%s${VL}${RESET}\n" "$(printf '%*s' $((COL_LARGURA+2)) | tr ' ' "$HL")" "$DIV" "$(printf '%*s' $((COL_LARGURA+2)) | tr ' ' "$HL")"

    # --- LISTAGEM ---
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

    # --- BARRA DE STATUS ---
    if [ -n "$FILTRO" ]; then
        echo -e "${HIGHLIGHT} BUSCANDO: $FILTRO (ESC para limpar) ${RESET}"
    else
        [ "$FOCO" == "PASTAS" ] && ALVO="${PASTAS[$CURSOR_P]}" || ALVO="${ARQUIVOS[$CURSOR_A]}"
        ALVO_LIMPO=$(echo "$ALVO" | tr -d '*/')
        if [ -n "$ALVO" ] && [ -e "$ALVO_LIMPO" ]; then
            PERM=$(stat -c '%A' "$ALVO_LIMPO"); TAM=$([ -d "$ALVO_LIMPO" ] && echo "DIR" || ls -lh "$ALVO_LIMPO" | awk '{print $5}')
            echo -e "${INFOBG} PERM: $PERM | TAM: $TAM | DATA: $(stat -c '%y' "$ALVO_LIMPO" | cut -c1-16) ${RESET}"
        fi
    fi
    echo -e "${FG_CYAN} [/] Buscar [N] Pasta [M] Menu [C] Config [TAB] Lado [Q] Sair ${RESET}"

    # --- CAPTURA DE TECLAS ---
    stty -icanon -echo
    tecla=$(dd bs=1 count=1 2>/dev/null)
    stty "$TERM_STATE"

    case "$tecla" in
        "/") # BUSCA
            mover_cursor 1 1; echo -ne "\033[2K ${FG_CYAN}Buscar por: ${RESET}"
            stty echo icanon; read TERMO; stty -echo -icanon
            if [ -n "$TERMO" ]; then
                mover_cursor 6 15; echo -e "${MENU_BG}┌──────────────────────────────┐${RESET}"
                mover_cursor 7 15; echo -e "${MENU_BG}│ ONDE PESQUISAR?              │${RESET}"
                mover_cursor 8 15; echo -e "${MENU_BG}├──────────────────────────────┤${RESET}"
                mover_cursor 9 15; echo -e "${MENU_BG}│ [ENTER] Pasta Atual          │${RESET}"
                mover_cursor 10 15; echo -e "${MENU_BG}│ [2] Todo o Sistema (Global)  │${RESET}"
                mover_cursor 11 15; echo -e "${MENU_BG}└──────────────────────────────┘${RESET}"
                read -rsn1 escopo
                if [ "$escopo" == "2" ]; then
                    clear; echo -e "${FG_YELLOW}🔍 Buscando '$TERMO' no sistema...${RESET}"
                    mapfile -t RESULTADOS < <(sudo find / -maxdepth 4 -iname "*$TERMO*" 2>/dev/null | head -n 20)
                    if [ ${#RESULTADOS[@]} -eq 0 ]; then echo "Nada encontrado."; sleep 1
                    else
                        stty echo icanon; PS3="Escolha o número: "; select escolha in "${RESULTADOS[@]}"; do
                            if [ -n "$escolha" ]; then [ -d "$escolha" ] && cd "$escolha" || cd "$(dirname "$escolha")"; fi
                            break
                        done; stty -echo -icanon
                    fi
                else FILTRO="$TERMO"; fi
            fi
            CURSOR_P=0; CURSOR_A=0; OFFSET_P=0; OFFSET_A=0 ;;

        "n"|"N") # NOVA PASTA
            printf "\033[1;1H\033[2K${FG_YELLOW} Nome da nova pasta: ${RESET}"
            stty echo icanon; read nova_pasta; stty -echo -icanon
            [ -n "$nova_pasta" ] && mkdir -p "$nova_pasta" ;;

        "m"|"M") # MENU DE AÇÕES
            [ "$FOCO" == "PASTAS" ] && ALVO_M=$(echo "${PASTAS[$CURSOR_P]}" | tr -d '*/') || ALVO_M=$(echo "${ARQUIVOS[$CURSOR_A]}" | tr -d '*/')
            [ -n "$ALVO_M" ] && [ "$ALVO_M" != ".." ] && bash "$APP_PATH/menu.sh" "$ALVO_M" ;;

        "c"|"C") # GERENCIADOR DE CONFIGURAÇÕES
            if [ -f "$APP_PATH/config_manager.sh" ]; then
                bash "$APP_PATH/config_manager.sh"
                # Recarrega as configurações para aplicar as mudanças de cores/tamanho na hora
                source "$APP_PATH/config.sh"
                CURSOR_P=0; CURSOR_A=0; OFFSET_P=0; OFFSET_A=0
            fi ;;

        $'\x1b') # SETAS E ESC
            FILTRO=""
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

        $'\t') # ALTERNAR COLUNAS
            [ "$FOCO" == "PASTAS" ] && FOCO="ARQUIVOS" || FOCO="PASTAS" ;;

        "") # ABRIR / ENTRAR
            if [ "$FOCO" == "PASTAS" ]; then
                ITEM=$(echo "${PASTAS[$CURSOR_P]}" | tr -d '*/')
                [ "$ITEM" == ".." ] && cd .. || cd "$ITEM"
                CURSOR_P=0; CURSOR_A=0; OFFSET_P=0; OFFSET_A=0
            else
                ARQ=$(echo "${ARQUIVOS[$CURSOR_A]}" | tr -d '*/')
                [ -n "$ARQ" ] && xdg-open "$ARQ" >/dev/null 2>&1 &
            fi ;;
        q|Q) cleanup ;;
    esac
done

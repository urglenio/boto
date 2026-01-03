#!/bin/bash
export LANG=pt_BR.UTF-8
export LC_ALL=pt_BR.UTF-8

# Função para repetir caracteres (resolve o problema do tr com UTF-8)
repetir() {
    local char="$1"
    local count="$2"
    local str=""
    for ((i=0; i<count; i++)); do str+="$char"; done
    echo -n "$str"
}

# --- CONFIGURAÇÃO DE CAMINHO ---
APP_PATH=$(dirname "$(readlink -f "$0")")

# --- FUNÇÃO DE SAÍDA ---
TERM_STATE=$(stty -g)
cleanup() {
    stty "$TERM_STATE"
    pwd > /tmp/boto_last_dir
    chmod 777 /tmp/boto_last_dir 2>/dev/null
    clear
    exit
}
trap cleanup SIGINT SIGTERM

# --- 1. CARREGAR IDENTIDADE E VERSÃO (PRIMEIRO DE TUDO) ---
[ -f "$APP_PATH/version.sh" ] && source "$APP_PATH/version.sh"

# --- 2. VERIFICAÇÃO DE UPDATE EM BACKGROUND ---
rm -f /tmp/boto_update_ready
(
    # Geramos um número aleatório para "enganar" o cache do GitHub
    CACHE_BUSTER=$(date +%s)
    REPO_VERSION_URL="https://raw.githubusercontent.com/urglenio/boto/main/version.sh?nocache=$CACHE_BUSTER"
    TMP_VERSION="/tmp/boto_remote_version.sh"

    # O parâmetro -L é essencial para seguir redirecionamentos
    curl -s -L -m 5 "$REPO_VERSION_URL" -o "$TMP_VERSION"

    if [ -f "$TMP_VERSION" ]; then
        # Extrai o build remoto e local limpando tudo que não for número
        REMOTE_BUILD=$(grep "BOTO_BUILD=" "$TMP_VERSION" | cut -d'"' -f2 | tr -dc '0-9')
        LOCAL_BUILD=$(echo "$BOTO_BUILD" | tr -dc '0-9')

        # DEBUG SILENCIOSO: Se quiser ver o que ele baixou, olhe o arquivo /tmp/boto_remote_version.sh
        if [ -n "$REMOTE_BUILD" ] && [ "$REMOTE_BUILD" -gt "$LOCAL_BUILD" ] 2>/dev/null; then
            touch /tmp/boto_update_ready
        fi
    fi
) &

# Pasta para dados que devem sobreviver a updates
DATA_DIR="$HOME/.config/boto"
mkdir -p "$DATA_DIR"
FAV_FILE="$DATA_DIR/favoritos.txt"
[ ! -f "$FAV_FILE" ] && touch "$FAV_FILE"

# --- 3. CARREGAR CORES E CONFIGURAÇÕES ---
BG_BLUE='\033[44m'; FG_WHITE='\033[37;1m'; FG_YELLOW='\033[33;1m'; FG_GREEN='\033[32;1m'
RESET='\033[0m'; HIGHLIGHT='\033[47;30m'; INFOBG='\033[40;37m'; FG_CYAN='\033[36;1m'
TL="+"; TR="+"; BL="+"; BR="+"; HL="-"; VL="|"; DIV="+"; B_DIV="+"
MAX_VIEW=15
COL_LARGURA=30

[ -f "$APP_PATH/config.sh" ] && source "$APP_PATH/config.sh"

# Variáveis de Navegação
CURSOR_P=0; CURSOR_A=0; OFFSET_P=0; OFFSET_A=0
FOCO="PASTAS"
FILTRO=""

mover_cursor() { printf "\033[%s;%sH" "$1" "$2"; }

# --- EXIBIR LOGO ---
if [ -f "$APP_PATH/logo.sh" ]; then
    bash "$APP_PATH/logo.sh"
    sleep 2
fi

while true; do
    NOME_PASTA_ATUAL=$(basename "$(pwd)")
    [ "$NOME_PASTA_ATUAL" == "/" ] && NOME_PASTA_ATUAL="RAIZ"

    # 1. COLETA DE DADOS
    LISTA_BRUTA=$(ls -1F --group-directories-first 2>/dev/null | grep -i "$FILTRO")
    PASTAS=("..")
    mapfile -t -O 1 PASTAS < <(echo "$LISTA_BRUTA" | grep '/$')
    mapfile -t ARQUIVOS < <(echo "$LISTA_BRUTA" | grep -v '/$')

    total_p=${#PASTAS[@]}; total_a=${#ARQUIVOS[@]}

    [ $CURSOR_P -ge $total_p ] && CURSOR_P=$((total_p - 1))
    [ $CURSOR_A -ge $total_a ] && CURSOR_A=$((total_a - 1))
    [ $CURSOR_P -lt 0 ] && CURSOR_P=0; [ $CURSOR_A -lt 0 ] && CURSOR_A=0

    clear

    # --- 1. CABEÇALHO COM NOTIFICAÇÃO DE UPDATE ---
    UPDATE_STYLE="${FG_WHITE}"
    AVISO_UPDATE=""
    if [ -f /tmp/boto_update_ready ]; then
        UPDATE_STYLE="\033[1;5;32m"
        AVISO_UPDATE=" [UPDATE DISPONÍVEL!] execute boto-update"
    fi

    LARGURA_TOTAL=$((COL_LARGURA * 2 + 5))
    printf "${BG_BLUE}${UPDATE_STYLE} 🐬 BOTO-FM v%-10s %s ${RESET}\n" "$BOTO_VERSION" "$AVISO_UPDATE"

# --- 2. BARRA DE NAVEGAÇÃO ---
    CAMINHO_ATUAL=$(pwd)
    IFACE_PATH="${CAMINHO_ATUAL}"
    # Ajuste para alinhar com a borda lateral
    MAX_PATH_LEN=$((LARGURA_TOTAL - 4))
    [ ${#IFACE_PATH} -gt $MAX_PATH_LEN ] && IFACE_PATH="...${IFACE_PATH: -$((MAX_PATH_LEN-3))}"
    printf "${HIGHLIGHT} 📂 %-${MAX_PATH_LEN}s ${RESET}\n" "$IFACE_PATH"

# --- 3. DESENHO DA JANELA ---
    printf "${BG_BLUE}${FG_WHITE}%s%s%s${RESET}\n" "$TL" "$(repetir "$HL" "$LARGURA_TOTAL")" "$TR"

    # Preparação dos Títulos
    TIT_P=" DIRETORIOS "; [ "$FOCO" == "PASTAS" ] && TIT_P="> DIRETORIOS <"

    # Título da Direita (Nome da Pasta Atual)
    FOLDER_LABEL="${NOME_PASTA_ATUAL:0:$((COL_LARGURA-4))}" # Corta se o nome for gigante
    TIT_A=" $FOLDER_LABEL "; [ "$FOCO" == "ARQUIVOS" ] && TIT_A="> $FOLDER_LABEL <"

    # Cálculo de espaços para alinhar com a VL (Vertical Line)
    # A largura interna de cada coluna é $COL_LARGURA + 1 (por causa do espaço da barra de rolagem)
    # Somamos +1 para manter o respiro interno original
    LARG_INTERNA=$((COL_LARGURA + 1))

    SP_TIT_P=$(( LARG_INTERNA - ${#TIT_P} ))
    SP_TIT_A=$(( LARG_INTERNA - ${#TIT_A} ))

    # Impressão dos Cabeçalhos com alinhamento fixo
    echo -ne "${BG_BLUE}${FG_WHITE}${VL} ${TIT_P}$(printf '%*s' $SP_TIT_P "")${VL} "
    echo -e "${TIT_A}$(printf '%*s' $SP_TIT_A "")${VL}${RESET}"

    # Divisória do meio
    printf "${BG_BLUE}${FG_WHITE}${VL}%s%s%s${VL}${RESET}\n" "$(repetir "$HL" $((COL_LARGURA+2)))" "$DIV" "$(repetir "$HL" $((COL_LARGURA+2)))"

 # --- 4. LISTAGEM ---
    for ((i=0; i<MAX_VIEW; i++)); do
        echo -ne "${BG_BLUE}${FG_WHITE}${VL} "

        # Coluna Pastas
        IDX_P=$((i + OFFSET_P))
        if [ $IDX_P -lt $total_p ]; then
            N_P="${PASTAS[$IDX_P]:0:$((COL_LARGURA-1))}" # Pega 1 caractere a menos para sobrar espaço para a barra
            SP_P=$(( (COL_LARGURA - 1) - ${#N_P} ))      # Ajusta o espaço de preenchimento

            if [ "$FOCO" == "PASTAS" ] && [ $IDX_P -eq $CURSOR_P ]; then
                echo -ne "${HIGHLIGHT}${N_P}$(printf '%*s' $SP_P "")${RESET}${BG_BLUE}${FG_WHITE}"
            else
                echo -ne "${FG_YELLOW}${N_P}${FG_WHITE}$(printf '%*s' $SP_P "")"
            fi

            # A barra de rolagem agora ocupa o último espaço fixo da coluna
            pos_p=$(( (CURSOR_P * (MAX_VIEW-1)) / (total_p > 1 ? total_p-1 : 1) ))
            [ $i -eq $pos_p ] && echo -ne "█" || echo -ne "░"
        else
            printf "%-${COL_LARGURA}s" ""
        fi

        echo -ne " ${VL} "

        # Coluna Arquivos
        IDX_A=$((i + OFFSET_A))
        if [ $IDX_A -lt $total_a ]; then
            N_A="${ARQUIVOS[$IDX_A]:0:$((COL_LARGURA-1))}" # Pega 1 caractere a menos
            SP_A=$(( (COL_LARGURA - 1) - ${#N_A} ))      # Ajusta o espaço

            if [ "$FOCO" == "ARQUIVOS" ] && [ $IDX_A -eq $CURSOR_A ]; then
                echo -ne "${HIGHLIGHT}${N_A}$(printf '%*s' $SP_A "")${RESET}${BG_BLUE}${FG_WHITE}"
            else
                echo -ne "${FG_GREEN}${N_A}${FG_WHITE}$(printf '%*s' $SP_A "")"
            fi

            # Barra de rolagem
            pos_a=$(( (CURSOR_A * (MAX_VIEW-1)) / (total_a > 1 ? total_a-1 : 1) ))
            [ $i -eq $pos_a ] && echo -ne "█" || echo -ne "░"
        else
            printf "%-${COL_LARGURA}s" ""
        fi
        echo -e " ${VL}${RESET}"
    done

    # --- 5. BORDA INFERIOR ---
    # Correção: Borda inferior usando 'repetir'
    printf "${BG_BLUE}${FG_WHITE}%s%s%s%s%s${RESET}\n" "$BL" "$(repetir "$HL" $((COL_LARGURA+2)))" "$B_DIV" "$(repetir "$HL" $((COL_LARGURA+2)))" "$BR"

    # --- 6. BARRA DE STATUS ---
    if [ -n "$FILTRO" ]; then
        echo -e "${HIGHLIGHT} BUSCANDO: $FILTRO (ESC para limpar) ${RESET}"
    else
        [ "$FOCO" == "PASTAS" ] && ALVO="${PASTAS[$CURSOR_P]}" || ALVO="${ARQUIVOS[$CURSOR_A]}"
        ALVO_LIMPO=$(echo "$ALVO" | tr -d '*/')
        if [ -n "$ALVO" ] && [ -e "$ALVO_LIMPO" ]; then
            PERM=$(stat -c '%A' "$ALVO_LIMPO")
            TAM=$([ -d "$ALVO_LIMPO" ] && echo "DIR" || ls -lh "$ALVO_LIMPO" | awk '{print $5}')
            echo -e "${INFOBG} PERM: $PERM | TAM: $TAM | DATA: $(stat -c '%y' "$ALVO_LIMPO" | cut -c1-16) ${RESET}"
        fi
    fi
    echo -e "${FG_CYAN} [/] Buscar [N] Pasta [M] Menu [C] Config [TAB] Lado [K] Ir para [V] Favoritos [Q] Sair ${RESET}"

    # --- 7. CAPTURA DE TECLAS ---
    stty -icanon -echo
    tecla=$(dd bs=1 count=1 2>/dev/null)
    stty "$TERM_STATE"

    case "$tecla" in
        "/")
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

        "n"|"N")
            printf "\033[1;1H\033[2K${FG_YELLOW} Nome da nova pasta: ${RESET}"
            stty echo icanon; read nova_pasta; stty -echo -icanon
            [ -n "$nova_pasta" ] && mkdir -p "$nova_pasta" ;;

        "m"|"M")
            [ "$FOCO" == "PASTAS" ] && ALVO_M=$(echo "${PASTAS[$CURSOR_P]}" | tr -d '*/') || ALVO_M=$(echo "${ARQUIVOS[$CURSOR_A]}" | tr -d '*/')
            [ -n "$ALVO_M" ] && [ "$ALVO_M" != ".." ] && bash "$APP_PATH/menu.sh" "$ALVO_M" ;;

"f"|"F") # ADICIONAR AOS FAVORITOS COM POPUP
            [ "$FOCO" == "PASTAS" ] && FAV_ALVO="${PASTAS[$CURSOR_P]}" || FAV_ALVO="${ARQUIVOS[$CURSOR_A]}"
            FAV_ALVO_LIMPO=$(readlink -f "$(echo "$FAV_ALVO" | tr -d '*/')")

            if [ -n "$FAV_ALVO_LIMPO" ] && [ "$FAV_ALVO" != ".." ]; then
                MSG="⭐ Adicionado aos Favoritos!"
                COR_MSG="${FG_GREEN}"

                if grep -qx "$FAV_ALVO_LIMPO" "$FAV_FILE"; then
                    MSG="⭐ Já está nos Favoritos!   "
                    COR_MSG="${FG_YELLOW}"
                else
                    echo "$FAV_ALVO_LIMPO" >> "$FAV_FILE"
                fi

                # --- DESENHO DO POPUP DE CONFIRMAÇÃO ---
                LARG_POP=$(( ${#MSG} + 5 ))
                COL_POP=$(( (LARGURA_TOTAL / 2) - (LARG_POP / 2) + 3 ))
                LIN_POP=10

                # Borda superior do balão
                mover_cursor $LIN_POP $COL_POP
                echo -e "${MENU_BG}┏$(repetir "━" $LARG_POP)┓${RESET}"

                # Conteúdo do balão
                mover_cursor $((LIN_POP+1)) $COL_POP
                echo -e "${MENU_BG}┃  ${COR_MSG}${MSG}${RESET}${MENU_BG}  ┃${RESET}"

                # Borda inferior do balão
                mover_cursor $((LIN_POP+2)) $COL_POP
                echo -e "${MENU_BG}┗$(repetir "━" $LARG_POP)┛${RESET}"

                sleep 1.2 # Tempo para o usuário ver a mensagem
            fi ;;

        "v"|"V") # CHAMA O GERENCIADOR DE FAVORITOS
            rm -f /tmp/boto_fav_result
            bash "$APP_PATH/fav_manager.sh"
            if [ -f /tmp/boto_fav_result ]; then
                RES_FAV=$(cat /tmp/boto_fav_result)
                if [ "$RES_FAV" != "REFRESH" ]; then
                    [ -d "$RES_FAV" ] && cd "$RES_FAV" || cd "$(dirname "$RES_FAV")"
                    CURSOR_P=0; CURSOR_A=0; OFFSET_P=0; OFFSET_A=0
                fi
                rm -f /tmp/boto_fav_result
            fi ;;

        "k"|"K")
            mover_cursor 2 1
            echo -ne "${BG_YELLOW}${FG_BLACK} IR PARA: ${RESET} "
            stty echo icanon
            read -e -i "$(pwd)/" destino
            stty -echo -icanon
            if [ -d "$destino" ]; then
                cd "$destino"
                CURSOR_P=0; CURSOR_A=0; OFFSET_P=0; OFFSET_A=0
            else
                mover_cursor 2 1
                echo -ne "${FG_RED} ❌ Caminho não encontrado! ${RESET}"
                sleep 0.8
            fi ;;

        "c"|"C")
            if [ -f "$APP_PATH/config_manager.sh" ]; then
                bash "$APP_PATH/config_manager.sh"
                source "$APP_PATH/config.sh"
                CURSOR_P=0; CURSOR_A=0; OFFSET_P=0; OFFSET_A=0
            fi ;;

        $'\x1b')
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

        $'\t') [ "$FOCO" == "PASTAS" ] && FOCO="ARQUIVOS" || FOCO="PASTAS" ;;

        "")
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

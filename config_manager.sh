#!/bin/bash

# --- CONFIGURAÇÃO DE CAMINHO ---
APP_PATH=$(dirname "$(readlink -f "$0")")

# Carrega configurações e informações de versão
[ -f "$APP_PATH/config.sh" ] && source "$APP_PATH/config.sh"
[ -f "$APP_PATH/version.sh" ] && source "$APP_PATH/version.sh"

# Função para salvar no arquivo config.sh
salvar_config() {
    cat <<EOF > "$APP_PATH/config.sh"
BG_BLUE='$BG_BLUE'
FG_WHITE='$FG_WHITE'
FG_YELLOW='$FG_YELLOW'
FG_GREEN='$FG_GREEN'
RESET='$RESET'
HIGHLIGHT='$HIGHLIGHT'
INFOBG='$INFOBG'
FG_CYAN='$FG_CYAN'
MENU_BG='$MENU_BG'
MAX_VIEW=$MAX_VIEW
COL_LARGURA=$COL_LARGURA
EDITOR_PADRAO='$EDITOR_PADRAO'
EOF
    echo -e "\n${FG_GREEN} ✔ Configurações salvas! ${RESET}"
    sleep 1
}

# Sub-menu de Cores
menu_cores() {
    clear
    echo -e "${FG_CYAN}=== AJUSTE DE CORES ===${RESET}"
    echo -e "[1] Azul Clássico"
    echo -e "[2] Modo Dark (Preto)"
    echo -e "[3] Matrix (Verde)"
    echo -e "[4] Manual (Código ANSI)"
    echo -e "[0] Voltar"
    echo -ne "\nEscolha: "
    read -n1 c_opt
    case $c_opt in
        1) BG_BLUE='\033[44m'; MENU_BG='\033[44;37m'; FG_WHITE='\033[37;1m' ;;
        2) BG_BLUE='\033[40m'; MENU_BG='\033[40;37m'; FG_WHITE='\033[37;1m' ;;
        3) BG_BLUE='\033[40m'; FG_WHITE='\033[32;1m'; MENU_BG='\033[40;32m' ;;
        4) echo -ne "\nDigite o código (ex: \033[45m): "; read BG_BLUE ;;
        *) return ;;
    esac
    salvar_config
}

# Sub-menu de Tamanho
menu_tamanho() {
    clear
    echo -e "${FG_CYAN}=== AJUSTE DE DIMENSÕES ===${RESET}"
    echo -e "Atual: Altura ${MAX_VIEW} | Largura ${COL_LARGURA}\n"
    echo -ne "Nova Altura: "; read MAX_VIEW
    echo -ne "Nova Largura: "; read COL_LARGURA
    [[ -z "$MAX_VIEW" ]] && MAX_VIEW=15
    [[ -z "$COL_LARGURA" ]] && COL_LARGURA=30
    salvar_config
}

# Sub-menu de Editor
menu_editor() {
    clear
    echo -e "${FG_CYAN}=== EDITOR PADRÃO ===${RESET}"
    echo -e "[1] Nano  [2] Vi  [3] Vim  [4] Personalizado"
    read -n1 e_opt
    case $e_opt in
        1) EDITOR_PADRAO='nano' ;;
        2) EDITOR_PADRAO='vi' ;;
        3) EDITOR_PADRAO='vim' ;;
        4) echo -ne "\nEditor: "; read EDITOR_PADRAO ;;
    esac
    salvar_config
}

# Sub-menu Sobre (Créditos e Versão)
menu_sobre() {
    clear
    echo -e "${FG_CYAN}=== SOBRE O BOTO-FM ===${RESET}"
    echo -e "Versão:  ${FG_YELLOW}$BOTO_VERSION${RESET}"
    echo -e "Autor:   $BOTO_AUTHOR"

    # Exibe Array de Colaboradores
    echo -ne "Colaboradores: ${FG_GREEN}"
    for i in "${!COLABORADORES[@]}"; do
        echo -ne "${COLABORADORES[$i]}"
        if [ $i -lt $((${#COLABORADORES[@]} - 1)) ]; then echo -ne ", "; fi
    done
    echo -e "${RESET}"

    echo -e "GitHub:  ${FG_CYAN}$BOTO_GITHUB${RESET}"
    echo -e "\n$BOTO_CREDITS"
    echo -e "\nPressione qualquer tecla para voltar..."
    read -n1
}

# --- LOOP DO MENU PRINCIPAL (O QUE FALTAVA) ---
while true; do
    clear
    echo -e "${BG_BLUE}${FG_WHITE}   CONFIGURAÇÕES BOTO-FM   ${RESET}"
    echo -e "---------------------------"
    echo -e "[1] Temas de Cores"
    echo -e "[2] Tamanho da Janela"
    echo -e "[3] Editor (Atual: $EDITOR_PADRAO)"
    echo -e "[4] Sobre / Créditos"
    echo -e "[0] Sair"
    echo -e "---------------------------"
    echo -ne "Escolha: "
    read -n1 principal_opt

    case $principal_opt in
        1) menu_cores ;;
        2) menu_tamanho ;;
        3) menu_editor ;;
        4) menu_sobre ;;
        0) exit 0 ;;
    esac
done

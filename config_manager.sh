#!/bin/bash

# --- CONFIGURAÇÃO DE CAMINHO ---
APP_PATH=$(dirname "$(readlink -f "$0")")

# Carrega as configurações atuais para ter os valores base
if [ -f "$APP_PATH/config.sh" ]; then
    source "$APP_PATH/config.sh"
fi

# Função para salvar no arquivo config.sh (Mantendo suas variáveis)
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
    echo -e "\n${FG_GREEN} ✔ Configurações salvas com sucesso! ${RESET}"
    sleep 1
}

# Sub-menu de Cores
menu_cores() {
    clear
    echo -e "${FG_CYAN}=== AJUSTE DE CORES ===${RESET}"
    echo -e "[1] Azul Clássico"
    echo -e "[2] Modo Dark (Preto)"
    echo -e "[3] Matrix (Verde)"
    echo -e "[4] Manual (Digitar código ANSI)"
    echo -e "[0] Voltar"
    echo -ne "\nEscolha uma opção: "
    read -n1 c_opt
    case $c_opt in
        1) BG_BLUE='\033[44m'; MENU_BG='\033[44;37m'; FG_WHITE='\033[37;1m' ;;
        2) BG_BLUE='\033[40m'; MENU_BG='\033[40;37m'; FG_WHITE='\033[37;1m' ;;
        3) BG_BLUE='\033[40m'; FG_WHITE='\033[32;1m'; MENU_BG='\033[40;32m' ;;
        4) echo -ne "\nDigite o código ANSI (ex: \033[45m): "; read BG_BLUE ;;
        *) return ;;
    esac
    salvar_config
}

# Sub-menu de Tamanho
menu_tamanho() {
    clear
    echo -e "${FG_CYAN}=== AJUSTE DE DIMENSÕES ===${RESET}"
    echo -e "Atual: Altura ${MAX_VIEW} | Largura ${COL_LARGURA}\n"
    echo -ne "Nova Altura (Linhas de arquivos): "; read MAX_VIEW
    echo -ne "Nova Largura (Largura das colunas): "; read COL_LARGURA

    # Validação simples para não quebrar a interface
    [[ -z "$MAX_VIEW" ]] && MAX_VIEW=15
    [[ -z "$COL_LARGURA" ]] && COL_LARGURA=30

    salvar_config
}

# Sub-menu de Editor
menu_editor() {
    clear
    echo -e "${FG_CYAN}=== EDITOR PADRÃO ===${RESET}"
    echo -e "[1] Nano"
    echo -e "[2] Vi"
    echo -e "[3] Vim"
    echo -e "[4] Personalizado"
    echo -ne "\nEscolha: "
    read -n1 e_opt
    case $e_opt in
        1) EDITOR_PADRAO='nano' ;;
        2) EDITOR_PADRAO='vi' ;;
        3) EDITOR_PADRAO='vim' ;;
        4) echo -ne "\nDigite o nome do editor: "; read EDITOR_PADRAO ;;
    esac
    salvar_config
}

# --- MENU PRINCIPAL DO GERENCIADOR ---
while true; do
    clear
    echo -e "${BG_BLUE}${FG_WHITE}   GERENCIADOR DE CONFIGURAÇÕES BOTO-FM   ${RESET}"
    echo -e "-------------------------------------------"
    echo -e "[1] Mudar Cores do Tema"
    echo -e "[2] Ajustar Tamanho da Janela"
    echo -e "[3] Mudar Editor Padrão (Atual: $EDITOR_PADRAO)"
    echo -e "[0] Sair e Aplicar"
    echo -e "-------------------------------------------"
    echo -ne "Escolha uma opção: "
    read -n1 principal_opt

    case $principal_opt in
        1) menu_cores ;;
        2) menu_tamanho ;;
        3) menu_editor ;;
        0) exit 0 ;;
    esac
done

#!/bin/bash

# Importa configurações de cores e variáveis
APP_PATH=$(dirname "$(readlink -f "$0")")
[ -f "$APP_PATH/config.sh" ] && source "$APP_PATH/config.sh"

ALVO="$1"
LINHA=4
COLUNA=15

# Atalhos de cores caso não existam no config.sh
RESET='\033[0m'
FG_CYAN='\033[36m'
FG_YELLOW='\033[33m'
FG_GREEN='\033[32m'
FG_RED='\033[31m'
MENU_BG='\033[40m' # Fundo preto para o menu

mover_cursor() { echo -ne "\033[$1;${2}H"; }

# 1. Desenho do Cabeçalho do Menu
mover_cursor $LINHA $COLUNA;      echo -e "${MENU_BG}┌────────────────────────────────┐${RESET}"
mover_cursor $((LINHA+1)) $COLUNA; echo -e "${MENU_BG}│ OPÇÕES: $(printf '%-22.22s' "$(basename "$ALVO")") │${RESET}"
mover_cursor $((LINHA+2)) $COLUNA; echo -e "${MENU_BG}├────────────────────────────────┤${RESET}"

# 2. Opções Condicionais (Arquivo vs Pasta)
if [ -f "$ALVO" ]; then
    mover_cursor $((LINHA+3)) $COLUNA; echo -e "${MENU_BG}│ [1] Abrir / Executar           │${RESET}"
    mover_cursor $((LINHA+4)) $COLUNA; echo -e "${MENU_BG}│ [2] Editar                     │${RESET}"
else
    mover_cursor $((LINHA+3)) $COLUNA; echo -e "${MENU_BG}│ [1] Entrar no Direitório       │${RESET}"
    mover_cursor $((LINHA+4)) $COLUNA; echo -e "${MENU_BG}│ [ ] ------------------         │${RESET}"
fi

# 3. Opções Gerais
mover_cursor $((LINHA+5)) $COLUNA; echo -e "${MENU_BG}│ [3] Renomear                   │${RESET}"
mover_cursor $((LINHA+6)) $COLUNA; echo -e "${MENU_BG}│ [4] COPIAR                     │${RESET}"
mover_cursor $((LINHA+7)) $COLUNA; echo -e "${MENU_BG}│ [5] MOVER                      │${RESET}"
mover_cursor $((LINHA+8)) $COLUNA; echo -e "${MENU_BG}│ [6] APAGAR                     │${RESET}"
mover_cursor $((LINHA+9)) $COLUNA; echo -e "${MENU_BG}│ [7] PERMISSÕES (chmod)         │${RESET}"
mover_cursor $((LINHA+10)) $COLUNA; echo -e "${MENU_BG}│ [0] Voltar                     │${RESET}"
mover_cursor $((LINHA+11)) $COLUNA; echo -e "${MENU_BG}└────────────────────────────────┘${RESET}"

mover_cursor $((LINHA+12)) $((COLUNA+2))
echo -ne "${FG_YELLOW}Escolha uma opção: ${RESET}"
read -rsn1 opcao

case $opcao in
    1)
        if [ -d "$ALVO" ]; then
            exit 0 # O script principal cuida da navegação
        else
            xdg-open "$ALVO" >/dev/null 2>&1 & clear
        fi
        ;;

    2)
        if [ -f "$ALVO" ]; then
            clear
            ${EDITOR_PADRAO:-nano} "$ALVO"
        fi
        ;;

    3)
        mover_cursor $((LINHA+13)) $COLUNA; echo -ne "${FG_CYAN} Novo nome: ${RESET}"
        stty echo; read -e -i "$ALVO" novo; stty -echo
        [ -n "$novo" ] && mv "$ALVO" "$novo"
        ;;

    4|5)
        # Lógica de Clipboard para Navegar e Colar
        ACAO="copy"
        [ "$opcao" == "5" ] && ACAO="move"

        # Salva o caminho absoluto e a ação em arquivos temporários
        readlink -f "$ALVO" > /tmp/boto_clipboard_path
        echo "$ACAO" > /tmp/boto_clipboard_action

        mover_cursor $((LINHA+13)) $COLUNA
        echo -e "${FG_GREEN} Marcado para $ACAO! Use [P] para colar.${RESET}"
        sleep 1.5
        ;;

    6)
        mover_cursor $((LINHA+13)) $COLUNA; echo -ne "${FG_RED} Apagar permanentemente? (s/n): ${RESET}"
        read -rsn1 conf
        [ "$conf" == "s" ] && rm -rf "$ALVO"
        ;;

    7)
        # --- SUBMENU DE PERMISSÕES ---
        P_LIN=6; P_COL=20
        mover_cursor $P_LIN $P_COL;      echo -e "${INFOBG}┌──────────────────────────────┐${RESET}"
        mover_cursor $((P_LIN+1)) $P_COL; echo -e "${INFOBG}│ CHMOD ATUAL: $(stat -c '%a' "$ALVO")           │${RESET}"
        mover_cursor $((P_LIN+2)) $P_COL; echo -e "${INFOBG}├──────────────────────────────┤${RESET}"
        mover_cursor $((P_LIN+3)) $P_COL; echo -e "${INFOBG}│ [1] Total (777)              │${RESET}"
        mover_cursor $((P_LIN+4)) $P_COL; echo -e "${INFOBG}│ [2] Padrão (644)             │${RESET}"
        mover_cursor $((P_LIN+5)) $P_COL; echo -e "${INFOBG}│ [3] Executável (755)         │${RESET}"
        mover_cursor $((P_LIN+6)) $P_COL; echo -e "${INFOBG}│ [4] Privado (600)            │${RESET}"
        mover_cursor $((P_LIN+7)) $P_COL; echo -e "${INFOBG}│ [5] Personalizado            │${RESET}"
        mover_cursor $((P_LIN+8)) $P_COL; echo -e "${INFOBG}└──────────────────────────────┘${RESET}"

        mover_cursor $((P_LIN+9)) $((P_COL+2)); echo -ne "${FG_YELLOW}Opção: ${RESET}"
        read -rsn1 perm_opt

        case $perm_opt in
            1) chmod 777 "$ALVO" ;;
            2) chmod 644 "$ALVO" ;;
            3) chmod 755 "$ALVO" ;;
            4) chmod 600 "$ALVO" ;;
            5) mover_cursor $((P_LIN+10)) $P_COL; echo -ne " Valor (ex: 700): "; read manual_perm
               [ -n "$manual_perm" ] && chmod "$manual_perm" "$ALVO" ;;
        esac
        ;;
    0|*)
        exit 0
        ;;
esac

clear

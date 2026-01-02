#!/bin/bash

# Importa as configurações usando o caminho absoluto para funcionar de qualquer lugar
APP_PATH=$(dirname "$(readlink -f "$0")")
if [ -f "$APP_PATH/config.sh" ]; then
    source "$APP_PATH/config.sh"
else
    # Fallback caso o config.sh não seja encontrado
    RESET='\033[0m'; MENU_BG='\033[44;37m'; FG_YELLOW='\033[33;1m'; FG_CYAN='\033[36;1m'; FG_GREEN='\033[32;1m'
fi

ALVO="$1"
LINHA=7
COLUNA=15

# Função para mover o cursor
mover() { echo -ne "\033[$1;${2}H"; }

# 1. DESENHO DO MENU
mover $LINHA $COLUNA;      echo -e "${MENU_BG}┌────────────────────────────────┐${RESET}"
mover $((LINHA+1)) $COLUNA; echo -e "${MENU_BG}│ OPÇÕES: ${ALVO:0:22} │${RESET}"
mover $((LINHA+2)) $COLUNA; echo -e "${MENU_BG}├────────────────────────────────┤${RESET}"
mover $((LINHA+3)) $COLUNA; echo -e "${MENU_BG}│ [1] Abrir / Executar (Padrão)  │${RESET}"
mover $((LINHA+4)) $COLUNA; echo -e "${MENU_BG}│ [2] Editar com NANO            │${RESET}"
mover $((LINHA+5)) $COLUNA; echo -e "${MENU_BG}│ [3] Renomear Arquivo           │${RESET}"
mover $((LINHA+6)) $COLUNA; echo -e "${MENU_BG}│ [4] Apagar Arquivo             │${RESET}"
mover $((LINHA+7)) $COLUNA; echo -e "${MENU_BG}│ [0] Voltar                     │${RESET}"
mover $((LINHA+8)) $COLUNA; echo -e "${MENU_BG}└────────────────────────────────┘${RESET}"

mover $((LINHA+9)) $((COLUNA+2))
echo -ne "${FG_YELLOW}Escolha: ${RESET}"
read -rsn1 opcao

case $opcao in
    1)
        # Abre com o programa padrão em segundo plano
        xdg-open "$ALVO" >/dev/null 2>&1 &
        clear
        ;;
    2)
        # Abre o editor de texto
        clear
        nano "$ALVO"
        ;;
    3)
        mover $((LINHA+10)) $COLUNA
        echo -ne "${FG_CYAN} Novo nome: ${RESET}"

        # Habilita edição do nome atual
        # -e habilita readline, -i insere o texto inicial
        stty echo
        read -e -i "$ALVO" novo_nome
        stty -echo

        if [ -n "$novo_nome" ] && [ "$novo_nome" != "$ALVO" ]; then
            mv "$ALVO" "$novo_nome"
            mover $((LINHA+11)) $COLUNA
            echo -ne "${FG_GREEN} ✔ Renomeado com sucesso! ${RESET}"
            sleep 0.8
        fi
        ;;
    4)
        mover $((LINHA+10)) $COLUNA
        echo -ne "${MENU_BG} Confirmar exclusão? (s/n) ${RESET}"
        read -rsn1 conf
        if [ "$conf" == "s" ]; then
            rm -rf "$ALVO"
            mover $((LINHA+11)) $COLUNA
            echo -ne "${FG_GREEN} ✔ Arquivo removido! ${RESET}"
            sleep 0.8
        fi
        ;;
    *)
        # Qualquer outra tecla apenas fecha o menu
        exit 0
        ;;
esac

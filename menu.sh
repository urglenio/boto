#!/bin/bash
# IMPORTANTE: Carregar o config usando o caminho absoluto para funcionar no /opt/boto
APP_PATH=$(dirname "$(readlink -f "$0")")
source "$APP_PATH/config.sh"

ALVO="$1"
LINHA=8
COLUNA=15

mover() { echo -ne "\033[$1;${2}H"; }

mover $LINHA $COLUNA;      echo -e "${MENU_BG}┌────────────────────────────────┐${RESET}"
mover $((LINHA+1)) $COLUNA; echo -e "${MENU_BG}│ OPÇÕES: ${ALVO:0:22} │${RESET}"
mover $((LINHA+2)) $COLUNA; echo -e "${MENU_BG}├────────────────────────────────┤${RESET}"
mover $((LINHA+3)) $COLUNA; echo -e "${MENU_BG}│ [1] Editar com NANO            │${RESET}"
mover $((LINHA+4)) $COLUNA; echo -e "${MENU_BG}│ [2] Editar com VI              │${RESET}"
mover $((LINHA+5)) $COLUNA; echo -e "${MENU_BG}│ [3] Apagar Arquivo             │${RESET}"
mover $((LINHA+6)) $COLUNA; echo -e "${MENU_BG}│ [0] Voltar                     │${RESET}"
mover $((LINHA+7)) $COLUNA; echo -e "${MENU_BG}└────────────────────────────────┘${RESET}"

mover $((LINHA+8)) $((COLUNA+2))
echo -ne "${FG_YELLOW}Escolha: ${RESET}"
read -rsn1 opcao

case $opcao in
    1) clear; nano "$ALVO" ;;
    2) clear; vi "$ALVO" ;;
    3)
       mover $((LINHA+9)) $COLUNA
       echo -ne "${MENU_BG} Confirmar exclusão? (s/n) ${RESET}"
       read -rsn1 conf
       if [ "$conf" == "s" ]; then
           rm -rf "$ALVO"
           mover $((LINHA+10)) $COLUNA
           echo -ne "${FG_GREEN} ✔ Arquivo removido! ${RESET}"
           sleep 0.5 # Pausa curta para o usuário ver a mensagem
       fi
       ;;
    *) exit ;;
esac

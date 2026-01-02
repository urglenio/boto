#!/bin/bash

APP_PATH=$(dirname "$(readlink -f "$0")")
source "$APP_PATH/config.sh"

ALVO="$1"
LINHA=6
COLUNA=15

mover_cursor() { echo -ne "\033[$1;${2}H"; }

# Desenho do Menu (Expandido para 6 opções)
mover_cursor $LINHA $COLUNA;      echo -e "${MENU_BG}┌────────────────────────────────┐${RESET}"
mover_cursor $((LINHA+1)) $COLUNA; echo -e "${MENU_BG}│ OPÇÕES: ${ALVO:0:22} │${RESET}"
mover_cursor $((LINHA+2)) $COLUNA; echo -e "${MENU_BG}├────────────────────────────────┤${RESET}"
mover_cursor $((LINHA+3)) $COLUNA; echo -e "${MENU_BG}│ [1] Abrir / Executar           │${RESET}"
mover_cursor $((LINHA+4)) $COLUNA; echo -e "${MENU_BG}│ [2] Editar com NANO            │${RESET}"
mover_cursor $((LINHA+5)) $COLUNA; echo -e "${MENU_BG}│ [3] Renomear                   │${RESET}"
mover_cursor $((LINHA+6)) $COLUNA; echo -e "${MENU_BG}│ [4] COPIAR para...             │${RESET}"
mover_cursor $((LINHA+7)) $COLUNA; echo -e "${MENU_BG}│ [5] MOVER para...              │${RESET}"
mover_cursor $((LINHA+8)) $COLUNA; echo -e "${MENU_BG}│ [6] APAGAR                     │${RESET}"
mover_cursor $((LINHA+9)) $COLUNA; echo -e "${MENU_BG}│ [0] Voltar                     │${RESET}"
mover_cursor $((LINHA+10)) $COLUNA; echo -e "${MENU_BG}└────────────────────────────────┘${RESET}"

mover_cursor $((LINHA+11)) $((COLUNA+2))
echo -ne "${FG_YELLOW}Escolha: ${RESET}"
read -rsn1 opcao

case $opcao in
    1) xdg-open "$ALVO" >/dev/null 2>&1 & clear ;;
    2) clear; nano "$ALVO" ;;
    3)
       mover_cursor $((LINHA+12)) $COLUNA
       echo -ne "${FG_CYAN} Novo nome: ${RESET}"
       stty echo
       read -e -i "$ALVO" novo_nome
       stty -echo
       [ -n "$novo_nome" ] && [ "$novo_nome" != "$ALVO" ] && mv "$ALVO" "$novo_nome"
       ;;
    4|5)
       # Lógica para Copiar (4) ou Mover (5)
       ACAO="COPIAR"; [ "$opcao" == "5" ] && ACAO="MOVER"

       # Lista subpastas para o usuário escolher como destino rápido
       SUBPASTAS=($(ls -d */ 2>/dev/null))

       mover_cursor $((LINHA+12)) $COLUNA; echo -e "${MENU_BG} Destino (TAB completa):        ${RESET}"
       mover_cursor $((LINHA+13)) $COLUNA; echo -e "${FG_WHITE} Sugestões: ${SUBPASTAS[*]:0:3}... ${RESET}"

       mover_cursor $((LINHA+14)) $COLUNA; echo -ne "${FG_CYAN} Para: ${RESET}"
       stty echo
       read -e -p "" destino
       stty -echo

       if [ -d "$destino" ]; then
           [ "$opcao" == "4" ] && cp -r "$ALVO" "$destino"
           [ "$opcao" == "5" ] && mv "$ALVO" "$destino"
           mover_cursor $((LINHA+15)) $COLUNA; echo -e "${FG_GREEN} ✔ Sucesso! ${RESET}"
           sleep 0.7
       else
           mover_cursor $((LINHA+15)) $COLUNA; echo -e "${FG_RED} ✖ Destino inválido! ${RESET}"
           sleep 1
       fi
       ;;
    6)
       mover_cursor $((LINHA+12)) $COLUNA; echo -ne "${MENU_BG} Confirmar exclusão? (s/n) ${RESET}"
       read -rsn1 conf
       [ "$conf" == "s" ] && rm -rf "$ALVO"
       ;;
    *) exit 0 ;;
esac

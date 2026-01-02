#!/bin/bash

APP_PATH=$(dirname "$(readlink -f "$0")")
[ -f "$APP_PATH/config.sh" ] && source "$APP_PATH/config.sh"

ALVO="$1"
LINHA=6
COLUNA=15

mover_cursor() { echo -ne "\033[$1;${2}H"; }

# Desenho do Menu
mover_cursor $LINHA $COLUNA;      echo -e "${MENU_BG}┌────────────────────────────────┐${RESET}"
mover_cursor $((LINHA+1)) $COLUNA; echo -e "${MENU_BG}│ OPÇÕES: ${ALVO:0:22} │${RESET}"
mover_cursor $((LINHA+2)) $COLUNA; echo -e "${MENU_BG}├────────────────────────────────┤${RESET}"

# Se for ARQUIVO, mostra Abrir e Editar. Se for PASTA, mostra apenas Entrar.
if [ -f "$ALVO" ]; then
    mover_cursor $((LINHA+3)) $COLUNA; echo -e "${MENU_BG}│ [1] Abrir / Executar           │${RESET}"
    mover_cursor $((LINHA+4)) $COLUNA; echo -e "${MENU_BG}│ [2] Editar com NANO            │${RESET}"
else
    mover_cursor $((LINHA+3)) $COLUNA; echo -e "${MENU_BG}│ [ ] ------------------         │${RESET}"
    mover_cursor $((LINHA+4)) $COLUNA; echo -e "${MENU_BG}│ [ ] ------------------         │${RESET}"
fi

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
    1) # Abrir ou Entrar
       if [ -d "$ALVO" ]; then exit 0; else xdg-open "$ALVO" >/dev/null 2>&1 & clear; fi ;;

    2) # Editar (Apenas se for arquivo)
       if [ -f "$ALVO" ]; then clear; nano "$ALVO"; fi ;;

    3) # Renomear
       mover_cursor $((LINHA+12)) $COLUNA; echo -ne "${FG_CYAN} Novo nome: ${RESET}"
       stty echo; read -e -i "$ALVO" novo; stty -echo
       [ -n "$novo" ] && mv "$ALVO" "$novo" ;;

    4|5) # Copiar ou Mover
       ACAO="COPIAR"; [ "$opcao" == "5" ] && ACAO="MOVER"
       mover_cursor $((LINHA+12)) $COLUNA; echo -ne "${FG_CYAN} Destino: ${RESET}"
       stty echo; read -e destino; stty -echo
       if [ -d "$destino" ]; then
           [ "$opcao" == "4" ] && cp -r "$ALVO" "$destino" || mv "$ALVO" "$destino"
           mover_cursor $((LINHA+13)) $COLUNA; echo -e "${FG_GREEN} ✔ Sucesso! ${RESET}"; sleep 0.7
       fi ;;

    6) # Apagar
       mover_cursor $((LINHA+12)) $COLUNA; echo -ne "${FG_RED} Apagar tudo? (s/n) ${RESET}"
       read -rsn1 conf
       [ "$conf" == "s" ] && rm -rf "$ALVO" ;;
    *) exit 0 ;;
esac

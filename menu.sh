#!/bin/bash

# Importa as configurações usando o caminho absoluto
APP_PATH=$(dirname "$(readlink -f "$0")")
source "$APP_PATH/config.sh"

ALVO="$1"
LINHA=7
COLUNA=15

# Função para mover o cursor
mover() { echo -ne "\033[$1;${2}H"; }

# Desenho do Menu (Aumentado para caber novas opções)
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
       # Abre com o programa padrão do sistema (xdg-open)
       # Redirecionamos erros para /dev/null para não quebrar a interface
       xdg-open "$ALVO" >/dev/null 2>&1 &
       clear
       ;;
    2)
       clear
       nano "$ALVO"
       ;;
    3)
       mover $((LINHA+10)) $COLUNA
       echo -ne "${FG_CYAN} Novo nome: ${RESET}"
       # Reativa o echo temporariamente para o usuário ver o que digita
       stty echo
       read novo_nome
       stty -echo
       if [ -n "$novo_nome" ]; then
           mv "$ALVO" "$novo_nome"
           mover $((LINHA+11)) $COLUNA
           echo -ne "${FG_GREEN} ✔ Renomeado! ${RESET}"
           sleep 0.7
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
           sleep 0.7
       fi
       ;;
    *) exit ;;
esac

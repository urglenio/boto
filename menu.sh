#!/bin/bash
source ./config.sh
ALVO="$1"

# Pega as dimensões do terminal para tentar centralizar (opcional)
# Mas aqui vamos usar uma posição fixa que caiba dentro da nossa janela azul
LINHA=8
COLUNA=15

# Função para mover o cursor: \033[Linha;ColunaH
mover() { echo -ne "\033[$1;${2}H"; }

# Desenhar o menu sobrepondo a tela atual
mover $LINHA $COLUNA;      echo -e "${MENU_BG}┌────────────────────────────────┐${RESET}"
mover $((LINHA+1)) $COLUNA; echo -e "${MENU_BG}│ OPÇÕES: ${ALVO:0:20} │${RESET}"
mover $((LINHA+2)) $COLUNA; echo -e "${MENU_BG}├────────────────────────────────┤${RESET}"
mover $((LINHA+3)) $COLUNA; echo -e "${MENU_BG}│ [1] Editar com NANO            │${RESET}"
mover $((LINHA+4)) $COLUNA; echo -e "${MENU_BG}│ [2] Editar com VI              │${RESET}"
mover $((LINHA+5)) $COLUNA; echo -e "${MENU_BG}│ [3] Apagar Arquivo             │${RESET}"
mover $((LINHA+6)) $COLUNA; echo -e "${MENU_BG}│ [0] Voltar                     │${RESET}"
mover $((LINHA+7)) $COLUNA; echo -e "${MENU_BG}└────────────────────────────────┘${RESET}"

# Posiciona o cursor para ler a opção logo abaixo do menu
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
       [ "$conf" == "s" ] && rm -rf "$ALVO"
       ;;
    *) exit ;;
esac

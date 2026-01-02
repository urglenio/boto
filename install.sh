#!/bin/bash
# Pega o caminho atual de onde os arquivos estão
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Dá permissão de execução aos arquivos
chmod +x "$DIR/main.sh"
chmod +x "$DIR/menu.sh"

# Cria um link simbólico no /usr/local/bin (atalho do sistema)
sudo ln -sf "$DIR/main.sh" /usr/local/bin/boto

echo "Instalação concluída! Agora você pode abrir o gerenciador digitando: boto"

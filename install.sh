#!/bin/bash

# Define a pasta de instalação
INSTALL_DIR="/opt/boto"
BIN_DIR="/usr/local/bin"

echo "🐬 Iniciando instalação do Boto File Manager..."

# 1. Cria a pasta de destino (precisa de sudo)
sudo mkdir -p "$INSTALL_DIR"

# 2. Copia todos os arquivos .sh e o config para /opt/boto
sudo cp main.sh menu.sh config.sh "$INSTALL_DIR/"

# 3. Dá permissão de execução
sudo chmod +x "$INSTALL_DIR/main.sh"
sudo chmod +x "$INSTALL_DIR/menu.sh"

# 4. Cria o comando principal 'boto'
# Usamos um link simbólico para o main.sh
sudo ln -sf "$INSTALL_DIR/main.sh" "$BIN_DIR/boto"

# 5. Cria o comando 'boto-update'
# Ele vai dar um 'git pull' dentro da pasta de instalação
cat <<EOF | sudo tee "$BIN_DIR/boto-update" > /dev/null
#!/bin/bash
echo "🐬 Atualizando o Boto..."
cd "$INSTALL_DIR" && sudo git pull
EOF

sudo chmod +x "$BIN_DIR/boto-update"

echo "✅ Instalação concluída!"
echo "Comandos disponíveis: 'boto' e 'boto-update'"

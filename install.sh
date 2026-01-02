#!/bin/bash

REPO_URL="https://github.com/urglenio/boto.git"
INSTALL_DIR="/opt/boto"
BIN_DIR="/usr/local/bin"

echo "🐬 Instalando/Atualizando o Boto File Manager..."

# 1. Remover instalação antiga para evitar conflitos
sudo rm -rf "$INSTALL_DIR"

# 2. Clona o repositório direto para /opt
sudo git clone "$REPO_URL" "$INSTALL_DIR"

# 3. Dá permissão de execução
sudo chmod +x "$INSTALL_DIR/main.sh"
sudo chmod +x "$INSTALL_DIR/menu.sh"

# 4. Cria o atalho 'boto'
sudo ln -sf "$INSTALL_DIR/main.sh" "$BIN_DIR/boto"

# 5. Cria o comando 'boto-update' robusto
cat <<EOF | sudo tee "$BIN_DIR/boto-update" > /dev/null
#!/bin/bash
echo "🐬 Verificando atualizações para o Boto..."
cd "$INSTALL_DIR"
# Configura a pasta como segura para o Git não reclamar do sudo
sudo git config --global --add safe.directory "$INSTALL_DIR"
sudo git pull
EOF

sudo chmod +x "$BIN_DIR/boto-update"

echo "✅ Pronto!"

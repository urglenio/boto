#!/bin/bash

REPO_URL="https://github.com/urglenio/boto.git"
INSTALL_DIR="/opt/boto"
BIN_DIR="/usr/local/bin"
DIRETORIO_ATUAL=$(pwd)

echo "🐬 Instalando/Atualizando o Boto-FM..."

# 1. Instalação padrão no /opt
sudo rm -rf "$INSTALL_DIR"
sudo git clone "$REPO_URL" "$INSTALL_DIR"
sudo chmod +x "$INSTALL_DIR/main.sh"
sudo chmod +x "$INSTALL_DIR/menu.sh"
sudo chmod +x "$INSTALL_DIR/logo.sh"
sudo chmod +x "$INSTALL_DIR/config.sh"

# 2. Criação dos links simbólicos
sudo ln -sf "$INSTALL_DIR/main.sh" "$BIN_DIR/boto-fm"

# 3. Criar comando de Update (Sem o comando de apagar!)
cat <<EOF | sudo tee "$BIN_DIR/boto-update" > /dev/null
#!/bin/bash
echo "🐬 Atualizando Boto-FM..."
cd "$INSTALL_DIR"
sudo git config --global --add safe.directory "$INSTALL_DIR"
sudo git pull
EOF
sudo chmod +x "$BIN_DIR/boto-update"

# 4. Criar o Desinstalador
cat <<EOF | sudo tee "$BIN_DIR/boto-uninstaller" > /dev/null
#!/bin/bash
sudo rm -rf "$INSTALL_DIR"
sudo rm -f "$BIN_DIR/boto-fm" "$BIN_DIR/boto-update" "$BIN_DIR/boto-uninstaller"
echo "✅ Boto-FM removido!"
EOF
sudo chmod +x "$BIN_DIR/boto-uninstaller"

echo "✅ Instalação concluída!"
echo "🚀 Use 'boto-fm' para abrir, 'boto-update' para atualizar ou 'boto-uninstaller' para remover."

# --- A TRAVA DE SEGURANÇA ---
# Só apaga a pasta se o diretório atual NÃO for /opt/boto e NÃO for sua pasta de dev
if [[ "$DIRETORIO_ATUAL" != "$INSTALL_DIR"* ]] && [[ "$DIRETORIO_ATUAL" != *"/opt/boto"* ]]; then
    echo "🧹 Limpando pasta temporária de instalação em: $DIRETORIO_ATUAL"
    # Agenda a remoção para 1 segundo após o script fechar para não dar erro de "arquivo em uso"
    (sleep 1; sudo rm -rf "$DIRETORIO_ATUAL") &
    echo "🚀 Tudo pronto! Pode fechar este terminal."
else
    echo "⚠️  Pasta de desenvolvimento ou sistema detectada. Limpeza automática ignorada."
fi

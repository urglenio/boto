#!/bin/bash

REPO_URL="https://github.com/urglenio/boto.git"
INSTALL_DIR="/opt/boto"
BIN_DIR="/usr/local/bin"
# Captura de onde o script está sendo executado agora
CURRENT_DIR=$(pwd)

echo "🐬 Instalando/Atualizando o Boto-FM..."

# 1. Limpeza de links físicos que bloqueiam a função
sudo rm -f "$BIN_DIR/boto"
sudo rm -f "$BIN_DIR/boto-fm"

# 2. Clona ou atualiza o repositório em /opt
sudo rm -rf "$INSTALL_DIR"
sudo git clone "$REPO_URL" "$INSTALL_DIR"

# 3. Permissões de execução e escrita
sudo chmod +x "$INSTALL_DIR/main.sh"
sudo chmod +x "$INSTALL_DIR/menu.sh"
sudo chmod +x "$INSTALL_DIR/logo.sh"
sudo chmod +x "$INSTALL_DIR/config_manager.sh"
sudo chmod +x "$INSTALL_DIR/version.sh"
sudo chmod 666 "$INSTALL_DIR/config.sh"

# 4. Cria o motor interno (binário real)
sudo ln -sf "$INSTALL_DIR/main.sh" "$BIN_DIR/boto-engine"

# 5. Injeta a função no .bashrc
sed -i '/# Boto-FM Start/,/# Boto-FM End/d' ~/.bashrc
echo '
# Boto-FM Start
boto-fm() {
    /usr/local/bin/boto-engine "$@"
    if [ -f /tmp/boto_last_dir ]; then
        cd "$(cat /tmp/boto_last_dir)"
        rm -f /tmp/boto_last_dir
    fi
}
# Boto-FM End' >> ~/.bashrc

# 6. Criar comando de atualização blindado
cat <<EOF | sudo tee "$BIN_DIR/boto-update" > /dev/null
#!/bin/bash
echo "🐬 Atualizando Boto-FM..."
cd "$INSTALL_DIR"
sudo git config --global --add safe.directory "$INSTALL_DIR"
sudo git fetch --all
sudo git reset --hard origin/main
sudo chmod 666 "$INSTALL_DIR/config.sh"
rm -f /tmp/boto_update_ready /tmp/boto_remote_version.sh
echo "✅ Atualizado com sucesso!"
EOF
sudo chmod +x "$BIN_DIR/boto-update"

# 7. Link de fallback e limpeza de cache
sudo ln -sf "$INSTALL_DIR/main.sh" "$BIN_DIR/boto-fm"
hash -r 2>/dev/null

echo "✅ Instalação concluída!"

# --- LÓGICA DE AUTO-LIMPEZA SEGURA ---
# Se a pasta atual NÃO for a pasta oficial de instalação (/opt/boto)
if [ "$CURRENT_DIR" != "$INSTALL_DIR" ]; then
    echo "🧹 Limpando arquivos temporários de instalação..."
    # Vai para a pasta pai, espera 1 segundo e remove a pasta de onde veio
    cd ..
    # Remove a pasta de download (apenas se o nome da pasta for 'boto')
    if [[ "$CURRENT_DIR" == *"boto"* ]]; then
        rm -rf "$CURRENT_DIR" &>/dev/null
    fi
fi

echo "🚀 Use 'boto-fm' para abrir. (Se nao funcionar, digite: source ~/.bashrc)"
echo "🚀 Use 'boto-uninstaller' para remover ou 'boto-update' para atualizar."

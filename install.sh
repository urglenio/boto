#!/bin/bash

REPO_URL="https://github.com/urglenio/boto.git"
INSTALL_DIR="/opt/boto"
BIN_DIR="/usr/local/bin"

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
# Garante que o usuário comum possa salvar cores e tamanhos no config.sh
sudo chmod 666 "$INSTALL_DIR/config.sh"

# 4. Cria o motor interno (binário real)
sudo ln -sf "$INSTALL_DIR/main.sh" "$BIN_DIR/boto-engine"

# 5. Injeta a função no .bashrc para futuras sessões
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

# 6. MÁGICA PARA FUNCIONAR AGORA: Injeta a função na sessão atual
# (Nota: export -f funciona em subshells, mas o usuário deve rodar source ou reiniciar para o cd funcionar 100%)
boto-fm() {
    /usr/local/bin/boto-engine "$@"
    if [ -f /tmp/boto_last_dir ]; then
        cd "$(cat /tmp/boto_last_dir)"
        rm -f /tmp/boto_last_dir
    fi
}
export -f boto-fm

# 7. Criar comando de atualização blindado (corrige o erro de merge)
cat <<EOF | sudo tee "$BIN_DIR/boto-update" > /dev/null
#!/bin/bash
echo "🐬 Atualizando Boto-FM..."
cd "$INSTALL_DIR"
sudo git config --global --add safe.directory "$INSTALL_DIR"
# Força o descarte de qualquer mudança local para evitar conflitos
sudo git fetch --all
sudo git reset --hard origin/main
# Garante que as permissões de escrita no config continuem após o update
sudo chmod 666 "$INSTALL_DIR/config.sh"
echo "✅ Atualizado com sucesso!"
EOF
sudo chmod +x "$BIN_DIR/boto-update"

# 8. Script do Desinstalador (Extra para manter o sistema limpo)
cat <<EOF | sudo tee "$BIN_DIR/boto-uninstaller" > /dev/null
#!/bin/bash
echo "🗑️ Removendo Boto-FM..."
sudo rm -rf "$INSTALL_DIR"
sudo rm -f "$BIN_DIR/boto-engine" "$BIN_DIR/boto-update" "$BIN_DIR/boto-fm" "$BIN_DIR/boto-uninstaller"
sed -i '/# Boto-FM Start/,/# Boto-FM End/d' ~/.bashrc
echo "✅ Removido com sucesso!"
EOF
sudo chmod +x "$BIN_DIR/boto-uninstaller"

# 9. Link de fallback e limpeza de cache
sudo ln -sf "$INSTALL_DIR/main.sh" "$BIN_DIR/boto-fm"
hash -r 2>/dev/null

echo "✅ Instalação concluída!"
echo "🚀 IMPORTANTE: Digite 'source ~/.bashrc' para ativar o 'cd' automático agora."
echo "🚀 Use 'boto-fm' para abrir ou 'boto-update' para atualizar."

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

# 3. Permissões de execução
sudo chmod +x "$INSTALL_DIR/main.sh"
sudo chmod +x "$INSTALL_DIR/menu.sh"
sudo chmod +x "$INSTALL_DIR/logo.sh"

# 4. Cria o motor interno (binário real)
sudo ln -sf "$INSTALL_DIR/main.sh" "$BIN_DIR/boto-engine"

# 5. Injeta a função no .bashrc para futuras sessões
# Remove versões anteriores para não duplicar
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
# Definimos a função diretamente para o shell que está rodando o instalador
boto-fm() {
    /usr/local/bin/boto-engine "$@"
    if [ -f /tmp/boto_last_dir ]; then
        cd "$(cat /tmp/boto_last_dir)"
        rm -f /tmp/boto_last_dir
    fi
}
# Exporta a função para que ela seja visível
export -f boto-fm

# 7. Criar comandos auxiliares
cat <<EOF | sudo tee "$BIN_DIR/boto-update" > /dev/null
#!/bin/bash
echo "🐬 Atualizando Boto-FM..."
cd "$INSTALL_DIR"
sudo git config --global --add safe.directory "$INSTALL_DIR"
sudo git pull
# Tenta atualizar a função na sessão atual
source ~/.bashrc 2>/dev/null
EOF
sudo chmod +x "$BIN_DIR/boto-update"

# 7. MÁGICA ADICIONAL: Criamos um link temporário para evitar o erro "Arquivo inexistente"
# Assim, se a função do .bashrc não carregar na hora, o link assume o trabalho.
sudo ln -sf "$INSTALL_DIR/main.sh" "$BIN_DIR/boto-fm"

# 8. Limpa o cache de comandos do usuário atual
hash -r 2>/dev/null

echo "✅ Instalação concluída!"
echo "🚀 Use 'boto-fm' para abrir, 'boto-update' para atualizar ou 'boto-uninstaller' para remover."

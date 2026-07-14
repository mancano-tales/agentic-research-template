#!/usr/bin/env bash
# ==============================================================================
# setup.sh — Configuração de Links de Governança Humano-IA (Linux/macOS)
#
# Uso:
#   chmod +x setup.sh
#   ./setup.sh
# ==============================================================================

# Detecção de Git Bash no Windows (MSYS/Cygwin)
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    echo "⚠ [AVISO] Detectado ambiente Git Bash / Windows."
    echo "  Recomenda-se executar o './setup.ps1' no PowerShell como Administrador"
    echo "  para garantir a criação correta de junctions NTFS e links físicos."
    echo "------------------------------------------------------------------------"
fi

# Verificar se Rscript está no PATH
if ! command -v Rscript &> /dev/null; then
    echo "⚠ [AVISO] 'Rscript' (interpretador do R) não foi encontrado no PATH do sistema!"
    echo "  Este template necessita do R instalado para executar a validação de governança."
    echo "  Por favor, instale o R (https://cran.r-project.org/) e adicione-o ao seu PATH."
    echo "------------------------------------------------------------------------"
fi

echo "🚀 Configurando links e junctions para agentes de IA..."

# 1. Criar Hard Link para AGENTS.md (OpenAI/Codex)
if [ ! -f AGENTS.md ]; then
    if [ -f CLAUDE.md ]; then
        ln CLAUDE.md AGENTS.md 2>/dev/null || cp CLAUDE.md AGENTS.md
        echo "  - Link AGENTS.md -> CLAUDE.md criado com sucesso."
    else
        echo "  - ERRO: CLAUDE.md não encontrado na raiz."
    fi
else
    echo "  - AGENTS.md já existe."
fi

# 2. Criar Symlink para a pasta de customizações (.agents -> .claude)
if [ ! -d .agents ] && [ ! -L .agents ]; then
    if [ -d .claude ]; then
        ln -s .claude .agents
        echo "  - Symlink .agents -> .claude criado com sucesso."
    else
        mkdir -p .claude/skills
        ln -s .claude .agents
        echo "  - Pasta .claude criada e symlink .agents -> .claude criado."
    fi
else
    echo "  - Diretório/Link .agents já existe."
fi

# 3. Criar Hard Link para .github/copilot-instructions.md (GitHub Copilot)
if [ -f CLAUDE.md ]; then
    mkdir -p .github
    if [ ! -f .github/copilot-instructions.md ]; then
        ln CLAUDE.md .github/copilot-instructions.md 2>/dev/null || cp CLAUDE.md .github/copilot-instructions.md
        echo "  - Link .github/copilot-instructions.md -> CLAUDE.md criado com sucesso."
    else
        echo "  - .github/copilot-instructions.md já existe."
    fi
fi

# 4. Configurar Git Hooks via core.hooksPath se a pasta .git existir
if [ -d .git ]; then
    git config core.hooksPath hooks
    echo "  - Git hooks configurados via 'core.hooksPath = hooks'."
    
    # Limpeza de eventuais hooks órfãos antigos
    if [ -f .git/hooks/pre-commit ]; then
        rm -f .git/hooks/pre-commit
        echo "  - Limpo hook antigo em .git/hooks/pre-commit."
    fi
    if [ -f .git/hooks/post-merge ]; then
        rm -f .git/hooks/post-merge
        echo "  - Limpo hook antigo em .git/hooks/post-merge."
    fi
fi

echo "------------------------------------------------------------------------"
echo "⚠ [AVISO DE CUIDADO] Editores como VS Code / Obsidian com 'Atomic Save' habilitado,"
echo "  e clientes de sincronização de nuvem (Dropbox/OneDrive/Google Drive/iCloud),"
echo "  podem quebrar Hard Links físicos ao salvar arquivos. Caso eles divirjam,"
echo "  execute este script novamente para restaurar os links."
echo "------------------------------------------------------------------------"
echo "💡 Git Hooks úteis de validação automática foram configurados para rodar a partir de 'hooks/'."
echo "------------------------------------------------------------------------"
echo "✅ Configuração concluída com sucesso!"

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
    echo "  Recomenda-se executar o './setup.ps1' no PowerShell"
    echo "  para garantir a criação correta da junction NTFS .agents -> .claude."
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

# 1. Garantir que CLAUDE.md seja apenas o ponteiro para AGENTS.md
#    AGENTS.md e o arquivo real e unico de instrucoes. Sem hard link: as copias
#    espelhadas foram eliminadas em 2026-07-29 porque Claude Code, Copilot e
#    Cursor leem o padrao aberto AGENTS.md diretamente.
if [ ! -f AGENTS.md ]; then
    echo "  - AVISO: AGENTS.md não encontrado na raiz. É o arquivo de instruções principal."
else
    pointer="@AGENTS.md"
    current=""
    [ -f CLAUDE.md ] && current=$(tr -d '[:space:]' < CLAUDE.md)
    if [ "$current" = "$pointer" ]; then
        echo "  - CLAUDE.md já é o ponteiro."
    elif [ ${#current} -gt 40 ]; then
        echo "  - AVISO: CLAUDE.md tem conteúdo próprio e NÃO foi tocado."
        echo "    Migre-o para AGENTS.md e deixe apenas '@AGENTS.md'."
    else
        printf '@AGENTS.md
' > CLAUDE.md
        echo "  - CLAUDE.md definido como ponteiro '@AGENTS.md'."
    fi
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
echo "💡 AGENTS.md é o único arquivo de instruções. CLAUDE.md é só o ponteiro '@AGENTS.md'."
echo "------------------------------------------------------------------------"
echo "💡 Git Hooks úteis de validação automática foram configurados para rodar a partir de 'hooks/'."
echo "------------------------------------------------------------------------"
echo "✅ Configuração concluída com sucesso!"

<#
.SYNOPSIS
    setup.ps1 — Configuração de Links de Governança Humano-IA (Windows)
.DESCRIPTION
    Executa a criação física da junção de diretório .agents apontando para .claude
    e garante que CLAUDE.md seja o ponteiro '@AGENTS.md'.
    NÃO cria hard links: AGENTS.md é o arquivo real e único (WP1/WP2, 2026-07-29).
.EXAMPLE
    .\setup.ps1
#>

# Verificar sistema de arquivos NTFS
$drive = Split-Path -Path $PSScriptRoot -Qualifier
if ($drive -match '^[A-Za-z]:$') {
    try {
        $fs = (Get-Volume -DriveLetter $drive.Replace(":", "")).FileSystem
        if ($fs -ne "NTFS") {
            Write-Warning "⚠ [AVISO] O sistema de arquivos detectado em $drive é '$fs' (Não NTFS)."
            Write-Warning "  Junctions requerem sistema NTFS para funcionar corretamente."
            Write-Warning "  Pode ocorrer falha ao tentar criar os links abaixo."
            Write-Host "------------------------------------------------------------------------"
        }
    } catch {
        Write-Warning "⚠ [AVISO] Não foi possível verificar o sistema de arquivos em $drive."
    }
}

# Verificar se Rscript está no PATH
$hasR = Get-Command Rscript -ErrorAction SilentlyContinue
if (-not $hasR) {
    Write-Warning "⚠ [AVISO] 'Rscript' (interpretador do R) não foi encontrado no PATH do sistema!"
    Write-Warning "  Este template necessita do R instalado para executar a validação de governança."
    Write-Warning "  Por favor, instale o R (https://cran.r-project.org/) e adicione-o ao seu PATH."
    Write-Host "------------------------------------------------------------------------"
}

Write-Host "🚀 Configurando links e junctions para agentes de IA..." -ForegroundColor Cyan

# 1. Garantir que CLAUDE.md seja apenas o ponteiro para AGENTS.md
#    AGENTS.md e o arquivo real e unico de instrucoes. Sem hard link: as tres
#    copias espelhadas (AGENTS.md, copilot-instructions.md) foram eliminadas em
#    2026-07-29 porque Claude Code, Copilot e Cursor leem AGENTS.md diretamente.
if (-not (Test-Path -Path "AGENTS.md" -PathType Leaf)) {
    Write-Warning "  - AGENTS.md não encontrado na raiz. Este é o arquivo de instruções principal."
} else {
    $pointer = "@AGENTS.md"
    $current = if (Test-Path -Path "CLAUDE.md" -PathType Leaf) { (Get-Content "CLAUDE.md" -Raw).Trim() } else { $null }
    if ($current -ne $pointer) {
        if ($null -ne $current -and $current.Length -gt 40) {
            Write-Warning "  - CLAUDE.md tem conteúdo próprio e NÃO foi tocado. Migre-o para AGENTS.md e deixe apenas @AGENTS.md."
        } else {
            Set-Content -Path "CLAUDE.md" -Value $pointer -Encoding utf8 -NoNewline
            Write-Host "  - CLAUDE.md definido como ponteiro @AGENTS.md." -ForegroundColor Green
        }
    } else {
        Write-Host "  - CLAUDE.md já é o ponteiro." -ForegroundColor Yellow
    }
}

# 2. Criar NTFS Directory Junction (.agents -> .claude)
if (-not (Test-Path -Path ".agents")) {
    if (-not (Test-Path -Path ".claude")) {
        New-Item -ItemType Directory -Path ".claude/skills" -Force | Out-Null
    }
    # Criar junção usando New-Item
    New-Item -ItemType Junction -Path ".agents" -Value ".claude" | Out-Null
    Write-Host "  - Junção NTFS .agents -> .claude criada." -ForegroundColor Green
} else {
    Write-Host "  - Diretório/Link .agents já existe." -ForegroundColor Yellow
}


# 4. Configurar Git Hooks via core.hooksPath se a pasta .git existir
if (Test-Path -Path ".git" -PathType Container) {
    git config core.hooksPath hooks
    Write-Host "  - Git hooks configurados via 'core.hooksPath = hooks'." -ForegroundColor Green
    
    # Limpeza de eventuais hooks órfãos antigos
    if (Test-Path -Path ".git/hooks/pre-commit" -PathType Leaf) {
        Remove-Item -Path ".git/hooks/pre-commit" -Force
        Write-Host "  - Limpo hook antigo em .git/hooks/pre-commit." -ForegroundColor DarkGray
    }
    if (Test-Path -Path ".git/hooks/post-merge" -PathType Leaf) {
        Remove-Item -Path ".git/hooks/post-merge" -Force
        Write-Host "  - Limpo hook antigo em .git/hooks/post-merge." -ForegroundColor DarkGray
    }
}

Write-Host "------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "💡 AGENTS.md é o único arquivo de instruções. CLAUDE.md é só o ponteiro @AGENTS.md." -ForegroundColor Cyan
Write-Host "------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "💡 Git Hooks úteis de validação automática foram configurados para rodar a partir de 'hooks/'." -ForegroundColor Cyan
Write-Host "------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "✅ Configuração concluída com sucesso!" -ForegroundColor Green


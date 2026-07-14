<#
.SYNOPSIS
    setup.ps1 — Configuração de Links de Governança Humano-IA (Windows)
.DESCRIPTION
    Executa a criação física da junção de diretório .agents apontando para .claude,
    e do hard link de AGENTS.md apontando para CLAUDE.md.
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
            Write-Warning "  Junctions e Hard Links requerem sistema NTFS para funcionar corretamente."
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

# 1. Criar Hard Link para AGENTS.md (OpenAI/Codex)
if (-not (Test-Path -Path "AGENTS.md" -PathType Leaf)) {
    if (Test-Path -Path "CLAUDE.md" -PathType Leaf) {
        # Criar hard link via cmd para ampla compatibilidade no Windows
        cmd /c mklink /h AGENTS.md CLAUDE.md
        Write-Host "  - Hard link AGENTS.md -> CLAUDE.md criado." -ForegroundColor Green
    } else {
        Write-Warning "  - CLAUDE.md não encontrado na raiz."
    }
} else {
    Write-Host "  - AGENTS.md já existe." -ForegroundColor Yellow
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

# 3. Criar Hard Link para .github/copilot-instructions.md (GitHub Copilot)
if (Test-Path -Path "CLAUDE.md" -PathType Leaf) {
    if (-not (Test-Path -Path ".github" -PathType Container)) {
        New-Item -ItemType Directory -Path ".github" -Force | Out-Null
    }
    if (-not (Test-Path -Path ".github/copilot-instructions.md" -PathType Leaf)) {
        cmd /c mklink /h .github\copilot-instructions.md CLAUDE.md
        Write-Host "  - Hard link .github/copilot-instructions.md -> CLAUDE.md criado." -ForegroundColor Green
    } else {
        Write-Host "  - .github/copilot-instructions.md já existe." -ForegroundColor Yellow
    }
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
Write-Host "⚠ [AVISO DE CUIDADO] Editores como VS Code / Obsidian com 'Atomic Save' habilitado," -ForegroundColor Yellow
Write-Host "  e clientes de sincronização de nuvem (Dropbox/OneDrive/Google Drive/iCloud)," -ForegroundColor Yellow
Write-Host "  podem deletar e recriar arquivos ao salvar, o que quebra o Hard Link físico." -ForegroundColor Yellow
Write-Host "  Se AGENTS.md e CLAUDE.md divergirem em tamanho, re-execute este script." -ForegroundColor Yellow
Write-Host "------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "💡 Git Hooks úteis de validação automática foram configurados para rodar a partir de 'hooks/'." -ForegroundColor Cyan
Write-Host "------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "✅ Configuração concluída com sucesso!" -ForegroundColor Green


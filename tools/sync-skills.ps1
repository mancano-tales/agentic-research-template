<#
.SYNOPSIS
    sync-skills.ps1 — Sincronização de skills de governança a partir do repositório mãe (Windows)
.DESCRIPTION
    Compara as skills locais (.claude/skills/*) com as do repositório mãe (por padrão,
    a pasta irmã 'agentic-research-template') e reporta o que está desatualizado ou
    faltando. Por padrão roda em modo dry-run (só relatório) — nada é escrito no disco
    sem -Apply. Nunca commita: só deixa a mudança no working tree, para revisão e
    'git add' explícito (Strict Staging Policy).
.PARAMETER Apply
    Nome de uma skill específica para puxar da mãe, ou 'all' para puxar todas as que
    estiverem desatualizadas ou faltando. Sem este parâmetro, roda só o relatório.
.PARAMETER SourcePath
    Caminho explícito para o repositório mãe, sobrepondo a detecção automática
    (pasta irmã 'agentic-research-template', ou o conteúdo de tools/.skills-source).
.EXAMPLE
    .\tools\sync-skills.ps1
.EXAMPLE
    .\tools\sync-skills.ps1 -Apply request-audit
.EXAMPLE
    .\tools\sync-skills.ps1 -Apply all
#>
param(
    [string]$Apply = "",
    [string]$SourcePath = ""
)

$RepoRoot = (Get-Item $PSScriptRoot).Parent.FullName

# 1. Resolver o caminho do repositório mãe
function Resolve-SkillsSource {
    param([string]$Override)
    if ($Override -ne "") { return $Override }

    $configFile = Join-Path $PSScriptRoot ".skills-source"
    if (Test-Path -Path $configFile -PathType Leaf) {
        $configured = (Get-Content -Path $configFile -TotalCount 1).Trim()
        if ($configured -ne "") { return $configured }
    }

    # Padrão: pasta irmã "agentic-research-template"
    $siblingDir = Split-Path -Path $RepoRoot -Parent
    return (Join-Path $siblingDir "agentic-research-template")
}

$SourceRoot = Resolve-SkillsSource -Override $SourcePath

if ((Resolve-Path $SourceRoot -ErrorAction SilentlyContinue).Path -eq (Resolve-Path $RepoRoot -ErrorAction SilentlyContinue).Path) {
    Write-Host "Este repositorio JA E o repositorio mae (agentic-research-template) - nada para sincronizar aqui." -ForegroundColor Cyan
    Write-Host "   Se você melhorou uma skill localmente, edite-a direto em .claude/skills/ e commit normalmente." -ForegroundColor Cyan
    exit 0
}

$SourceSkillsDir = Join-Path $SourceRoot ".claude\skills"
if (-not (Test-Path -Path $SourceSkillsDir -PathType Container)) {
    Write-Warning "⚠ [ERRO] Repositório mãe não encontrado ou sem .claude/skills em: $SourceRoot"
    Write-Warning "   Ajuste com -SourcePath, ou crie tools/.skills-source com o caminho correto (uma linha)."
    exit 1
}

$LocalSkillsDir = Join-Path $RepoRoot ".claude\skills"
if (-not (Test-Path -Path $LocalSkillsDir -PathType Container)) {
    New-Item -ItemType Directory -Path $LocalSkillsDir -Force | Out-Null
}

# 2. Comparar cada skill da mãe com a versão local (hash do SKILL.md)
Write-Host "🔄 Comparando skills locais com a mãe em: $SourceRoot" -ForegroundColor Cyan
Write-Host ""

$motherSkills = Get-ChildItem -Path $SourceSkillsDir -Directory
$toApply = @()

foreach ($skill in $motherSkills) {
    $name = $skill.Name
    $motherFile = Join-Path $skill.FullName "SKILL.md"
    if (-not (Test-Path -Path $motherFile -PathType Leaf)) { continue }

    $localFile = Join-Path $LocalSkillsDir "$name\SKILL.md"
    $motherHash = (Get-FileHash -Path $motherFile -Algorithm SHA256).Hash

    if (-not (Test-Path -Path $localFile -PathType Leaf)) {
        Write-Host ("  {0,-28} NOVA (não instalada)" -f $name) -ForegroundColor Yellow
        $toApply += @{ Name = $name; Status = "nova" }
    } else {
        $localHash = (Get-FileHash -Path $localFile -Algorithm SHA256).Hash
        if ($localHash -eq $motherHash) {
            Write-Host ("  {0,-28} em dia" -f $name) -ForegroundColor Green
        } else {
            Write-Host ("  {0,-28} desatualizada" -f $name) -ForegroundColor Yellow
            $toApply += @{ Name = $name; Status = "desatualizada" }
        }
    }
}

Write-Host ""

# 3. Aplicar, se pedido
if ($Apply -eq "") {
    if ($toApply.Count -gt 0) {
        Write-Host "Rode com -Apply <nome-da-skill> ou -Apply all para puxar as atualizações acima." -ForegroundColor Cyan
        Write-Host "Nada foi escrito no disco (modo relatório)." -ForegroundColor DarkGray
    }
    exit 0
}

$targets = if ($Apply -eq "all") { $toApply } else { $toApply | Where-Object { $_.Name -eq $Apply } }

if ($targets.Count -eq 0) {
    Write-Host "Nada a aplicar para '$Apply' (já está em dia, ou não existe na mãe)." -ForegroundColor Yellow
    exit 0
}

foreach ($t in $targets) {
    $src = Join-Path $SourceSkillsDir "$($t.Name)\SKILL.md"
    $destDir = Join-Path $LocalSkillsDir $t.Name
    if (-not (Test-Path -Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    $dest = Join-Path $destDir "SKILL.md"
    Copy-Item -Path $src -Destination $dest -Force
    Write-Host "  ✅ '$($t.Name)' copiada da mãe." -ForegroundColor Green
}

Write-Host ""
Write-Host "⚠ Nada foi commitado. Revise o diff e faça 'git add' explícito (arquivo por arquivo) antes de commitar." -ForegroundColor Yellow

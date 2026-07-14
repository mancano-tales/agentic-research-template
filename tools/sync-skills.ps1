<#
.SYNOPSIS
    sync-skills.ps1 — Sincronização de skills de governança a partir do repositório mãe (Windows)
.DESCRIPTION
    Compara as skills locais (.claude/skills/*) com as do repositório mãe (por padrão,
    a pasta irmã 'agentic-research-template') e reporta o que está desatualizado ou
    faltando. Compara a PASTA inteira de cada skill (SKILL.md e quaisquer arquivos
    auxiliares, ex.: scripts/), não só o SKILL.md — skills como pdf-text-extractor
    têm scripts junto. Por padrão roda em modo dry-run (só relatório) — nada é escrito
    no disco sem -Apply. Nunca commita: só deixa a mudança no working tree, para
    revisão e 'git add' explícito (Strict Staging Policy).
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

# Hash combinado de uma pasta inteira: concatena "caminho-relativo:hash" de cada
# arquivo, ordenado, e hasheia o resultado. Pega adição/remoção/modificação de
# qualquer arquivo dentro da pasta da skill, não só o SKILL.md.
function Get-FolderHash {
    param([string]$FolderPath)
    if (-not (Test-Path -Path $FolderPath -PathType Container)) { return $null }
    $files = Get-ChildItem -Path $FolderPath -Recurse -File | Sort-Object FullName
    if ($files.Count -eq 0) { return $null }
    $combined = ($files | ForEach-Object {
        $rel = $_.FullName.Substring($FolderPath.Length).Replace("\", "/")
        $h = (Get-FileHash -Path $_.FullName -Algorithm SHA256).Hash
        "$rel`:$h"
    }) -join "|"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($combined)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    return [System.BitConverter]::ToString($sha.ComputeHash($bytes)).Replace("-", "")
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

# 2. Comparar cada skill da mãe com a versão local (hash da pasta inteira)
Write-Host "🔄 Comparando skills locais com a mãe em: $SourceRoot" -ForegroundColor Cyan
Write-Host ""

$motherSkills = Get-ChildItem -Path $SourceSkillsDir -Directory
$toApply = @()

foreach ($skill in $motherSkills) {
    $name = $skill.Name
    $motherHash = Get-FolderHash -FolderPath $skill.FullName
    if ($null -eq $motherHash) { continue }

    $localDir = Join-Path $LocalSkillsDir $name
    $localHash = Get-FolderHash -FolderPath $localDir

    if ($null -eq $localHash) {
        Write-Host ("  {0,-28} NOVA (não instalada)" -f $name) -ForegroundColor Yellow
        $toApply += @{ Name = $name; Status = "nova" }
    } elseif ($localHash -eq $motherHash) {
        Write-Host ("  {0,-28} em dia" -f $name) -ForegroundColor Green
    } else {
        Write-Host ("  {0,-28} desatualizada" -f $name) -ForegroundColor Yellow
        $toApply += @{ Name = $name; Status = "desatualizada" }
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
    $srcDir = Join-Path $SourceSkillsDir $t.Name
    $destDir = Join-Path $LocalSkillsDir $t.Name
    # Espelha a pasta inteira: remove o destino antes de copiar, para que arquivos
    # removidos na mãe (ex.: um script descontinuado) também somem localmente.
    if (Test-Path -Path $destDir) { Remove-Item -Path $destDir -Recurse -Force }
    Copy-Item -Path $srcDir -Destination $destDir -Recurse -Force
    Write-Host "  ✅ '$($t.Name)' copiada da mãe (pasta inteira)." -ForegroundColor Green
}

Write-Host ""
Write-Host "⚠ Nada foi commitado. Revise o diff e faça 'git add' explícito (arquivo por arquivo) antes de commitar." -ForegroundColor Yellow

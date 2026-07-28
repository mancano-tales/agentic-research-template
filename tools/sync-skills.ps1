<#
.SYNOPSIS
    sync-skills.ps1 — Sincronização de skills a partir do repositório mãe (Windows)
.DESCRIPTION
    Compara as skills locais (.claude/skills/*) com as do repositório mãe (por padrão,
    a pasta irmã 'skills') e reporta o que está desatualizado ou faltando. Compara a
    PASTA inteira de cada skill (SKILL.md e quaisquer arquivos auxiliares, ex.:
    scripts/), não só o SKILL.md — skills como pdf-text-extractor têm scripts junto.

    A comparação é de CONTEÚDO NORMALIZADO, não de bytes crus: BOM, CRLF vs LF e
    linhas em branco no fim são ignorados (ver Get-ContentHash). Sem isso o relatório
    marca como "desatualizada" qualquer skill que só tenha mudado de codificação —
    foi o que aconteceu em 2026-07-28, quando 8 de 9 supostas divergências eram ruído.

    Por padrão roda em modo dry-run (só relatório) — nada é escrito no disco sem
    -Apply. Nunca commita: só deixa a mudança no working tree, para revisão e
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

    # Padrão: pasta irmã "skills" — repositório mãe das skills desde 2026-07-28.
    # Antes desta data o padrão era "agentic-research-template", que se declarava
    # mãe das skills de governança enquanto o repositório "skills" reunia as mesmas
    # skills mais ~90 outras. Duas mães para a mesma peça é o que fazia este script
    # comparar contra uma fonte ambígua e reportar sinal sem significado.
    $siblingDir = Split-Path -Path $RepoRoot -Parent
    return (Join-Path $siblingDir "skills")
}

# Extensões tratadas como texto para fins de normalização. Qualquer outra coisa
# (imagem, PDF, binário) é hasheada byte a byte, sem normalizar.
$script:TextExtensions = @(".md", ".yaml", ".yml", ".json", ".toml", ".txt",
                           ".r", ".sh", ".ps1", ".py", ".js", ".mjs", ".csv")

# Hash do CONTEÚDO de um arquivo, não dos seus bytes crus.
#
# Por que isto existe: até 2026-07-28 este script usava Get-FileHash direto nos
# bytes. Consequência real, medida numa auditoria: das 11 skills compartilhadas
# entre o template e o repositório mãe, 9 apareciam "desatualizadas" — e 8 delas
# tinham conteúdo IDÊNTICO. A diferença era BOM (marca de codificação), CRLF vs LF
# e uma linha em branco no fim. O script reportava informação verdadeira e inútil,
# e o autor perdeu tempo investigando divergência que não existia.
#
# Codificação não é conteúdo. Para arquivos de texto, normaliza-se antes de hashear:
#   - remove BOM UTF-8
#   - CRLF e CR viram LF
#   - remove linhas em branco no fim do arquivo
function Get-ContentHash {
    param([string]$Path)
    $ext = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()
    if ($script:TextExtensions -contains $ext) {
        $text = [System.IO.File]::ReadAllText($Path)
        $text = $text -replace "^﻿", ""      # BOM
        $text = $text -replace "`r`n", "`n"       # CRLF -> LF
        $text = $text -replace "`r", "`n"         # CR   -> LF
        $text = $text.TrimEnd("`n")               # linhas em branco no fim
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
    } else {
        $bytes = [System.IO.File]::ReadAllBytes($Path)
    }
    $sha = [System.Security.Cryptography.SHA256]::Create()
    return [System.BitConverter]::ToString($sha.ComputeHash($bytes)).Replace("-", "")
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
        $h = Get-ContentHash -Path $_.FullName
        "$rel`:$h"
    }) -join "|"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($combined)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    return [System.BitConverter]::ToString($sha.ComputeHash($bytes)).Replace("-", "")
}

$SourceRoot = Resolve-SkillsSource -Override $SourcePath

if ((Resolve-Path $SourceRoot -ErrorAction SilentlyContinue).Path -eq (Resolve-Path $RepoRoot -ErrorAction SilentlyContinue).Path) {
    Write-Host "Este repositorio JA E o repositorio mae das skills - nada para sincronizar aqui." -ForegroundColor Cyan
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

# O relatório cobre apenas as skills que este repositório JÁ TEM instaladas. As
# demais existentes na mãe são apenas contadas ao final, não listadas uma a uma.
#
# Por quê: a mãe (repositório `skills`) reúne 101 skills — governança, escrita
# acadêmica, análise em R, portadas de terceiros. Um consumidor usa um subconjunto.
# Antes de 2026-07-28 o relatório listava cada skill não instalada como "NOVA", o
# que enterrava as poucas linhas úteis (as desatualizadas) sob dezenas de linhas de
# ruído — 90 contra 9 na primeira execução real. Instalar skill nova é decisão
# deliberada do consumidor, não pendência a ser cobrada em todo relatório.
$motherSkills = Get-ChildItem -Path $SourceSkillsDir -Directory
$toApply = @()
$available = @()

foreach ($skill in $motherSkills) {
    $name = $skill.Name
    $localDir = Join-Path $LocalSkillsDir $name

    # Skill não instalada aqui: só conta, NÃO hasheia. Hashear as 90 skills da mãe
    # que este repositório não usa fazia o relatório levar minutos — a normalização
    # de conteúdo custa por arquivo, e 90% desse trabalho era sobre pastas cujo hash
    # nunca seria comparado com nada.
    if (-not (Test-Path -Path $localDir -PathType Container)) {
        $available += $name
        continue
    }

    $motherHash = Get-FolderHash -FolderPath $skill.FullName
    if ($null -eq $motherHash) { continue }
    $localHash = Get-FolderHash -FolderPath $localDir

    if ($null -eq $localHash) {
        $available += $name
    } elseif ($localHash -eq $motherHash) {
        Write-Host ("  {0,-28} em dia" -f $name) -ForegroundColor Green
    } else {
        Write-Host ("  {0,-28} desatualizada" -f $name) -ForegroundColor Yellow
        $toApply += @{ Name = $name; Status = "desatualizada" }
    }
}

if ($available.Count -gt 0) {
    Write-Host ""
    Write-Host ("ℹ {0} skill(s) disponíveis na mãe e não instaladas aqui." -f $available.Count) -ForegroundColor DarkGray
    Write-Host "   Para ver a lista:      Get-ChildItem `"$SourceSkillsDir`"" -ForegroundColor DarkGray
    Write-Host "   Para instalar uma:     .\tools\sync-skills.ps1 -Apply <nome>" -ForegroundColor DarkGray
}

Write-Host ""

# 3. Aplicar, se pedido
if ($Apply -eq "") {
    if ($toApply.Count -gt 0) {
        Write-Host "Rode com -Apply all para atualizar as desatualizadas acima, ou -Apply <nome> para uma skill específica (inclusive nova)." -ForegroundColor Cyan
        Write-Host "Nada foi escrito no disco (modo relatório)." -ForegroundColor DarkGray
    }
    exit 0
}

# 'all' significa "atualizar tudo que eu JÁ TENHO", nunca "instalar as 101 da mãe".
# Instalar uma skill nova exige nomeá-la explicitamente.
$targets = if ($Apply -eq "all") {
    $toApply
} else {
    @($toApply | Where-Object { $_.Name -eq $Apply }) +
    @($available | Where-Object { $_ -eq $Apply } | ForEach-Object { @{ Name = $_; Status = "nova" } })
}

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

#!/usr/bin/env bash
# ==============================================================================
# sync-skills.sh — Sincronização de skills de governança a partir do repositório mãe
#
# Compara as skills locais (.claude/skills/*) com as do repositório mãe (por padrão,
# a pasta irmã 'skills') e reporta o que está desatualizado ou
# faltando. Compara a PASTA inteira de cada skill (SKILL.md e arquivos auxiliares,
# ex.: scripts/), não só o SKILL.md. Por padrão roda em modo dry-run (só relatório)
# — nada é escrito no disco sem --apply. Nunca commita: só deixa a mudança no
# working tree, para revisão e 'git add' explícito (Strict Staging Policy).
#
# Uso:
#   tools/sync-skills.sh                        # relatório (dry-run)
#   tools/sync-skills.sh --apply request-audit   # puxa uma skill específica
#   tools/sync-skills.sh --apply all             # puxa todas as desatualizadas/faltando
#   tools/sync-skills.sh --source /caminho/outro-repo   # sobrepõe a detecção automática
# ==============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPLY=""
SOURCE_OVERRIDE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY="$2"; shift 2 ;;
    --source) SOURCE_OVERRIDE="$2"; shift 2 ;;
    *) echo "Argumento desconhecido: $1" >&2; exit 1 ;;
  esac
done

# 1. Resolver o caminho do repositório mãe
resolve_source() {
  if [[ -n "$SOURCE_OVERRIDE" ]]; then
    echo "$SOURCE_OVERRIDE"
    return
  fi
  local config_file="$REPO_ROOT/tools/.skills-source"
  if [[ -f "$config_file" ]]; then
    local configured
    configured="$(head -n1 "$config_file" | tr -d '\r\n')"
    if [[ -n "$configured" ]]; then
      echo "$configured"
      return
    fi
  fi
  # Padrão: pasta irmã "skills" — repositório mãe das skills desde 2026-07-28.
  # Antes desta data o padrão era "agentic-research-template", que se declarava mãe
  # das skills de governança enquanto o repositório "skills" reunia as mesmas skills
  # mais ~90 outras. Duas mães para a mesma peça é o que fazia este script comparar
  # contra uma fonte ambígua e reportar sinal sem significado.
  echo "$(dirname "$REPO_ROOT")/skills"
}

# Hash do CONTEÚDO de um arquivo, não dos seus bytes crus.
#
# Por que isto existe: até 2026-07-28 este script usava sha256sum direto nos bytes.
# Consequência real, medida numa auditoria: das 11 skills compartilhadas entre o
# template e o repositório mãe, 9 apareciam "desatualizadas" — e 8 delas tinham
# conteúdo IDÊNTICO. A diferença era BOM (marca de codificação), CRLF vs LF e uma
# linha em branco no fim. O script reportava informação verdadeira e inútil.
#
# Codificação não é conteúdo. Para arquivos de texto, normaliza antes de hashear:
# remove BOM UTF-8, converte CRLF/CR para LF, remove linhas em branco no fim.
# Extensões não reconhecidas como texto são hasheadas byte a byte.
content_hash() {
  local f="$1"
  case "${f,,}" in
    *.md|*.yaml|*.yml|*.json|*.toml|*.txt|*.r|*.sh|*.ps1|*.py|*.js|*.mjs|*.csv)
      sed -e '1s/^\xef\xbb\xbf//' -e 's/\r$//' "$f" \
        | awk 'BEGIN{n=0} {if($0==""){n++} else {while(n-->0) print ""; n=0; print}}' \
        | sha256sum | cut -d' ' -f1
      ;;
    *)
      sha256sum "$f" | cut -d' ' -f1
      ;;
  esac
}

# Hash combinado de uma pasta inteira: concatena "caminho-relativo:hash" de cada
# arquivo, ordenado, e hasheia o resultado. Pega adição/remoção/modificação de
# qualquer arquivo dentro da pasta da skill, não só o SKILL.md. Retorna vazio se
# a pasta não existir ou estiver vazia.
folder_hash() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  local entries
  entries="$(find "$dir" -type f | sort | while read -r f; do
    rel="${f#$dir/}"
    h="$(content_hash "$f")"
    printf "%s:%s|" "$rel" "$h"
  done)"
  [[ -n "$entries" ]] || return 0
  printf "%s" "$entries" | sha256sum | cut -d' ' -f1
}

SOURCE_ROOT="$(resolve_source)"

if [[ "$(cd "$SOURCE_ROOT" 2>/dev/null && pwd)" == "$REPO_ROOT" ]]; then
  echo "Este repositorio JA E o repositorio mae das skills - nada para sincronizar aqui."
  echo "   Se você melhorou uma skill localmente, edite-a direto em .claude/skills/ e commit normalmente."
  exit 0
fi

SOURCE_SKILLS_DIR="$SOURCE_ROOT/.claude/skills"
if [[ ! -d "$SOURCE_SKILLS_DIR" ]]; then
  echo "⚠ [ERRO] Repositório mãe não encontrado ou sem .claude/skills em: $SOURCE_ROOT" >&2
  echo "   Ajuste com --source, ou crie tools/.skills-source com o caminho correto (uma linha)." >&2
  exit 1
fi

LOCAL_SKILLS_DIR="$REPO_ROOT/.claude/skills"
mkdir -p "$LOCAL_SKILLS_DIR"

# 2. Comparar cada skill da mãe com a versão local (hash da pasta inteira)
echo "🔄 Comparando skills locais com a mãe em: $SOURCE_ROOT"
echo ""

# O relatório cobre apenas as skills que este repositório JÁ TEM instaladas. As
# demais existentes na mãe são apenas contadas ao final, não listadas uma a uma.
#
# Por quê: a mãe (repositório `skills`) reúne 101 skills — governança, escrita
# acadêmica, análise em R, portadas de terceiros. Um consumidor usa um subconjunto.
# Antes de 2026-07-28 o relatório listava cada skill não instalada como "NOVA", o
# que enterrava as poucas linhas úteis (as desatualizadas) sob dezenas de linhas de
# ruído — 90 contra 9 na primeira execução real. Instalar skill nova é decisão
# deliberada do consumidor, não pendência a ser cobrada em todo relatório.
TO_APPLY=()
AVAILABLE=()

for skill_dir in "$SOURCE_SKILLS_DIR"/*/; do
  [[ -d "$skill_dir" ]] || continue
  name="$(basename "$skill_dir")"
  local_dir="$LOCAL_SKILLS_DIR/$name"

  # Skill não instalada aqui: só conta, NÃO hasheia. Hashear as 90 skills da mãe
  # que este repositório não usa fazia o relatório levar minutos em Git Bash no
  # Windows — a normalização de conteúdo custa processos por arquivo, e 90% desse
  # trabalho era sobre pastas cujo hash nunca seria comparado com nada.
  if [[ ! -d "$local_dir" ]]; then
    AVAILABLE+=("$name")
    continue
  fi

  mother_hash="$(folder_hash "${skill_dir%/}")"
  [[ -n "$mother_hash" ]] || continue
  local_hash="$(folder_hash "$local_dir")"

  if [[ -z "$local_hash" ]]; then
    AVAILABLE+=("$name")
  elif [[ "$local_hash" == "$mother_hash" ]]; then
    printf "  %-28s em dia\n" "$name"
  else
    printf "  %-28s desatualizada\n" "$name"
    TO_APPLY+=("$name:desatualizada")
  fi
done

if [[ ${#AVAILABLE[@]} -gt 0 ]]; then
  echo ""
  echo "ℹ ${#AVAILABLE[@]} skill(s) disponíveis na mãe e não instaladas aqui."
  echo "   Para ver a lista:      ls \"$SOURCE_SKILLS_DIR\""
  echo "   Para instalar uma:     tools/sync-skills.sh --apply <nome>"
fi

echo ""

# 3. Aplicar, se pedido
if [[ -z "$APPLY" ]]; then
  if [[ ${#TO_APPLY[@]} -gt 0 ]]; then
    echo "Rode com --apply all para atualizar as desatualizadas acima, ou --apply <nome> para uma skill específica (inclusive nova)."
    echo "Nada foi escrito no disco (modo relatório)."
  fi
  exit 0
fi

# 'all' significa "atualizar tudo que eu JÁ TENHO", nunca "instalar as 101 da mãe".
# Instalar uma skill nova exige nomeá-la explicitamente.
CANDIDATES=("${TO_APPLY[@]}")
if [[ "$APPLY" != "all" ]]; then
  for a in "${AVAILABLE[@]}"; do
    [[ "$a" == "$APPLY" ]] && CANDIDATES+=("$a:nova")
  done
fi

applied_any=false
for entry in "${CANDIDATES[@]}"; do
  name="${entry%%:*}"
  if [[ "$APPLY" != "all" && "$APPLY" != "$name" ]]; then continue; fi
  src_dir="$SOURCE_SKILLS_DIR/$name"
  dest_dir="$LOCAL_SKILLS_DIR/$name"
  # Espelha a pasta inteira: remove o destino antes de copiar, para que arquivos
  # removidos na mãe (ex.: um script descontinuado) também somem localmente.
  rm -rf "$dest_dir"
  cp -r "$src_dir" "$dest_dir"
  echo "  ✅ '$name' copiada da mãe (pasta inteira)."
  applied_any=true
done

if [[ "$applied_any" == false ]]; then
  echo "Nada a aplicar para '$APPLY' (já está em dia, ou não existe na mãe)."
  exit 0
fi

echo ""
echo "⚠ Nada foi commitado. Revise o diff e faça 'git add' explícito (arquivo por arquivo) antes de commitar."

#!/usr/bin/env bash
# ==============================================================================
# sync-skills.sh — Sincronização de skills de governança a partir do repositório mãe
#
# Compara as skills locais (.claude/skills/*) com as do repositório mãe (por padrão,
# a pasta irmã 'agentic-research-template') e reporta o que está desatualizado ou
# faltando. Por padrão roda em modo dry-run (só relatório) — nada é escrito no disco
# sem --apply. Nunca commita: só deixa a mudança no working tree, para revisão e
# 'git add' explícito (Strict Staging Policy).
#
# Uso:
#   tools/sync-skills.sh                       # relatório (dry-run)
#   tools/sync-skills.sh --apply request-audit  # puxa uma skill específica
#   tools/sync-skills.sh --apply all            # puxa todas as desatualizadas/faltando
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
  # Padrão: pasta irmã "agentic-research-template"
  echo "$(dirname "$REPO_ROOT")/agentic-research-template"
}

SOURCE_ROOT="$(resolve_source)"

if [[ "$(cd "$SOURCE_ROOT" 2>/dev/null && pwd)" == "$REPO_ROOT" ]]; then
  echo "ℹ️  Este repositório JÁ É o repositório mãe (agentic-research-template) — nada para sincronizar aqui."
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

# 2. Comparar cada skill da mãe com a versão local (hash do SKILL.md)
echo "🔄 Comparando skills locais com a mãe em: $SOURCE_ROOT"
echo ""

TO_APPLY=()

for skill_dir in "$SOURCE_SKILLS_DIR"/*/; do
  [[ -d "$skill_dir" ]] || continue
  name="$(basename "$skill_dir")"
  mother_file="$skill_dir/SKILL.md"
  [[ -f "$mother_file" ]] || continue

  local_file="$LOCAL_SKILLS_DIR/$name/SKILL.md"
  mother_hash="$(sha256sum "$mother_file" | cut -d' ' -f1)"

  if [[ ! -f "$local_file" ]]; then
    printf "  %-28s NOVA (não instalada)\n" "$name"
    TO_APPLY+=("$name:nova")
  else
    local_hash="$(sha256sum "$local_file" | cut -d' ' -f1)"
    if [[ "$local_hash" == "$mother_hash" ]]; then
      printf "  %-28s em dia\n" "$name"
    else
      printf "  %-28s desatualizada\n" "$name"
      TO_APPLY+=("$name:desatualizada")
    fi
  fi
done

echo ""

# 3. Aplicar, se pedido
if [[ -z "$APPLY" ]]; then
  if [[ ${#TO_APPLY[@]} -gt 0 ]]; then
    echo "Rode com --apply <nome-da-skill> ou --apply all para puxar as atualizações acima."
    echo "Nada foi escrito no disco (modo relatório)."
  fi
  exit 0
fi

applied_any=false
for entry in "${TO_APPLY[@]}"; do
  name="${entry%%:*}"
  if [[ "$APPLY" != "all" && "$APPLY" != "$name" ]]; then continue; fi
  src="$SOURCE_SKILLS_DIR/$name/SKILL.md"
  dest_dir="$LOCAL_SKILLS_DIR/$name"
  mkdir -p "$dest_dir"
  cp "$src" "$dest_dir/SKILL.md"
  echo "  ✅ '$name' copiada da mãe."
  applied_any=true
done

if [[ "$applied_any" == false ]]; then
  echo "Nada a aplicar para '$APPLY' (já está em dia, ou não existe na mãe)."
  exit 0
fi

echo ""
echo "⚠ Nada foi commitado. Revise o diff e faça 'git add' explícito (arquivo por arquivo) antes de commitar."

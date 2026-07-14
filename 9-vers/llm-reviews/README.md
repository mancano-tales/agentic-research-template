# llm-reviews/ — Histórico e Auditoria de Sessões de IA (Conversas)

Este diretório contém o registro histórico e a trilha de auditoria das conversas com agentes de IA (Claude Code, Antigravity, etc.) que resultaram em mudanças significativas no projeto.

---

## Convenção de Nomenclatura

Os arquivos de conversa exportados devem seguir o padrão:
```
YYYY-MM-DD[_HHMM]_slug-descritivo_conversa-<fonte>.md
```
Onde `<fonte>` representa a IA ou plataforma utilizada (ex: `claude`, `antigravity`, `perplexity`, `gemini`).

---

## Como Exportar Conversas

Utilize a skill ou execute diretamente o script utilitário em Python:
```bash
python tools/export_conversa.py <session_uuid> [slug]
```
O script lê o arquivo de log JSONL original da sessão e converte-o para Markdown estruturado (com timestamps e raciocínios internos em seções recolhíveis `<details>`). Após a exportação, registre a nova entrada na tabela de inventário abaixo.

---

## Inventário de Conversas

| Arquivo | Tipo | Fonte | Assunto |
|---|---|---|---|
| `2026-07-13_2225_sincronizacao-governanca_conversa-antigravity.md` | Sessão de Trabalho | Antigravity | Sincronização de governança com tese principal |

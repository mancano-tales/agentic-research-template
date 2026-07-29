---
autor: "Tales Mançano / Ecossistema"
name: export-conversation
description: Exporta a conversa atual (ou uma sessão passada) do Claude Code ou Antigravity como Markdown completo — com timestamps, thinking e chamadas de ferramentas em seções recolhíveis — para {gov}/llm-reviews/ usando o script R. ({gov} = chave `diretorio_governanca` em CLAUDE.md § "Configuração de Skills")
---

# Exportar conversa para o diretório de logs ({gov}/llm-reviews/)

Esta skill é **idêntica em todo repositório que a usa**. Os únicos dados específicos deste projeto que ela consome são o caminho do script (chave `script_exportar_conversa`) e o diretório de governança (chave `diretorio_governanca`), ambos em `CLAUDE.md` § "Configuração de Skills".

> **Convenção de caminho**: neste documento, `{gov}` representa o valor da chave `diretorio_governanca` em `CLAUDE.md` § "Configuração de Skills".

## O que fazer

1. **Identifique o UUID da sessão atual**: extraia-o do caminho do scratchpad informado no seu contexto de sistema — o caminho geralmente tem o formato `.../Temp/claude/<project-slug>/<UUID-DA-SESSÃO>/scratchpad`. Esse UUID é o nome do arquivo `.jsonl` da sessão. Fallback (se não houver scratchpad no contexto): o `.jsonl` modificado mais recentemente na pasta de projetos do Claude (`~/.claude/projects/`) ou nos logs do Antigravity (`~/.gemini/antigravity/brain/`).

2. **Interprete o argumento da skill** (se houver):
   - Se parecer um UUID (ou prefixo hex de 8+ caracteres), o usuário quer exportar **outra** sessão: use-o como primeiro argumento do script.
   - Caso contrário, é o **slug** para o nome do arquivo (descreva o tema da conversa em kebab-case se o usuário deu texto livre).
   - Sem argumento: exporte a sessão atual e crie você mesmo um slug curto (3–5 palavras) que resuma os temas da conversa.

3. **Rode o script**, usando o caminho da chave `script_exportar_conversa` em `CLAUDE.md` § "Configuração de Skills" (se não estiver preenchida, tente `tools/export_conversa.R`):
   ```bash
   Rscript <script_exportar_conversa> <uuid-ou-caminho> [slug]
   ```

4. **Reporte ao usuário**: o caminho do arquivo gerado, o período coberto e as contagens que o script imprime. Avise que o export reflete o que está gravado em disco no momento da execução — mensagens posteriores (inclusive esta troca final) só entram se a skill for rodada de novo ao fim da conversa.

## Formato do arquivo gerado (para referência)

- Nome: `YYYY-MM-DD_HHMM_<slug>_conversa-claude.md` (data/hora = início da conversa, horário local). Nunca sobrescreve: sufixa `_v2`, `_v3`...
- Cabeçalho com UUID, fonte, início/fim/duração, modelo, versão, branch e contagens.
- `### [timestamp] Usuário` / `### [timestamp] Claude` a cada troca de turno; texto na íntegra.
- Thinking, parâmetros de ferramenta (JSON) e resultados de ferramenta na íntegra, cada um em `<details>` recolhível.
- Resumos de compactação de contexto viram seção própria (`## 📦`).
- UTF-8 sem BOM.


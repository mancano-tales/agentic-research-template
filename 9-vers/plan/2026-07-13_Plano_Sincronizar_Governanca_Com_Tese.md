---
tipo: Plano
titulo: "Sincronizar mancano-project-template com o estado atual de governança do repositório Mancano2026-MA-Thesis"
status: CONCLUÍDO
criado: "2026-07-13 22:17"
concluido: "2026-07-13 22:37"
agentes:
  orquestrador: "Claude Sonnet 5 (Claude Code, VS Code)"
  executor: null
  auditor: null
autor_humano: "Tales Mançano"
tarefas:
  - { desc: "Corrigir bug real do self-heal CLAUDE.md<->AGENTS.md (shell() com mklink falha silenciosamente sob Git Bash)", status: pendente, data: null }
  - { desc: "Estender self-heal para 3 vias incluindo .github/copilot-instructions.md", status: pendente, data: null }
  - { desc: "Adicionar checagem de validade da junction .agents -> .claude", status: pendente, data: null }
  - { desc: "Portar correcoes do parser YAML de fallback (aspas simples escapadas, split de array respeitando aspas)", status: pendente, data: null }
  - { desc: "Adicionar T5 (caminho absoluto nos proprios docs de governanca) e T6 (marcador de conflito de merge staged)", status: pendente, data: null }
  - { desc: "Adicionar rastreamento de cerca de codigo no T4 e genericizar a dependencia de .bib/_quarto.yml", status: pendente, data: null }
  - { desc: "Migrar hooks/setup.ps1/setup.sh para core.hooksPath versionado, com guarda UNC", status: pendente, data: null }
  - { desc: "Portar convencao de timestamp HH:MM para CLAUDE.md, plan/README.md, NEWS.md", status: pendente, data: null }
  - { desc: "Generalizar e portar a regra de Chapter Commits Prohibited e a regra tipo Zotero (arquivo gerenciado externamente)", status: pendente, data: null }
  - { desc: "Portar as skills finalizar-tarefa e limpar-pendencias-git, generalizadas", status: pendente, data: null }
relacionados:
  - "9-vers/plan/2026-07-12_Avaliacao_Auditoria_Governanca_Blackbox.md (Mancano2026-MA-Thesis)"
  - ".claude/skills/finalizar-tarefa/SKILL.md (Mancano2026-MA-Thesis)"
  - ".claude/skills/limpar-pendencias-git/SKILL.md (Mancano2026-MA-Thesis)"
  - "2026-07-13_2225_sincronizacao-governanca_conversa-antigravity.md"
news: []
---

# Plano — Sincronizar `mancano-project-template` com a governança atual da tese

> **Status**: ATIVO
> **O que é este documento**: roteiro para atualizar este template (congelado no commit `68b3cf8`, "add T1-T4 reproducibility gates") com tudo que o repositório-fonte `Mancano2026-MA-Thesis` desenvolveu depois — três rodadas de auditoria (T5, T6, correções de bugs reais, migração de hooks, skills de cerimônia) que o template nunca recebeu.
> **Elaborado por**: Claude Sonnet 5 (Claude Code, VS Code), a pedido do autor, que notou que não sabia se o template estava atualizado.
> **Por quê**: este template existe para ser o ponto de partida de projetos futuros do autor. Um template desatualizado replica bugs já corrigidos (o self-heal de link físico, por exemplo, está **provadamente quebrado** neste template hoje) e omite proteções que só existem na tese porque foram descobertas por auditorias sucessivas ali. Sincronizar agora evita que o próximo projeto novo comece já com a dívida técnica que a tese levou 3 rodadas para pagar.
> **Como usar**: execute as seções na ordem (1→6). Cada mudança cita o arquivo/trecho exato do repositório-fonte (`Mancano2026-MA-Thesis`) a consultar — não invente a lógica de novo, copie e adapte. Ao final, rode a suíte de verificação na seção 7 antes de comitar.

---

## 0. Diagnóstico (já feito, resumo)

Comparação linha a linha entre os dois repositórios em 2026-07-13:

| Arquivo | Template (`68b3cf8`) | Tese (atual) |
|---|---|---|
| `tools/validate-governance.R` | 844 linhas, só T1-T4 | 1116 linhas, T1-T6 + parser YAML corrigido + rastreamento de chunk |
| `CLAUDE.md` | 77 linhas, boilerplate genérico | 297 linhas |
| `hooks/*.sample` | copiados para `.git/hooks/` no setup | renomeados sem `.sample`, instalados via `core.hooksPath` |
| `setup.ps1` | sem guarda UNC | guarda UNC (try/catch em torno de `Get-Volume`) |
| `.claude/skills/` | só `exportar-conversa` | + `finalizar-tarefa`, `limpar-pendencias-git` |
| `9-vers/plan/README.md` | `criado`/`concluido` só `YYYY-MM-DD` | `YYYY-MM-DD HH:MM` obrigatório |

`4-DA-Code/utils/export_conversa.R` (tese) e `tools/export_conversa.R` (template) já estão **idênticos** — nenhuma ação necessária aí.

---

## 1. `tools/validate-governance.R` — Seção 0 (self-heal de link)

**Bug real confirmado, não hipotético**: o template usa `shell("cmd /c mklink /h ...", translate = TRUE, intern = TRUE)` (linhas 63 e 86 do template). Sob a execução do hook `pre-commit` via Git Bash, `Sys.getenv("SHELL")` aponta para `bash.exe`, o que faz `shell()` do R roteanálise o comando errado para um `cmd.exe` aninhado — o `mklink` nunca roda de verdade, e o self-heal sempre cai no fallback de cópia física (`file.copy`), nunca criando o hard link real. Isso foi descoberto e corrigido na tese (ver `9-vers/plan/2026-07-12_Avaliacao_Auditoria_Governanca_Blackbox.md` § achados da segunda rodada).

**Correção**: trocar as duas ocorrências de `shell("cmd /c mklink /h X Y", ...)` por:
```r
link_success <- tryCatch({
  res <- system2("cmd.exe", c("/c", "mklink", "/h", "X", "Y"), stdout = TRUE, stderr = TRUE)
  attr(res, "status") %||% 0 == 0
}, error = function(e) FALSE)
```
(precisa do helper `%||%` já presente mais abaixo no arquivo — se a seção 0 rodar antes dele ser definido, mova a definição do helper para o topo do script).

**Estender para 3 vias**: o template já tem `.github/copilot-instructions.md` (confirmado, `ls .github/`), mas a seção 0 só sincroniza `CLAUDE.md`↔`AGENTS.md`. Portar a extensão de 3 vias da tese (seção "0b/0c" em `tools/validate-governance.R` da tese) — sincronização one-directional de `CLAUDE.md` → `copilot-instructions.md`, não bidirecional (ver comentário na tese explicando por quê).

**Checagem de junction `.agents`**: portar a checagem informativa (não-bloqueante) que compara `sort(list.files(".agents"))` com `sort(list.files(".claude"))` — `Sys.readlink()` do R não reconhece junctions NTFS neste ambiente (confirmado por teste na tese), por isso a comparação é por listagem de conteúdo, não por metadado de link.

---

## 2. `tools/validate-governance.R` — Parser YAML de fallback

Portar as duas funções que a tese adicionou depois de dois bugs reais de perda silenciosa de dados:
- `parse_yaml_single_quoted(s)` — respeita o escape YAML `''` = apóstrofo literal (sem isso, `'Plano do Autor''s Revisão'` truncava no primeiro apóstrofo).
- `split_respecting_quotes(s)` — não quebra `relacionados: ["Plano A, revisão", "Plano B"]` no meio do primeiro elemento.

Copiar as duas funções inteiras da tese (proximidade: logo após a seção "Inicialização", antes de `parse_yaml_lines()`) e trocar as chamadas de strip simples por elas no caminho `chave: valor` do parser.

---

## 3. `tools/validate-governance.R` — T5 e T6 (novas travas)

**T5** — mesmo regex/helper do T1 (`check_abs_path_in_added_lines()` na tese), aplicado a uma lista fixa de documentos de governança (`CLAUDE.md`, `AGENTS.md`, `README.md`, `GUIDANCE.md`, `NEWS.md`, `9-vers/plan/README.md`, `9-vers/llm-reviews/README.md`) — bloqueia se um caminho absoluto local for reintroduzido nesses arquivos especificamente (achado real: 3 links `file:///c:/Users/...` estavam hardcoded nesses próprios documentos).

**T6** — bloqueio de marcadores de conflito de merge staged (`<<<<<<<`, `=======`, `>>>>>>>`) em **qualquer** arquivo staged, escopo "só linhas adicionadas" como o resto da suíte:
```r
CONFLICT_MARKER_REGEX <- r"{^(<{7}|>{7}|={7}$)}"
```
Nota: a tese exclui `9-vers/llm-reviews/` deste check porque logs de conversa exportados legitimamente citam marcadores de conflito dentro de blocos de código (falso-positivo real, encontrado ao vivo). Se o template também vier a ter uma pasta de logs de conversa citando trechos de código com esses marcadores, replicar a mesma exclusão nomeada; senão, aplicar sem exclusão.

Ordem de execução recomendada (mesma da tese): helpers de git → T2 → T1 → T5 → T6 → T4 → T3.

---

## 4. `tools/validate-governance.R` — T4 (rastreamento de chunk + genericização)

**Bug real a portar a correção**: sem rastreamento de cerca de código (` ``` `), uma linha adicionada dentro de um chunk R (`email <- c("a", "@boto2014")`) é capturada como citação inválida. Portar o rastreamento de abertura/fechamento de cerca dentro das próprias linhas adicionadas do diff (variável `in_chunk`, toggled em linhas que batem `^\s*```"), pulando a checagem de citação enquanto `in_chunk` estiver `TRUE`.

**Decisão de design nova, não apenas cópia**: o T4 do template (como o da tese) está hardcoded para um projeto Quarto+Zotero (`_quarto.yml`, fallback `Zotero-Library-cr-2026-06-08.bib`, menção a `educabr2`). Como este é um **template genérico**, não faz sentido copiar esses hardcodes de novo — projetos futuros podem não ter bibliografia nenhuma. Ajustar `resolve_bib_path()` para retornar `NA`/vazio (não um fallback com nome de arquivo específico da tese) quando `_quarto.yml` não existir ou não tiver campo `bibliography:`, e fazer T4 pular silenciosamente (`cat_info`, não `cat_warn`) quando não houver `.bib` detectável — em vez de avisar toda vez que rodar num projeto que nunca teve um.

---

## 5. Hooks e `setup.ps1`/`setup.sh`

1. Renomear `hooks/pre-commit.sample` → `hooks/pre-commit` e `hooks/post-merge.sample` → `hooks/post-merge` (`core.hooksPath` exige o nome exato, sem sufixo). O conteúdo do `pre-commit` do template já limpa o locale corretamente — só falta o rename e o `chmod +x`.
2. Em `setup.ps1`/`setup.sh`, trocar a lógica de `Copy-Item hooks/*.sample -> .git/hooks/*` por `git config core.hooksPath hooks` (idempotente) + limpeza de eventuais `.git/hooks/pre-commit`/`post-merge` órfãos de uma instalação antiga.
3. `setup.ps1` linha 13 (`$fs = (Get-Volume -DriveLetter $drive.Replace(":", "")).FileSystem`) crasha se `$PSScriptRoot` for um caminho UNC sem letra de unidade. Envolver em `if ($drive -match '^[A-Za-z]:$') { try {...} catch {...} } else { aviso, pular checagem de FS }` — padrão já implementado na tese.
4. Corrigir a mensagem final de sucesso para citar `core.hooksPath -> 'hooks/'` em vez de `.git/hooks/`.
5. Confirmar que o aviso sobre risco de "atomic save" de editores/clientes de sincronização de nuvem (que pode quebrar o hard link `AGENTS.md`) menciona explicitamente clientes de sync (Dropbox/OneDrive/Google Drive/iCloud), não só editores de texto — a tese ampliou esse texto depois de identificar que este próprio repositório vive dentro de uma pasta de sincronização (`MancanoSync`).

---

## 6. Convenções de documentação (CLAUDE.md, plan/README.md, NEWS.md, skills)

1. **Timestamp rigor**: adicionar ao `CLAUDE.md` do template o parágrafo completo de "Convenção de timestamp" (a versão da tese está em `CLAUDE.md` § Synchronized Commit Policy, e há uma nota espelho no topo do `NEWS.md` da tese) — generalizar removendo a menção a "Horário de Brasília" como fixo e deixando `[seu fuso horário local]` como placeholder, já que o template pode ser reusado para projetos com outro contexto. Atualizar `9-vers/plan/README.md` (Diretrizes de Formatação) e o próprio `9-vers/plan/2026-07-11_Plano_TEMPLATE.md` para `criado`/`concluido` no formato `YYYY-MM-DD HH:MM`, não só `YYYY-MM-DD`.
2. **Regra tipo "Chapter Commits Prohibited"**: a tese proíbe agentes de comitar `3-texts/*.qmd` sem pedido explícito, para proteger rascunho do autor em arquivos de conteúdo principal. Generalizar como um placeholder no `CLAUDE.md` do template: *"Se este projeto tem um diretório de autoria humana primária (prosa, notebooks de pesquisa, etc.) onde edições não devem ser comitadas silenciosamente por agentes, declare-o aqui nomeadamente."* — não inventar um nome de pasta específico, deixar como instrução de preenchimento.
3. **Regra tipo "Zotero .bib" (Regra 4 da tese)**: generalizar como um segundo placeholder: *"Se este projeto tem um arquivo gerenciado por uma ferramenta externa (biblioteca de citação, schema gerado, lockfile), proíba EDIÇÃO manual por agentes aqui — mas note explicitamente que comitar esse arquivo sem editá-lo é seguro (a distinção entre 'não editar' e 'não comitar' gerou confusão real numa sessão anterior — ver histórico da tese, `9-vers/plan/2026-07-13_Prompt_Finalizacao_Pendencias_Git.md`)."*
4. Adicionar a mesma nota de convenção de timestamp ao topo do `NEWS.md` do template (hoje ele não tem nenhuma).

## 7. Skills

Portar, generalizando as referências específicas da tese (substituir `3-texts/*.qmd`, `2-set/Zotero-Library...bib`, `4-DA-Code/utils/export_conversa.R` pelos placeholders equivalentes do template — `tools/export_conversa.R` já é o caminho certo no template):
- `.claude/skills/finalizar-tarefa/SKILL.md` (76 linhas na tese) — já inclui, na versão atual, as 5 correções da auditoria desta mesma sessão (staging explícito em vez de `git add .`, teto de 3 tentativas no retry de `.git/index.lock`, checkpoint de validação após editar YAML, descrição correta do que `--sync` faz, exigência do bloco de Metadados de Execução). Portar essa versão já corrigida, não uma anterior.
- `.claude/skills/limpar-pendencias-git/SKILL.md` (79 linhas na tese) — skill nova, generalização do procedimento de limpeza de pendências de git em lote (múltiplos agentes, múltiplos dias) que a tese só formalizou depois de executar o processo manualmente uma vez via prompt avulso. Ler o conteúdo antes de portar para confirmar quais partes são genéricas vs. específicas da tese (ex.: as "2 variantes com/sem `.qmd`" mencionadas no inventário de sessão são thesis-specific e precisam de generalização, não cópia direta).

---

## 8. Verificação

Depois de aplicar as seções 1-7:
1. Rodar `Rscript tools/validate-governance.R` no template sem nada staged — deve passar limpo.
2. Repetir os 6 cenários de teste documentados em `9-vers/plan/2026-07-12_Plano_Melhorias_QA_Reprodutibilidade_Academica.md` § "Plano de Validação e Testes" da tese (adaptados: caminho absoluto staged bloqueia, arquivo >10MB bloqueia, citação inexistente bloqueia só se houver `.bib` detectável, marcador de conflito staged bloqueia, `.git/hooks/pre-commit` antigo removido depois do `setup.ps1`).
3. Testar o self-heal de verdade: divergir `CLAUDE.md` de `AGENTS.md` manualmente, rodar o validador, confirmar (via `fsutil hardlink list` ou comparação de inode) que o link recriado é um **hard link real**, não uma cópia — este é o teste que a tese nunca rodou até a segunda rodada de auditoria, e é o teste que provaria que o bug da seção 1 foi de fato corrigido, não só reescrito.
4. Um `git clone` limpo do template para um caminho curto fora de `MancanoSync/`, rodar `setup.ps1`, confirmar que `core.hooksPath` fica vazio antes do setup e aponta para `hooks/` depois (mesmo teste que a tese rodou na terceira rodada).

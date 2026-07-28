---
tipo: Plano
titulo: "Migração para AGENTS.md, fim dos hard links e indireção real do diretório de governança"
status: ATIVO
criado: "2026-07-27 21:49"
concluido: null
agentes:
  orquestrador: "Claude Opus 5 (Claude Code, VS Code)"
  executor: null
  auditor: null
autor_humano: "Tales Mançano"
tarefas:
  - { desc: "WP0 — Ativar Developer Mode no Windows (ação humana, pré-requisito)", status: pendente, data: null }
  - { desc: "WP1 — Substituir hard links por symlink AGENTS.md → CLAUDE.md e remover o self-heal", status: pendente, data: null }
  - { desc: "WP2 — Remover copilot-instructions.md e .cursor/rules/ dos consumidores", status: pendente, data: null }
  - { desc: "WP3 — Indireção real do diretório de governança (PATH_GOV_DIR + diretorio_governanca)", status: pendente, data: null }
  - { desc: "WP4 — Resgatar os órfãos da raiz MancanoSync (9-vers/ e 0-governance/)", status: pendente, data: null }
  - { desc: "WP5 — Reduzir CLAUDE.md para <200 linhas migrando regras para .claude/rules/", status: pendente, data: null }
  - { desc: "WP6 — Substituir sync-skills por symlink de .claude/rules/ (mecanismo oficial)", status: pendente, data: null }
  - { desc: "WP7 — Decidir nome do diretório de governança por repositório (último passo)", status: pendente, data: null }
  - { desc: "WP8 — Dois ritmos de trabalho (Fluxo Rápido vs Fluxo Arquitetural) com gatilho mecânico", status: pendente, data: null }
  - { desc: "WP9 — Auditoria silenciosa via Stop hook; avaliar SpecStory como substituto do export_conversa.R", status: pendente, data: null }
  - { desc: "WP10 — Migrar travas de prompt para PreToolUse hooks; reduzir dependência de R", status: pendente, data: null }
  - { desc: "WP11 — Eliminar caminhos absolutos locais (10.5k+ ocorrências, 7 repositórios)", status: pendente, data: null }
relacionados:
  - "9-vers/plan/2026-07-14_Plano_Skills_Compartilhadas_TODO.md"
news: []
---

# Plano — Migração para AGENTS.md, fim dos hard links e indireção real do diretório de governança

> **Status**: ATIVO
> **O que é este documento**: Plano de migração do template de governança e de todos os seus repositórios consumidores, para (a) adotar o padrão aberto AGENTS.md pelo mecanismo oficial, (b) eliminar a classe inteira de bugs de hard link, (c) criar indireção real do diretório de governança, e (d) adotar `.claude/rules/` como mecanismo de compartilhamento entre projetos.
> **Elaborado por**: Claude Opus 5 (Claude Code, VS Code)
> **Por quê**: A auditoria de 2026-07-27 encontrou três pastas de governança coexistindo na raiz `MancanoSync`, um export de conversa fora do controle de versão, hard links quebrados em 3 de 8 repositórios, e uma chave de configuração (`diretorio_governanca`) que não é lida por lugar nenhum. A causa raiz não é o nome da pasta: é a ausência de indireção. Enquanto isso, a documentação oficial do Claude Code passou a oferecer mecanismos que tornam boa parte do tooling artesanal deste template desnecessário.
> **Como usar**: Executar os Work Packages **na ordem numérica**. A ordem não é estética — WP3 antes de WP7 é o que impede a próxima renomeação de repetir o estrago. Cada WP é commitável isoladamente.

---

## 0. Diagnóstico (evidência mecânica coletada em 2026-07-27)

### 0.1 Raio de alcance — inventário verificado

| Repositório | Dir. governança | CLAUDE | AGENTS | Copilot | Cursor | Hard link |
|---|---|---|---|---|---|---|
| `MancanoSync` (raiz) | `0-meta` + 2 órfãos | sim | sim | sim | — | **QUEBRADO** |
| `agentic-research-template` | `9-vers` | sim | sim | sim | sim | **QUEBRADO** |
| `skills` | `0-meta` | sim | sim | sim | — | **QUEBRADO** |
| `Mancano2026-MA-Thesis` | `9-vers` | sim | sim | — | sim | ok |
| `Nahoum-Mancano-2026-Antitrust` | `9-vers` | sim | sim | sim | sim | ok |
| `agentic-institutionalism` | `9-vers` | sim | sim | sim | sim | ok |
| `cha-affirmative-action-us-brazil` | `0-meta` | sim | sim | sim | — | ok |
| `Annotated-Bibliography` | — | sim | sim | — | — | ok |
| `quarto-tts-reader` | — | sim | sim | — | — | ok |
| `educabr2` | — | sim | — | — | — | n/a |
| `folha-scraper` | — | sim | — | — | — | n/a |
| `planning-repo` | — | sim | — | — | — | n/a |

**12 repositórios afetados**, em 3 camadas: 7 consumidores plenos (com diretório de governança), 2 parciais (só o par de instrução), 3 mínimos (só `CLAUDE.md`).

### 0.2 Achados que motivam o plano

1. **Hard links quebrados em 3 repositórios agora.** Verificado por inode. No template, `AGENTS.md` e `.github/copilot-instructions.md` estão sem a `HARD LINK RULE` adicionada no commit `feb55a1` — ou seja, **a regra que manda os agentes não perderem tempo com hard link está faltando justamente porque o hard link falhou.**

2. **Export de conversa fora do git.** `MancanoSync/9-vers/llm-reviews/2026-07-26_1059_tts-reader-annotated-bib_conversa-antigravity.md` existe no disco e é ignorado pelo `.gitignore` whitelist. Causa: `tools/export_conversa.R:33` fixa `"9-vers"` sem fallback, enquanto o repositório usa `0-meta`. Um artefato de governança exigido pela RULE 3 do Covenant não tem backup.

3. **Terceiro nome órfão.** `MancanoSync/0-governance/backups/` contém 2 arquivos `.bak` de 2026-07-17. A string `0-governance` **não aparece em nenhuma configuração, script ou documento** do ecossistema.

4. **A indireção não existe.** A chave `diretorio_governanca` está documentada em `MancanoSync/CLAUDE.md` e `skills/CLAUDE.md`, e não é consumida por nenhuma skill. As skills escrevem `9-vers/` literalmente — exatamente o que o preâmbulo delas jura que nunca fazem ("nunca hardcoded aqui"). A ponte hoje é uma nota em prosa: *"skills que citarem `9-vers/` devem ser lidas como `0-meta/` aqui."*

5. **Invariante byte-idêntica já rompida.** Hash de `close-task`, `sync-skills` e `export-conversation` diverge entre os 3 repositórios. O sinal "em dia/desatualizada" do `sync-skills` já não significa o que promete.

6. **`.cursor/rules/governance.mdc` contradiz o `CLAUDE.md`.** Manda gravar `concluido: YYYY-MM-DD` enquanto o `CLAUDE.md` exige `YYYY-MM-DD HH:MM`; ainda cita o nome antigo do repositório (`mancano-project-template`); e seus `globs:` apontam para `9-vers/`.

### 0.3 Fatos externos que mudam as opções disponíveis

Verificados em fonte primária (doc oficial do Claude Code, `agents.md`, Linux Foundation):

- **Claude Code não lê `AGENTS.md`** — lê `CLAUDE.md`. Posição documentada oficialmente, com workaround oficial (import `@AGENTS.md` ou symlink). Issue [#6235](https://github.com/anthropics/claude-code/issues/6235) aberta desde 2025-08-21, sem resposta na thread.
- **`AGENTS.md` é padrão da Agentic AI Foundation / Linux Foundation**, 60k+ repositórios, 24 ferramentas. Copilot e Cursor leem nativamente.
- **`.claude/rules/` suporta symlinks oficialmente** para compartilhar regras entre projetos, e suporta escopo por caminho via frontmatter `paths:`.
- **Alvo oficial de tamanho do `CLAUDE.md`: menos de 200 linhas.** Arquivos maiores reduzem aderência. Imports **não** economizam contexto — carregam junto no launch.
- Symlink no Windows exige Administrador **ou Developer Mode**. Developer Mode está **desativado** nesta máquina (verificado: `AllowDevelopmentWithoutDevLicense` vazio).

### 0.4 Validação de mercado (busca de código no GitHub, 2026-07-27)

Executada via `gh search code` / `gh api search/repositories` — evidência de prática real, não de artigos.

| Decisão do plano | Evidência encontrada | Veredito |
|---|---|---|
| WP1 — symlink em vez de import | `@AGENTS.md` dentro de `CLAUDE.md`: **apenas 3 repositórios públicos**. Symlink documentado em `grafana/grafana-kiosk`, `grafana/grafana-polystat-panel`, `utooland/utoo`, `Cosmian/kms`, `envoyproxy/ai-gateway` | **Confirma.** A direção escolhida pelo autor é a prática majoritária; o método oficial é o minoritário. |
| WP5/WP6 — `.claude/rules/` | Em produção: `algolia/instantsearch` (`e2e.md`), `arvidn/libtorrent` (`dht.md`), `SonarSource/SonarJS`, `platform9/vjailbreak` (`ui.md`), `generaltranslation/gt` (`cli.md`), `ran-isenberg/aws-lambda-handler-cookbook` (`cdk.md`), `yshrsmz/BuildKonfig` (`git.md`) | **Confirma com força.** Organização por tema é o padrão emergente. |
| Trilha de auditoria de conversas | Exportadores são commodity (`magarcia/cc2md` 27★ e ~5 clones). **Nenhuma convenção de governança** em cima deles (inventário, co-commit, status). | **Sem precedente.** Manter como está; é o diferencial real do template. |

**Referências a estudar antes de executar**: `carlrannaberg/claudekit` (tem `src/commands/agents-md/migration.md` — ferramenta de migração pronta, ler antes de escrever a nossa), `Ischca/awesome-agents-md` (70★, lista curada de AGENTS.md reais), `johnpapa/ai-ready` (117★), `popescualextraian/shipped-by-agents` (29★), `walidboughdiri/claude-governance`, `synthaicode/XRefKit`.

**Nota de maturidade do campo**: o maior repositório de governança de agentes encontrado tem **30 estrelas**. Não existe solução consolidada — este template não está atrasado em relação ao mercado, está dentro da fronteira atual dele.

### 0.5 Raio de alcance é maior que os 12 repositórios

Dois fatos descobertos na busca do GitHub que **não estavam no § 0.1**:

1. **O repositório mãe é público e já foi renomeado no remote**: `mancano-tales/agentic-workflow-template` (público, push em 2026-07-27 20:28 BRT). A pasta local ainda se chama `agentic-research-template` — os dois nomes convivem e o plano usa o nome local nas tabelas.
2. **Existe pelo menos um adotante externo**: `andersonheri/andersonheri.github.io` contém `9-vers/llm-reviews/README.md` e **não é fork** — a estrutura foi copiada manualmente por terceiro.

**Consequência para a execução**: mudanças de convenção neste template são públicas e afetam gente fora do controle do autor. WP2 (deleção de `copilot-instructions.md` e `.cursor/rules/`) e WP7 (nome do diretório) devem vir acompanhados de entrada no `NEWS.md` redigida para leitor externo, não só para o autor. Considerar também abrir uma nota no `README.md` do template descrevendo a migração para quem já copiou a estrutura.

### 0.7 Benchmarking: `microsoft/agent-governance-toolkit` (clonado e lido em 2026-07-27)

4.947★, MIT, Python + Node. **Escopo diferente do nosso**: governança de *runtime* de agentes autônomos (OWASP Agentic Top 10, identidade zero-trust, sandbox). Nós governamos *repositório e documentação*. **Não adotar o produto** — adotar os mecanismos abaixo.

A tese deles valida o WP10 literalmente, com citação de OWASP LLM01 e de Andriushchenko et al. (ICLR 2025), que reporta 100% de taxa de sucesso de ataque contra GPT-4o, Claude 3 e Llama-3:

> *"Prompt-level safety ('please follow the rules') is not a control surface. It is a polite request to a stochastic system. […] Actions the AGT kernel denies are not 'unlikely.' They are structurally impossible."*

| # | Mecanismo deles | Onde entra aqui |
|---|---|---|
| 1 | **Política de três efeitos**: `allow` / `review` / `deny`, com `defaultEffect: "review"`. Read/Glob/Grep = allow; Bash/Write/Edit = review; padrões específicos = deny | **WP8** — é exatamente o "dois ritmos", expresso como policy-as-code em vez de prosa. O gatilho mecânico vira `pathRules` com `effect: "review"` |
| 2 | **Fail closed**: `denyOnPolicyError: true`; o hook sai com código 2 se a avaliação lançar exceção | **WP10** — princípio geral. Hoje o `validate-governance.R` falha *aberto*: sem R instalado, não valida e ninguém percebe |
| 3 | **Regras nomeadas e auditáveis**: cada regra tem `id`, `reason` e padrão; quando bloqueia, o agente recebe o motivo. Com exceções explícitas (`SAFE_CLEANUP_TARGETS`) | **WP10** — formato de referência para as travas. Regra sem escape hatch vira regra contornada |
| 4 | **Trilha com hash encadeado**: `previousHash` → `hash`, genesis hash, verificação a cada append; adulteração retroativa é detectável | **WP9** — nossa regra "NEWS.md nunca é reescrito" é honrada por disciplina; a deles, por criptografia. Avaliar para o inventário de `llm-reviews` |
| 5 | **Contexto injetado por hook** (`SessionStart` → `additionalContext`), não por leitura de arquivo | **WP5/WP10** — resolve "o agente esqueceu o CLAUDE.md" sem depender do arquivo caber na janela |
| 6 | **Distribuição por plugin marketplace**: `.claude-plugin/marketplace.json` + `/plugin marketplace add microsoft/agent-governance-toolkit` | **WP6** — pode **aposentar o `sync-skills`**. Em vez de copiar skills para 12 repos e comparar hash, publicar plugin versionado que cada repo instala — inclusive o adotante externo do § 0.5 |
| 7 | **`AGENTS.md` é mapa, não sermão**: 130 linhas / 7,5KB, seções de roteamento (*Where Changes Belong*, *Routing Rules*, *Decision Escalation*, *Boundaries*), **zero** "NUNCA faça X" — porque isso vive na policy | **WP5** — modelo de referência para a conversão prosa → estrutura |

**Observação que contraria uma suposição nossa**: eles **não têm `CLAUDE.md`**. Só `AGENTS.md` (7,5KB) e `.github/copilot-instructions.md` (24KB) — e os dois são arquivos **diferentes com conteúdos diferentes**, não espelhos. Um repositório Microsoft de 4,9k★ não usa o modelo de arquivo espelhado que este template adota. Não é motivo para mudar a decisão do § 0.8, mas é motivo para não tratá-la como consenso de mercado.

**Não copiar**: o produto Python/PyPI, o MCP server, zero-trust e sandbox (escopo de agente autônomo em produção); o `copilot-instructions.md` de 24KB (dogfooding do próprio produto); o audit log em `~/.claude/agt/` fora do repositório — isso **contraria nosso design deliberado** de versionar a trilha de auditoria, que é defensável e serve a outro propósito.

### 0.8 Decisão de direção (registro explícito)

O autor determinou que **`CLAUDE.md` permanece o arquivo canônico** e `AGENTS.md` o ponteiro.

Isto **exclui** o método de import `@AGENTS.md` da documentação oficial, que força a direção inversa (o import é sintaxe exclusiva do Claude Code; `@CLAUDE.md` dentro de um `AGENTS.md` seria lido como texto literal por Codex/Cursor/Copilot, quebrando justamente as ferramentas que respeitam o padrão aberto).

A direção desejada é obtida por **symlink `AGENTS.md → CLAUDE.md`** (WP1), que preserva o canônico e funciona para todas as ferramentas por serem bytes idênticos. Custo: exige Developer Mode (WP0). Fallback documentado em WP1.3 caso o autor não queira ativar Developer Mode.

---

## 1. Mudanças Propostas

### WP0 — Pré-requisito (ação humana)
*   **[HUMANO]** Ativar Developer Mode: Configurações → Sistema → Para desenvolvedores → "Modo de desenvolvedor" = Ativado.

### WP1 — Fim dos hard links
*   **[MODIFY]** `setup.ps1` / `setup.sh` — trocar `mklink /h` por symlink; remover a criação do link de `.github/copilot-instructions.md`
*   **[MODIFY]** `tools/validate-governance.R` — **remover a seção 0 inteira** (self-heal, `mklink`, `make_backup_path()`, `PATH_BACKUP_DIR`)
*   **[MODIFY]** `CLAUDE.md` — remover a `HARD LINK RULE` do bloco de regras críticas
*   **[DELETE]** `9-vers/backups/` (e `MancanoSync/0-governance/backups/` em WP4)

### WP2 — Remoção dos arquivos redundantes de instrução
*   **[DELETE]** `.github/copilot-instructions.md` (6 repositórios)
*   **[DELETE]** `.cursor/rules/governance.mdc` (4 repositórios)
*   **[MODIFY]** `README.md` — atualizar o organograma
*   **[MODIFY]** `CLAUDE.md` — remover as menções aos dois arquivos

### WP3 — Indireção real

**Estado por repositório** (auditado em 2026-07-27, conferindo a definição real de `PASTA_SAIDA` e `PATH_PLAN_DIR`, não a mera presença da string):

| Repositório | Dir. usado | `validate-governance.R` | `export_conversa.R` | Situação |
|---|---|---|---|---|
| `skills` | `0-meta` | ✅ tem | ✅ tem | ok — só convergir para a forma canônica |
| `cha-affirmative-action-us-brazil` | **`0-meta`** | ✅ tem (linha 25) | ❌ **fixo em `9-vers`** | 🔴 **bomba armada**: primeiro export criará `9-vers/` órfã |
| `MancanoSync` (raiz) | **`0-meta`** | (sem script) | ❌ **fixo em `9-vers`** | 🔴 **já detonou** — export de 2026-07-26 fora do git (§ 0.2) |
| `Nahoum-Mancano-2026-Antitrust` | `9-vers` | ❌ fixo | ❌ fixo | coerente hoje, frágil se renomear |
| `agentic-institutionalism` | `9-vers` | ❌ fixo | ❌ fixo | idem |
| `Mancano2026-MA-Thesis` | `9-vers` | ❌ fixo | (sem script) | idem |
| `agentic-research-template` | `9-vers` | ✅ **feito 2026-07-27** | ✅ **feito 2026-07-27** | mãe, aplicado |

**Achado relevante**: `cha` já tinha a indireção no validador, escrita numa rodada anterior e **nunca promovida ao template-mãe** — a implementação de 2026-07-27 convergiu de forma independente para a mesma solução. Confirma o § 0.2 item 5: correções nascem nos consumidores e não voltam para a mãe. **Prioridade: `cha` e a raiz primeiro** (bug real), depois os `9-vers` (prevenção).

*   **[MODIFY]** `tools/validate-governance.R` — adotar o `PATH_GOV_DIR` já existente no repo `skills`
*   **[MODIFY]** `tools/export_conversa.R` — idem, para `PASTA_SAIDA`
*   **[MODIFY]** `.claude/skills/{close-task,git-cleanup,export-conversation,request-audit}/SKILL.md` — substituir `9-vers/` literal pela consulta à chave `diretorio_governanca`
*   **[MODIFY]** `CLAUDE.md` § Configuração de Skills — **adicionar a chave `diretorio_governanca`** (hoje ausente no template)

### WP4 — Resgate dos órfãos da raiz
*   **[MOVE]** `MancanoSync/9-vers/llm-reviews/2026-07-26_1059_*.md` → `0-meta/llm-reviews/`
*   **[MODIFY]** `MancanoSync/0-meta/llm-reviews/README.md` — linha no inventário
*   **[DELETE]** `MancanoSync/9-vers/` e `MancanoSync/0-governance/` (vazias após o resgate)

### WP5 — Densidade do CLAUDE.md (meta corrigida)

**Correção de premissa** (2026-07-27, após benchmarking § 0.7): a versão anterior deste WP dizia "reduzir para <200 linhas" e afirmava que o arquivo estava muito acima do alvo. **Estava errado** — a estimativa foi inferida de bytes, não de linhas contadas:

| | Linhas | Bytes |
|---|---:|---:|
| `CLAUDE.md` do template | 140 | 15.651 |
| `CLAUDE.md` da raiz MancanoSync | 130 | 14.504 |
| `AGENTS.md` do `microsoft/agent-governance-toolkit` | 130 | 7.530 |
| Alvo oficial Anthropic | <200 | — |

Ambos já estão **dentro** do limite de linhas. O problema real é **densidade**: mesma contagem de linhas que a referência da Microsoft, com o dobro de bytes — parágrafos longos de prosa onde deveria haver estrutura.

**Meta revista**: não cortar linhas, e sim converter prosa em estrutura, no modelo do `AGENTS.md` da Microsoft (mapa e roteamento, não exortação — ver § 0.7 item 7). Toda proibição que virar trava física no WP10 sai do texto por consequência.

*   **[NEW]** `.claude/rules/governanca-planos.md` (`paths: ["<gov>/plan/**"]`)
*   **[NEW]** `.claude/rules/governanca-commits.md`
*   **[NEW]** `.claude/rules/governanca-llm-reviews.md` (`paths: ["<gov>/llm-reviews/**"]`)
*   **[MODIFY]** `CLAUDE.md` — prosa → estrutura; alvo de **densidade** ≤ 8KB, mantendo <200 linhas

### WP6 — Compartilhamento oficial
*   **[MODIFY]** `.claude/skills/sync-skills/SKILL.md` + `tools/sync-skills.ps1`/`.sh` — reposicionar para skills; regras passam a ser symlink
*   **[NEW]** documentação do symlink de `.claude/rules/shared`

### WP7 — Nome do diretório (por último)
*   Decisão por repositório. Ver § 4.

### WP8 — Dois ritmos de trabalho (elimina fadiga de conformidade)

O regime atual exige plano + `NEWS.md` + `TODO.md` para **qualquer** mudança. Isso é caro demais para trabalho rotineiro, e regime caro demais é contornado — o que degrada justamente os registros que ele deveria proteger.

**Gatilho mecânico** (não percentual, não julgamento do agente). Fluxo Arquitetural é obrigatório se a mudança:
1. toca mais de um repositório; **ou**
2. cria, renomeia ou deleta diretório de topo; **ou**
3. altera `tools/`, `hooks/` ou `.claude/`; **ou**
4. muda convenção de governança (formato de plano, regra de commit, timestamp).

**Todo o resto é Fluxo Rápido**: staging cirúrgico + commit direto, sem plano, sem `NEWS.md`, sem `TODO.md`.

*   **[MODIFY]** `CLAUDE.md` — declarar os dois fluxos e o gatilho
*   **[MODIFY]** `hooks/pre-commit` — detectar as 4 condições e só então cobrar `NEWS.md`
*   **[MODIFY]** `.claude/skills/close-task/SKILL.md` — cerimônia completa só no Fluxo Arquitetural

### WP9 — Auditoria silenciosa (zero token de contexto)

*   **[NEW]** `Stop` hook em `.claude/settings.json` que dispara o exportador ao fim da sessão
*   **[MODIFY]** `tools/export_conversa.R` — registrar sozinho a linha no inventário do `llm-reviews/README.md` (hoje é trabalho manual do agente, e é o que realmente custa token — o export em si já custa zero)
*   **[AVALIAR]** **SpecStory** como substituto: salva conversas em `.specstory/history/` como Markdown versionado, revisável em PR. Resolve o mesmo problema com ferramenta mantida por terceiro. Decisão do autor: manter script próprio ou adotar. Referência: `specstoryai/agent-skills` (30★), `alimoradi296/claude-session-exporter` (Stop hook, implementação mínima).
*   **[MODIFY]** `CLAUDE.md` — remover a RULE 3 (exportar manualmente) quando o hook estiver ativo

### WP10 — Travas de código no lugar de promessas de texto

A doc oficial do Claude Code é explícita: *"Claude treats them as context, not enforced configuration. To block an action regardless of what Claude decides, use a PreToolUse hook instead."* Boa parte das proibições do `CLAUDE.md` são exatamente do tipo que a doc diz não ser garantido.

*   **[NEW]** `PreToolUse` hook bloqueando `git add .` / `git add -A` **no momento da chamada** (superior ao `pre-commit`, que só reage depois do staging montado)
*   **[NEW]** Verificação de ativação de hooks — **não** configurar `core.hooksPath` no setup: já está feito (`setup.ps1:78`, `setup.sh:67`, documentado no `README.md:75`). A versão anterior deste item afirmava a falta sem conferir; corrigido em 2026-07-27.
    O buraco real é **silêncio**: os *arquivos* de hook viajam no clone (estão versionados em `hooks/`), mas a *ativação* (`core.hooksPath`) é config local e não viaja — e nada avisa quando falta. Auditoria feita: `quarto-tts-reader` está **sem** `hooksPath` (consumidor que nunca rodou o `setup`), e a raiz `MancanoSync` está sem por decisão documentada. Adotantes externos que copiam arquivos em vez de rodar o `setup` (§ 0.5) ficam na mesma situação, sem sinal.
    Ação: fazer o `SessionStart` hook e/ou o `check-integrity` **falharem ruidosamente** quando `core.hooksPath` não estiver configurado — mesmo princípio do `denyOnPolicyError: true` da Microsoft (§ 0.7 item 2). Governança que falha em silêncio é indistinguível de governança ausente.
*   **[NEW]** `tools/check-integrity.ps1` / `.sh` — validador sem dependência de R. **R é dependência pesada demais para um template público**: adotantes externos (§ 0.5) provavelmente não o têm instalado, e hoje toda a validação depende dele.
*   **[MODIFY]** `CLAUDE.md` — remover as proibições que passaram a ser trava física (deixar de gastar contexto repetindo o que o ambiente já impede)

### WP11 — Caminhos absolutos locais (levantado pelo autor, 2026-07-28)

O autor apontou os caminhos absolutos como "um grande problema nos repositórios atualmente, incluindo governança". Levantamento mecânico confirma:

| Repositório | Arquivos | Ocorrências |
|---|---:|---:|
| `Mancano2026-MA-Thesis` | 172 | **9.895** |
| `Nahoum-Mancano-2026-Antitrust` | 7 | 419 |
| `MancanoSync` (raiz) | 8 | 73 |
| `agentic-research-template` | 3 | 73 |
| `agentic-institutionalism` | 3 | 58 |
| `skills` | 5 | 20 |
| **`cha-affirmative-action-us-brazil`** | **0** | **0** |

Distribuição na tese: 171 arquivos em `9-vers/`, 166 em `4-DA-Code/`, 8 em `3-texts/`, 1 no `NEWS.md`. Forma típica: `file:///c:/Users/Mancano/Documents/MancanoSync/...` em links de Markdown.

**Por que o validador não pegou.** A checagem existe, com dois furos: **T1** varre apenas `.R`/`.qmd` staged — Markdown de governança fica fora; e **T5** cobre `NEWS.md` mas só **linhas adicionadas**, então o que já estava no arquivo nunca é reexaminado. O furo decisivo é outro: a raiz `MancanoSync` está com **`core.hooksPath` desconfigurado** (§ WP10), então o validador **nunca roda lá** — é por isso que ela acumulou 73 ocorrências sem nenhum alerta. Mesma classe de falha do "falha em silêncio".

**O que torna a limpeza não-trivial.** A maior parte das ocorrências da tese está em `9-vers/llm-reviews/` — **transcrições verbatim de sessões**, que a governança deste ecossistema proíbe reescrever. A limpeza precisa separar dois regimes:

| Regime | Exemplos | Ação |
|---|---|---|
| **Autorado** | links no `NEWS.md`, planos, `CLAUDE.md`, `README.md`, código em `4-DA-Code/` | corrigir para caminho relativo |
| **Arquivado** | `llm-reviews/*.md`, entradas antigas do `NEWS.md` | **nunca tocar** — registro histórico |

`cha-affirmative-action-us-brazil` com zero ocorrências é a prova de que o estado limpo é alcançável.

*   **[NEW]** Checagem no `check-integrity` (WP10) varrendo **todo** Markdown autorado, não só linhas adicionadas, com exclusão explícita de `llm-reviews/` e do histórico do `NEWS.md`
*   **[MODIFY]** Limpeza dos caminhos autorados, repositório por repositório, começando pelos de menor volume (`skills`, `institucionalismo`, template) e deixando a tese por último
*   **[DEPENDE DE]** WP10 — enquanto `core.hooksPath` puder ficar desconfigurado em silêncio, qualquer limpeza volta a sujar

---

## 2. Cronograma de Tarefas (Checklist)

### WP0 — Pré-requisito
- [ ] Ativar Developer Mode no Windows
- [ ] Validar: `New-Item -ItemType SymbolicLink` sem elevação em pasta de teste

### WP1 — Fim dos hard links
- [ ] Reescrever `setup.ps1`/`setup.sh` para symlink `AGENTS.md → CLAUDE.md`
- [ ] Remover a seção 0 do `validate-governance.R`
- [ ] Remover `HARD LINK RULE` do `CLAUDE.md`
- [ ] Deletar `9-vers/backups/`
- [ ] **Antes de deletar `AGENTS.md` para recriar como symlink**: conferir se ele contém conteúdo que não está no `CLAUDE.md` (os 3 repos divergentes podem ter deriva em qualquer direção)
- [ ] Aplicar nos 9 repositórios com par `CLAUDE`/`AGENTS`

### WP2 — Remoção dos redundantes
- [ ] Rodar `/init` com `CLAUDE_CODE_NEW_INIT=1` **antes** de deletar, para absorver o que houver de útil
- [ ] Deletar `.github/copilot-instructions.md` (6 repos)
- [ ] Deletar `.cursor/rules/` (4 repos)
- [ ] Atualizar organograma no `README.md`

### WP3 — Indireção real
- [ ] Portar `PATH_GOV_DIR` do repo `skills` para o `validate-governance.R` do template
- [ ] Portar a detecção para `export_conversa.R`
- [ ] Adicionar `diretorio_governanca` à tabela do `CLAUDE.md` do template
- [ ] Reescrever as 4 skills para consultar a chave
- [ ] **Teste de regressão**: rodar o exportador num repo `0-meta` e num `9-vers`, confirmar destino correto nos dois

### WP4 — Resgate dos órfãos
- [ ] Mover o export de 2026-07-26 para `0-meta/llm-reviews/`
- [ ] Registrar no inventário
- [ ] Conferir se os 2 `.bak` de `0-governance/` têm conteúdo único; se não, deletar
- [ ] Remover as duas pastas órfãs

### WP5 — Densidade
- [ ] Rodar `/doctor` para a proposta automática de cortes
- [ ] Extrair as regras para `.claude/rules/` com `paths:`
- [ ] Converter prosa em estrutura seguindo o modelo do `AGENTS.md` da Microsoft (§ 0.7 item 7): roteamento e escalonamento, não exortação
- [ ] Confirmar **≤ 8KB** mantendo <200 linhas (meta de densidade, não de linhas — ver correção no WP5)
- [ ] Validar com `/context` que tudo carregou

### WP6 — Compartilhamento
- [ ] Criar `~/shared-claude-rules/` com as regras de governança
- [ ] Symlink em 1 repo piloto; validar com `/context`
- [ ] Propagar; reposicionar `sync-skills` para skills apenas

### WP7 — Nome
- [ ] Decidir por repositório (§ 4)

### WP8 — Dois ritmos
- [ ] Escrever a policy no formato `allow`/`review`/`deny` (§ 0.7 item 1), com `defaultEffect: "review"`
- [ ] Traduzir as 4 condições do gatilho mecânico em `pathRules`
- [ ] `CLAUDE.md` declara os dois fluxos; `hooks/pre-commit` só cobra `NEWS.md` no Fluxo Arquitetural
- [ ] Testar: mudança trivial num arquivo commita sem cerimônia; mudança em `tools/` exige plano

### WP9 — Auditoria silenciosa
- [ ] `Stop` hook em `.claude/settings.json` disparando o exportador
- [ ] Exportador registra sozinho a linha no inventário
- [ ] **[AVALIAR, decisão do autor pendente]** hash encadeado no inventário (§ 0.7 item 4)
- [ ] **[AVALIAR, decisão do autor pendente]** SpecStory — autor instalou a extensão em 2026-07-27 e está testando. Ressalva levantada: integrações são Cursor e VS Code+Copilot; **não cobre Antigravity**, que hoje gera 2 dos 3 exports do template
- [ ] Remover a RULE 3 do `CLAUDE.md` só depois do hook validado

### WP10 — Travas de código
- [ ] `PreToolUse` hook bloqueando `git add .` / `git add -A`, no formato `id` + `reason` + padrão + exceções (§ 0.7 item 3)
- [ ] Fazer o validador **falhar ruidosamente** quando `core.hooksPath` não estiver configurado
- [ ] Corrigir `quarto-tts-reader` (sem `hooksPath`, achado na auditoria)
- [ ] `tools/check-integrity.ps1`/`.sh` sem dependência de R
- [ ] Remover do `CLAUDE.md` as proibições que viraram trava física
- [ ] Testar que a trava dispara de fato: tentar `git add .` e confirmar bloqueio com mensagem legível

---

## 3. Ordem de propagação entre repositórios

**Ordem obrigatória**, do mais seguro para o mais crítico:

1. **`agentic-research-template`** (mãe) — todo WP nasce aqui.
2. **`skills`** — segundo consumidor mais simples; já tem o `PATH_GOV_DIR`, serve de conferência cruzada.
3. **`quarto-tts-reader`** ou **`Annotated-Bibliography`** — piloto real, consumidor parcial, risco baixo.
4. **`MancanoSync` (raiz)** — inclui o WP4.
5. **`cha-affirmative-action-us-brazil`**, **`agentic-institutionalism`**, **`Nahoum-Mancano-2026-Antitrust`**.
6. **`Mancano2026-MA-Thesis`** — **por último**, é a dissertação. Nenhuma mudança aqui antes dos outros 6 estarem estáveis por pelo menos uma sessão de trabalho real.
7. **`educabr2`**, **`folha-scraper`**, **`planning-repo`** — só ganham `AGENTS.md` se o autor quiser; hoje não têm.

**Regra de parada**: se qualquer WP falhar em 2 repositórios seguidos, parar a propagação e escalar ao autor. Não seguir "consertando na frente".

---

## 4. Sobre o nome do diretório (`9-vers` vs `0-meta`) — a conclusão que inverte a pergunta original

A pergunta que originou esta rodada foi "qual o melhor nome para a pasta". A resposta, depois do diagnóstico: **com o WP3 feito, a pergunta deixa de importar.**

Motivos:

1. **`9-vers` é correto onde nasceu.** Nos repositórios de pesquisa ele é o slot 9 de uma taxonomia numerada viva (`2-set/`, `3-texts/`, `4-DA-Code/`, `6-images-tables/`, `9-vers/`). Renomear ali **destruiria** significado. `Mancano2026-MA-Thesis` e `Nahoum-Mancano-2026-Antitrust` devem **manter `9-vers`**.
2. **`0-meta` é correto onde está.** Na raiz e no `skills` não há taxonomia numerada; `0-` ordena no topo e `meta` descreve honestamente um conteúdo heterogêneo.
3. **Com `PATH_GOV_DIR`, os dois funcionam para sempre**, e a divergência entre repositórios deixa de ser dívida e passa a ser adequação local.

**Recomendação**: no template, renomear `9-vers/` → `0-meta/` (converge com a maioria e com o fallback já escrito), **manter `9-vers` nos dois repositórios de pesquisa**, e **nunca mais tratar isto como migração**.

**Sobre `backups/`**: sai do diretório de governança de qualquer forma — em WP1 ele deixa de existir junto com o self-heal. Com isso o diretório passa a conter apenas planos + trilha de auditoria, que é um conjunto coerente e bem descrito tanto por `meta` quanto por `governance`.

**Não dividir a pasta em múltiplas** nesta rodada. Dividir agora triplicaria o número de caminhos fixados no código — exatamente o bug que este plano existe para matar. Reavaliar depois do WP3, quando dividir custar uma variável em vez de uma caçada a strings.

---

## 5. Plano de Validação e Verificação

### Testes automatizados
```
Rscript tools/validate-governance.R          # deve passar em repo 0-meta E em repo 9-vers
```

### Verificação mecânica por WP

**WP1** — o link é symlink e aponta certo:
```powershell
(Get-Item AGENTS.md).LinkType      # -> SymbolicLink
(Get-Item AGENTS.md).Target        # -> CLAUDE.md
```
Teste de resistência (o que o hard link não passava): editar `CLAUDE.md` no VS Code, salvar, e confirmar que `AGENTS.md` continua sendo symlink e reflete a mudança.

**WP3** — o teste que prova a indireção:
```bash
# num repo 0-meta e num repo 9-vers:
Rscript tools/export_conversa.R <uuid> teste-indirecao
git status --porcelain --ignored | grep -i "llm-reviews"
```
O arquivo deve nascer **rastreado** nos dois casos. Este é o teste que teria pego o bug de 2026-07-26.

**WP5** — carregamento e tamanho:
```
/context     # confirmar CLAUDE.md e rules em "Memory files"
```
```powershell
(Get-Content CLAUDE.md | Measure-Object -Line).Lines   # < 200 (já atendido hoje: 140)
(Get-Item CLAUDE.md).Length                            # <= 8192 — a métrica que importa
```

**WP10** — a trava dispara de fato (não basta existir):
```bash
git add .          # deve ser BLOQUEADO, com mensagem legível citando a regra
git config --get core.hooksPath   # ausente => o validador deve falhar RUIDOSAMENTE
```

**WP2** — verificar que nenhuma referência ficou órfã:
```bash
grep -rn "copilot-instructions\|\.cursor/rules" . --exclude-dir=.git
```

### Verificação manual
- Abrir um repo migrado no **Cursor** e outro no **VS Code + Copilot**, e confirmar que ambos veem as instruções via `AGENTS.md`.
- Rodar uma tarefa real de `close-task` num repo migrado, de ponta a ponta.

### Rollback
Cada WP é um commit isolado e revertível com `git revert`. Riscos que exigem cuidado extra:
- **WP1** deleta e recria `AGENTS.md`. Antes de deletar em cada repo, salvar cópia fora da árvore; nos 3 repos com link quebrado, `AGENTS.md` pode conter conteúdo ausente no `CLAUDE.md`.
- **WP4** move arquivo hoje **fora do git** — sem rede de segurança do versionamento. Copiar antes de mover.
- **WP2** deleta arquivos rastreados: recuperáveis pelo histórico.

---

## 6. Riscos e questões em aberto

| # | Risco / questão | Mitigação |
|---|---|---|
| 1 | Autor não quer ativar Developer Mode | Fallback: hook `pre-commit` copiando `CLAUDE.md`→`AGENTS.md`. Preserva a direção canônica, custa um passo de build. |
| 2 | Symlink e Syncthing/Google Drive | Ambos pausados hoje (CLAUDE.md da raiz), mas **confirmar antes de reativar** — sincronizadores tratam symlink de forma inconsistente. Registrar no `TODO.md` da raiz. |
| 3 | Symlink dentro de worktrees git | Validar no piloto: este próprio plano nasceu num worktree. |
| 4 | `AGENTS.md` deixa de ser arquivo real no GitHub | Symlink aparece como ponteiro na UI web. Se incomodar, usar o fallback do risco 1. |
| 5 | Deriva entre as 3 skills já divergentes | Resolver o merge **antes** do WP6; escolher a versão vencedora por skill com o autor. |
| 6 | "Copilot lê AGENTS.md desde ago/2025" sem fonte primária | Confirmar na doc do GitHub antes de deletar o `copilot-instructions.md` do repo da dissertação. |
| 7 | Template é **público** com adotante externo (§ 0.5) | `NEWS.md` do WP2/WP7 redigido para leitor externo; nota de migração no `README.md`. Não tratar a mudança como interna. |
| 8 | Retrabalho vs. ferramenta existente | Ler `carlrannaberg/claudekit` § `agents-md/migration.md` **antes** do WP1 — pode substituir parte do script próprio. |

---

## 6b. Nota sobre os timestamps desta rodada (relógio do sistema divergente)

Durante a execução de 2026-07-27/28, o relógio do sistema desta máquina reportava horários **cerca de 5h45 atrasados** em relação ao horário real, confirmado pelo autor (`Get-Date` retornava ~02:05 quando eram ~07:51). A divergência foi corroborada por um carimbo independente: a entrada (55) do `NEWS.md` da dissertação, escrita por outra sessão, marca 07:22 — coerente com o relógio do autor, não com o do sistema.

As entradas de `NEWS.md` escritas nesta sessão em `agentic-research-template`, `skills`, `MancanoSync` (raiz), `cha-affirmative-action-us-brazil`, `Nahoum-Mancano-2026-Antitrust` e `agentic-institutionalism` carregam horários derivados do relógio errado e **não foram reescritas retroativamente**, conforme a regra de que entradas de `NEWS.md` nunca são reescritas. A ordem relativa entre elas está correta; apenas o horário absoluto está deslocado. A entrada da dissertação (56) já usa o horário corrigido.

**Consequência para a governança**: a convenção de timestamp deste ecossistema manda usar "o timestamp real do turno no log da sessão, não uma estimativa de memória" — mas nada verifica se o relógio da máquina está certo. Um agente seguindo a regra à risca produz timestamps errados sem perceber. Item a considerar no `check-integrity` do WP10.

---

## 7. Nota sobre governança deste próprio plano

Este plano toca repositórios filhos a partir de uma sessão do template. Conforme a proibição estrita do `CLAUDE.md` da raiz ("nunca opere dentro dos repositórios filhos sem plano `ATIVO` que mencione o repo explicitamente"), **os 12 repositórios estão nomeados no § 0.1 e no § 3**, e a execução em cada um exige que este plano esteja `ATIVO` e aprovado pelo autor.

Nenhuma modificação foi feita em nenhum repositório até a criação deste documento.

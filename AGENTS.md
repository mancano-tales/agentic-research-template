# CLAUDE.md — [NOME DO SEU PROJETO]

> 🚨 **CRITICAL AGENT RULES (COVENANT) — READ FIRST:**
> - **RULE 1:** You are operating under the **Agent Covenant** framework. Every commit is audited. Run `Rscript tools/validate-governance.R` to test your edits before committing.
> - **RULE 2:** Any modification in the main source directories REQUIRES an update in the root `NEWS.md` file.
> - **RULE 3:** When completing a task or plan, you MUST run the conversation exporter to save your session log.
> - **For humans:** this file is for AI operating context. See [GUIDANCE.md](GUIDANCE.md) for the sitemap.

---

## Current State of the Project (version dated YYYY-MM-DD)

> **Esta seção é a única fonte de verdade sobre a concepção ATUAL do projeto.** Alterações de design, arquitetura e decisões de negócio devem ser registradas aqui com a data correspondente. Versões arquivadas ou planos antigos em conflito com esta seção devem ser desconsiderados pelos agentes.

- **Descrição Geral**: [Descreva em 1 ou 2 parágrafos o que é o projeto, qual o seu objetivo central e proposta de valor.]
- **Arquitetura / Componentes principais**:
  - [Componente 1]: [Função e caminhos de arquivo]
  - [Componente 2]: [Função e caminhos de arquivo]
- **Proibições Estritas (Standing Prohibitions)**:
  - Nunca execute `git add .` ou `git add -A`. Apenas adicione os arquivos específicos modificados (`git add <file>`).
  - **[PLACEHOLDER - PROTEÇÃO DE AUTORIA]**: Se este projeto tem um diretório de autoria humana primária (prosa, notebooks de pesquisa, etc.) onde edições não devem ser comitadas silenciosamente por agentes, declare-o aqui nomeadamente. Exemplo: "Nunca faça commit na pasta `textos/` sem aprovação humana."
  - **[PLACEHOLDER - PROTEÇÃO DE EXTERNOS]**: Se este projeto tem um arquivo gerenciado por uma ferramenta externa (biblioteca de citação, schema gerado, lockfile), proíba EDIÇÃO manual por agentes aqui — mas note explicitamente que comitar esse arquivo sem editá-lo é seguro (a distinção entre 'não editar' e 'não comitar' gera confusão). Exemplo: "Nunca edite manualmente o arquivo `zotero.bib`."
  - [Adicione outras proibições do seu projeto aqui...]
- **Planos ativos**: consulte o índice de status em `9-vers/plan/README.md`.

---

## Guidance Documents: Map and Precedence Rules

**Regras de Precedência:**
1. Em caso de conflito, a seção "Current State" acima + o plano ativo em `9-vers/plan/` correspondente prevalecem sobre qualquer outro documento.
2. Arquivos marcados com banner de desatualização/arquivamento são mantidos apenas para histórico e não devem orientar o trabalho corrente.
3. Cada documento de diretriz possui uma função única (tabela abaixo).

**Map of guidance documents** (what orients agents and humans, and what each file is for):

| Document | Audience | Function | Update trigger |
|---|---|---|---|
| `CLAUDE.md` (this file) | Agents | CURRENT state of the research, conventions, gotchas, this map | Conception/design change |
| `AGENTS.md` (this file also)| Agents | Hard link to CLAUDE.md | Conception/design change |
| `TODO.md` | Both | Append-only task log — 3 seções (Pendente/Prospectivo/Concluído), item novo no topo, cada item com data+hora e agente/humano de criação e conclusão, e link para o plano em `9-vers/plan/` quando complexo | Toda sessão que cria, promove ou conclui uma tarefa |
| `README.md` | Humans | What the project is, repo map, how to build | Structural repo change |
| `GUIDANCE.md` / `9-vers/GUIDANCE_MAP.md` | Both | Master sitemap of directory structures and guidance documents | Repository layout or guideline change |
| `NEWS.md` (root) | Both | Intellectual changelog — history, never rewritten | Every session with a relevant decision |
| `9-vers/plan/README.md` | Both | **Status index of all plans** (ATIVO/CONCLUÍDO/…) | Any plan created or changing status |
| `9-vers/plan/*.md` | Both | Dated plans; the ATIVO ones guide current work | New plan per work round |
| `9-vers/llm-reviews/README.md` | Both | Convention for archived LLM conversations/reviews | Convention change |

---

## Git and LLM Documentation Conventions for AI Agents

- **Commits Permitidos**: Os agentes de IA estão autorizados a fazer commits diretamente no repositório.
- **Política de Staging Cirúrgico**: Agentes **NUNCA** devem utilizar `git add .`. Devem adicionar cirurgicamente apenas os arquivos nos quais trabalharam (ex: `git add src/main.js`). Isso preserva o trabalho em andamento do autor humano.
- **Synchronized Commit Policy (Co-committing)**: Cada commit contendo mudanças de funcionalidade ou documentação deve obrigatoriamente incluir a atualização do [NEWS.md](NEWS.md) (e o status do plano em `9-vers/plan/README.md` se aplicável) na *mesma transação de commit*. Todo log de agente no `NEWS.md` deve terminar com o bloco **Metadados de Execução**:
  - **Timestamp rigor**: a data isolada não é suficiente. Todo timestamp nos artefatos de governança deste repositório — o cabeçalho de entrada no `NEWS.md` (`## YYYY-MM-DD HH:MM — Título`), o campo `**Data/Hora**` no bloco de Metadados de Execução abaixo, e os campos YAML `criado`/`concluido` em `9-vers/plan/*.md` — **devem incluir hora e minuto**, no formato `YYYY-MM-DD HH:MM`, [seu fuso horário local]. Se a hora exata não puder ser recuperada confiavelmente do log da sessão, deixe apenas a data e explique o motivo em um comentário — nunca invente um horário.
  ```markdown
  **Metadados de Execução**:
  - **Data/Hora**: YYYY-MM-DD HH:MM (Horário Local)
  - **Agente**: [Nome do Agente] / [Modelo] / [Plataforma]
  - **Mensagem do Commit**: "sua mensagem aqui"
  - **Arquivos afetados**: caminho/do/arquivo1, caminho/do/arquivo2
  ```
- **Auditoria de Conversas**: Ao final de cada sessão, o agente deve exportar o histórico de conversa rodando o script:
  `Rscript tools/export_conversa.R <session_uuid> [slug]`
  E registrar a nova entrada na tabela de inventário em `9-vers/llm-reviews/README.md`.
- **Limites de Alteração e Segurança**:
  - **Sem exclusões não autorizadas**: Nunca delete arquivos de configuração, código-fonte, dependências ou bancos de dados sem autorização humana expressa.
  - **Escopo restrito**: Restrinja suas edições cirurgicamente aos arquivos mapeados no plano ativo. Refatorações globais ou alterações de dependências fora de plano são estritamente proibidas.
  - **Substituição incremental**: Prefira sempre editar blocos de código específicos (chunks) em vez de reescrever arquivos inteiros, economizando tokens e evitando a perda acidental de lógica de negócios.

---

## Skills Compartilhadas Entre Projetos

Este template é o **repositório mãe** de um conjunto de skills usadas por vários projetos correlatos:

- **Skills de governança, autoria própria** (`close-task`, `request-audit`, `export-conversation`, `git-cleanup`, `sync-skills`, `pdf-text-extractor`): **byte-idênticas** em todo repositório que as usa — nunca hardcodeiam caminho, nome de arquivo ou convenção específica de um projeto. Qualquer particularidade de repositório vem da seção **"Configuração de Skills"** abaixo, nunca do texto da própria skill — isso é o que permite comparar skills por hash entre repositórios e ter um sinal de "em dia"/"desatualizada" que significa alguma coisa de verdade (ver histórico da decisão em `9-vers/plan/2026-07-14_Plano_Skills_Compartilhadas_TODO.md`).
- **Skills portadas de terceiros** (`grill-me`, `grilling`, `grill-with-docs`, `edit-article`, `code-review`): de [mattpocock/skills](https://github.com/mattpocock/skills) (licença MIT), instaladas em 2026-07-14 a pedido do autor após uma triagem ("grill") das ~32 skills do repositório original — a maioria é específica de projetos TypeScript/Node e não se aplica aqui. Instaladas fielmente ao original (mesmo texto, mesmos arquivos `agents/openai.yaml` de interoperabilidade), sem adaptar ao padrão config-driven acima — não são deste projeto, não faz sentido reescrevê-las. **Gaps conhecidos, não corrigidos**: `grill-with-docs` referencia uma skill `/domain-modeling` do repositório original que não foi instalada (a interview roda, mas a geração de ADR/glossário via domain-modeling não vai funcionar até essa skill ser adicionada); `code-review` referencia `docs/agents/issue-tracker.md`/`/setup-matt-pocock-skills`, que não existem aqui — degrada graciosamente (pula o eixo Spec e avisa), não quebra.

Consumidores puxam atualizações com `tools/sync-skills.ps1`/`.sh` (relatório por padrão; `-Apply <skill>` para aplicar) ou pela skill `sync-skills`, que envolve o script com a cerimônia de revisão e commit explícito — nunca há sincronização automática/silenciosa nem link físico entre repositórios (junctions/symlinks entre repositórios distintos já se mostraram frágeis sob renomeação de pasta e sincronização de nuvem). O script compara a **pasta inteira** de cada skill (não só o `SKILL.md`) — algumas skills têm arquivos auxiliares junto (`pdf-text-extractor/scripts/`, `agents/openai.yaml` nas portadas de terceiros). Se este projeto **é** o repositório mãe, edite as skills direto em `.claude/skills/`; se é um consumidor, veja `.claude/skills/sync-skills/SKILL.md` para o fluxo completo.

**Invocação — `disable-model-invocation`**: nenhuma das skills de governança usa essa flag hoje (decisão do autor, 2026-07-14 — testada e depois revertida). Das portadas de terceiros, `grill-me`, `grill-with-docs` e `edit-article` vinham com a flag `true` do próprio Matt Pocock (ele as trata como ações só-por-pedido-explícito); **mudado para `false` em 2026-07-17 (decisão do autor)** — ele quer as três model-invoked como as demais, e a interoperabilidade `agents/openai.yaml` de cada uma foi atualizada em conjunto (`allow_implicit_invocation: true`) para não divergir entre plataformas. `grilling` e `code-review` seguem sem a flag (já eram model-invoked).

---

## Skills Globais Disponíveis Neste Ambiente

> ⚠️ **Isto documenta o que está instalado nesta máquina/usuário em 2026-07-14, não este projeto.** Diferente das skills em `.claude/skills/` (versionadas, viajam com o repositório), plugins globais do Claude Code vivem em `~/.claude/plugins/` — locais por máquina/usuário, **não vêm junto num clone**. Se você está lendo isto num clone novo ou noutra máquina, **não assuma que o pacote abaixo está instalado** — confira com `/plugin list` antes de confiar nesta tabela. Esta seção existe deliberadamente fora de `sync-skills/SKILL.md` (onde foi colocada por engano numa rodada anterior — ver auditoria em `9-vers/plan/2026-07-14_Prompt_Auditoria_Sync-Skills-Superpowers.md`): `sync-skills` documenta sincronização de skills *de projeto*; isto é inventário de máquina, escopo diferente.

**Regra de convivência**: se uma tarefa é coberta por uma skill global listada abaixo, use-a — as skills de projeto (`close-task`, `git-cleanup`, etc.) tratam de governança específica do repositório, as globais tratam de processo de desenvolvimento geral; elas se complementam, não se substituem. **Atenção especial a `using-superpowers`**: ao contrário das outras 13, ela não é "use quando aplicável" — o próprio `SKILL.md` dela exige invocação obrigatória ("YOU ABSOLUTELY MUST invoke the skill... not negotiable") sempre que houver qualquer chance de aplicação, no início de qualquer conversa. Isso pode competir por atenção com os SOPs deste repositório (`close-task`, `git-cleanup`) — as instruções do usuário sempre prevalecem sobre ambos.

### `superpowers` (pacote instalado via plugin, confirmado em `~/.claude/plugins/cache/claude-plugins-official/superpowers/5.1.0/skills/`)

| Skill | Quando usar |
|---|---|
| `superpowers:using-superpowers` | Ponto de entrada — invocação obrigatória por design (ver aviso acima), não apenas "quando aplicável" |
| `superpowers:brainstorming` | Antes de qualquer trabalho criativo: criar features, componentes ou modificar comportamento |
| `superpowers:writing-plans` | Ao receber spec ou requisitos de tarefa multi-passo, antes de tocar qualquer arquivo |
| `superpowers:executing-plans` | Ao executar um plano já escrito — em sessão separada, com checkpoints de revisão |
| `superpowers:subagent-driven-development` | Ao executar planos com tarefas independentes na sessão atual |
| `superpowers:dispatching-parallel-agents` | Ao enfrentar 2+ tarefas independentes que podem rodar sem estado compartilhado |
| `superpowers:using-git-worktrees` | Antes de feature work que precisa de isolamento do workspace atual |
| `superpowers:test-driven-development` | Antes de escrever código de implementação de qualquer feature ou bugfix |
| `superpowers:systematic-debugging` | Ao encontrar qualquer bug, falha de teste ou comportamento inesperado |
| `superpowers:requesting-code-review` | Ao concluir implementações ou antes de merge |
| `superpowers:receiving-code-review` | Antes de implementar sugestões de review, especialmente se parecerem questionáveis |
| `superpowers:verification-before-completion` | Antes de declarar trabalho concluído, antes de `close-task` |
| `superpowers:finishing-a-development-branch` | Quando implementação está completa e é preciso decidir como integrar |
| `superpowers:writing-skills` | Ao criar ou editar skills — use antes de promover uma skill local para a mãe |

---

## Configuração de Skills (Skill Configuration)

> As skills genéricas acima consultam esta seção para qualquer dado específico deste repositório — nunca hardcodeiam. **As chaves (o que existe) são definidas pelas skills; o valor de cada linha é deste projeto.** Preencha ao adotar o template; deixe em branco/`[PLACEHOLDER]` se não se aplicar.

| Chave | Usada por | Valor neste repositório |
|---|---|---|
| `diretorio_autoria_primaria` | `close-task`, `git-cleanup` | [PLACEHOLDER — se este projeto tem uma pasta de prosa/notebooks de autoria humana que agentes não devem comitar sem autorização, declare o caminho aqui] |
| `arquivo_gerenciado_externamente` | `git-cleanup` | [PLACEHOLDER — se algum arquivo é escrito por uma ferramenta externa (biblioteca de citação, lockfile, schema gerado) e agentes nunca devem editá-lo manualmente, declare o caminho aqui] |
| `script_exportar_conversa` | `close-task`, `export-conversation` | `tools/export_conversa.R` (padrão do template — ajuste se movido) |
| `diretorios_trabalho_continuo` | `git-cleanup` | [PLACEHOLDER — pastas onde commits em série/numerados são normais (ex.: scripts de análise por sessão), para agrupar em vez de tratar cada arquivo isolado] |

---

## Technical Stack & Commands

### Tecnologia
- **Linguagem Principal**: R 4.4+ (ou a linguagem do seu projeto)
- **Frameworks**: [ex: FastAPI, Next.js, React]
- **Banco de Dados**: [ex: PostgreSQL, SQLite]

### Comandos Frequentes (Cheat Sheet)
*   **Build/Compilar**: `[Comando de build]`
*   **Testes Automatizados**: `[Comando de testes]`
*   **Execução Local**: `[Comando de run dev]`
*   **Instalação de Dependências**: `[Comando de install]`

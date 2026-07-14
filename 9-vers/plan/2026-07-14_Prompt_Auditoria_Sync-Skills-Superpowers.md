---
tipo: Prompt
titulo: "Auditoria — Adição de §4 (skills globais superpowers) em sync-skills/SKILL.md"
status: CONCLUÍDO
criado: "2026-07-14 12:20"
concluido: "2026-07-14 12:45"
agentes:
  orquestrador: "Claude Sonnet 4.6 (Claude Code)"
  executor: "Claude Sonnet 5 (Claude Code, VS Code)"
  auditor: "Claude Sonnet 5 (Claude Code, VS Code)"
autor_humano: "Tales Mançano"
tarefas:
  - { desc: "Auditor conduz leitura independente e emite veredito", status: concluida, data: "2026-07-14 12:40" }
  - { desc: "Corrigir achado #1 (escopo errado): mover §4 de sync-skills/SKILL.md para nova seção em CLAUDE.md, com caveat de máquina e menção explícita a using-superpowers", status: concluida, data: "2026-07-14 12:45" }
relacionados:
  - "2026-07-14_Plano_Skills_Compartilhadas_TODO.md"
  - "2026-07-14_1128_instalar-skills-superpowers_conversa-claude.md"
news: ["2026-07-14"]
---

> **Status**: ATIVO
> **O que é**: Prompt de auditoria independente (red-teaming) do trabalho realizado na sessão de 2026-07-14, especificamente a adição da seção §4 em `.claude/skills/sync-skills/SKILL.md` referenciando as skills globais do pacote `superpowers`.
> **Elaborado por**: Claude Sonnet 4.6 (Claude Code), via skill `request-audit`.
> **Por quê**: Garantir revisão independente antes de propagar a mudança para repositórios consumidores via `sync-skills`.
> **Como usar**: Copie o bloco abaixo e entregue a um agente independente (não o autor) no contexto do repositório `agentic-research-template`.

---

## Prompt de Auditoria

---

### A. Cabeçalho de Contexto

- **Agente Autor**: Claude Sonnet 4.6 / Claude Code / VS Code
- **Timestamp início**: 2026-07-14 11:28 (início da sessão conforme JSONL exportado)
- **Timestamp conclusão**: 2026-07-14 12:18 (commit `37c28f8`)
- **Plano fonte**: `9-vers/plan/2026-07-14_Plano_Skills_Compartilhadas_TODO.md`

**Evidência mecânica do escopo — `git show --stat HEAD`:**
```
commit 37c28f87d111f791c5cb63d351c866dd5ad441cd
Author: Tales Mancano <221003443+mancano-tales@users.noreply.github.com>
Date:   Tue Jul 14 12:18:56 2026 -0300

    feat(governance): reference superpowers global skills in sync-skills, close active plan

 .claude/skills/sync-skills/SKILL.md                                        |   25 +
 9-vers/llm-reviews/2026-07-14_1128_instalar-skills-superpowers_conversa-claude.md | 2293 ++++++++++++++++++++
 9-vers/llm-reviews/README.md                                                |    1 +
 9-vers/plan/2026-07-14_Plano_Skills_Compartilhadas_TODO.md                 |    5 +-
 9-vers/plan/README.md                                                       |    2 +-
 NEWS.md                                                                     |   10 +
 6 files changed, 2333 insertions(+), 3 deletions(-)
```

**Diff completo da mudança de conteúdo (`sync-skills/SKILL.md`):**
```diff
+## 4. Skills globais (plugins) — não sincronizadas, mas disponíveis
+
+Além das skills de projeto em `.claude/skills/`, existem skills instaladas como **plugins globais do Claude Code** (em `~/.claude/plugins/`). Elas estão disponíveis em qualquer projeto e **não precisam de sync** — mas o agente deve consultá-las ativamente no lugar certo do workflow.
+
+> **Regra de convivência**: se uma tarefa é coberta por uma skill global listada abaixo, use-a. As skills de projeto (`close-task`, `git-cleanup`, etc.) tratam de governança específica do repositório; as globais tratam de processo de desenvolvimento geral. Elas se complementam, não se substituem.
+
+### `superpowers` (pacote instalado via plugin)
+
+| Skill | Quando usar |
+|---|---|
+| `superpowers:using-superpowers` | Ponto de entrada — use no início de qualquer conversa para descobrir quais skills aplicar |
+| `superpowers:brainstorming` | Antes de qualquer trabalho criativo: criar features, componentes ou modificar comportamento |
+| `superpowers:writing-plans` | Ao receber spec ou requisitos de tarefa multi-passo, antes de tocar qualquer arquivo |
+| `superpowers:executing-plans` | Ao executar um plano já escrito — em sessão separada, com checkpoints de revisão |
+| `superpowers:subagent-driven-development` | Ao executar planos com tarefas independentes na sessão atual |
+| `superpowers:dispatching-parallel-agents` | Ao enfrentar 2+ tarefas independentes que podem rodar sem estado compartilhado |
+| `superpowers:using-git-worktrees` | Antes de feature work que precisa de isolamento do workspace atual |
+| `superpowers:test-driven-development` | Antes de escrever código de implementação de qualquer feature ou bugfix |
+| `superpowers:systematic-debugging` | Ao encontrar qualquer bug, falha de teste ou comportamento inesperado |
+| `superpowers:requesting-code-review` | Ao concluir implementações ou antes de merge |
+| `superpowers:receiving-code-review` | Antes de implementar sugestões de review, especialmente se parecerem questionáveis |
+| `superpowers:verification-before-completion` | Antes de declarar trabalho concluído, antes de `close-task` |
+| `superpowers:finishing-a-development-branch` | Quando implementação está completa e é preciso decidir como integrar |
+| `superpowers:writing-skills` | Ao criar ou editar skills — use antes de promover uma skill local para a mãe (seção 2 acima) |
```

**Evidência bruta de verificação — `Rscript tools/validate-governance.R` (pós-commit):**
```
ℹ  Nenhum arquivo de bibliografia configurado ou encontrado. Checagem T4 pulada.
ℹ  Localizados 3 planos indexados no README.md.
ℹ  Localizados 2 logs de conversas registrados no README.md.

✅  Auditoria de governança concluída com sucesso! Todos os arquivos estão consistentes.
```

---

### B. Diretiva de Ceticismo e Verificação Empírica (A Regra de Ouro)

> **IMPORTANTE**: Não tome nada do que o agente autor diz neste prompt pelo valor de face. O agente que escreveu o código/texto pode estar alucinando o seu próprio sucesso ou ignorando falhas lógicas. Você deve ser extremamente crítico, cético, e verificar os arquivos fisicamente de forma independente. Comece em modo leitura (visualizando arquivos, lendo diffs, conferindo a evidência mecânica de escopo e o output bruto acima). Depois de formar uma hipótese sobre um problema, você PODE e DEVE rodar comandos de verificação não-destrutivos para confirmá-la empiricamente antes de reportá-la como achado — por exemplo `Rscript tools/validate-governance.R`, verificar se as skills listadas realmente existem nos paths indicados, ou reproduzir um edge case com um script mínimo. Não aceite nem rejeite uma alegação técnica só por parecer plausível na leitura; teste.

---

### C. Escopo do Trabalho e Áreas de Vulnerabilidade

**O que foi feito:**

A skill `sync-skills/SKILL.md` recebeu uma nova seção §4 ("Skills globais (plugins) — não sincronizadas, mas disponíveis") com uma tabela de 14 skills do pacote `superpowers`, acompanhada de uma "regra de convivência" orientando o agente a usar as skills globais quando aplicável. O objetivo declarado é que, ao carregar `sync-skills` no contexto, o agente já tenha o inventário das skills globais em memória.

**Auto-crítica e fragilidades declaradas:**

1. **Lista hardcoded / staleness** — as 14 skills são citadas literalmente no SKILL.md. Se o usuário desinstalar o plugin `superpowers`, instalar um novo plugin com outras skills, ou se o pacote for atualizado com skills renomeadas/removidas, a lista fica desatualizada silenciosamente. Não há mecanismo de detecção. *Mitigação tentada*: nenhuma — aceito como risco inerente a documentação estática; a alternativa (skills inspecionarem o próprio sistema de plugins em runtime) está fora do escopo de uma SKILL.md. *Recomendação ao autor que ficou sem implementar*: adicionar uma nota explícita na seção dizendo que a lista foi gerada em data X e pode ter ficado desatualizada.

2. **Sem verificação de disponibilidade em runtime** — a tabela pressupõe que o plugin `superpowers` está instalado. Um agente rodando num repositório consumidor onde o plugin não foi instalado vai ler a tabela e tentar invocar skills inexistentes, sem aviso. *Mitigação tentada*: a §4 diz "Elas estão disponíveis em qualquer projeto" — o que é falso se o plugin não estiver instalado globalmente. *Risco não mitigado.*

3. **Acoplamento a nome de pacote específico** — a seção é inteiramente dedicada ao pacote `superpowers`. Se o usuário instalar outros plugins com skills relevantes, não há padrão definido para adicioná-los à mesma seção ou criar uma §5. A estrutura não é extensível por convenção. *Mitigação tentada*: nenhuma.

4. **Regra de convivência sem exemplos concretos** — a "Regra de convivência" orienta usar a skill global quando aplicável, mas não fornece exemplos de sobreposição real (ex.: "use `systematic-debugging` em vez de abrir um issue direto no GitHub"). Sem exemplos, a regra é ambígua para o agente. *Mitigação tentada*: a tabela "Quando usar" já fornece contexto por skill, o que compensa parcialmente.

5. **Path `~/.claude/plugins/` referenciado no corpo** — o SKILL.md menciona `~/.claude/plugins/` como localização dos plugins globais. Isso é um caminho que varia por plataforma (Windows usa `%APPDATA%` ou `$HOME`). Não é um caminho absoluto *local* no sentido da checagem T1/T5 do validator, mas pode confundir usuários Linux/Mac. *Risco baixo, não mitigado.*

---

### D. Formato de Resposta Exigido do Auditor

Retorne a análise estruturada com:

1. **Avaliação Geral**: análise qualitativa da robustez da mudança — ela cumpre o objetivo declarado? A abordagem (documentação estática vs. inspeção dinâmica) é adequada para o contexto?

2. **Veredito Categórico** (escolha exatamente um):
   - `[APROVADO]` — solução robusta, pronta para propagar via `sync-skills` aos repositórios consumidores.
   - `[REQUER REFATORAÇÃO MENOR]` — pequenos ajustes antes de propagar.
   - `[REQUER REFATORAÇÃO ESTRUTURAL]` — vulnerabilidades graves que tornam a propagação prematura.
   - `[DESCARTADO]` — abordagem incorreta desde a premissa.

3. **Lista de Achados** (ordenada do mais grave ao menos grave). Cada achado deve ter:
   - **Resumo de uma frase** do defeito.
   - **Cenário de falha concreto**: input/estado específico → output errado. Não "pode falhar" — sim "agente X rodando em repositório Y sem o plugin instalado vai tentar invocar `superpowers:brainstorming`, receber erro Z".
   - **Veredito do achado**: `CONFIRMED` (reproduziu empiricamente) ou `PLAUSIBLE` (identificado por leitura/raciocínio).

---

### E. Teto de Rodadas

> Se o veredito for `[REQUER REFATORAÇÃO MENOR]` ou `[REQUER REFATORAÇÃO ESTRUTURAL]`, o agente executor deve corrigir os itens e pode pedir **no máximo mais uma rodada** de auditoria independente. Se a segunda rodada também resultar em `[REQUER REFATORAÇÃO ESTRUTURAL]` ou `[DESCARTADO]`, o agente executor **PARA** e escala a decisão ao autor humano em vez de iniciar uma terceira rodada — sem isso, o ciclo de auditoria cruzada entre agentes pode continuar indefinidamente gastando tokens sem convergir. Uma autoauditoria do próprio agente autor nunca conta como uma dessas rodadas.

---

## Resultado da Auditoria (2026-07-14 12:40, Claude Sonnet 5)

Verificado fisicamente antes de aceitar: commit `37c28f8` e diff conferem exatamente com o declarado; as 14 skills listadas existem de verdade em `~/.claude/plugins/cache/claude-plugins-official/superpowers/5.1.0/skills/` (nomes e contagem 1:1, nada hallucinado); output do validador reproduzido de novo, mesmo resultado. As 5 fragilidades autodeclaradas no prompt são todas precisas — nenhuma inflada, nenhuma omissão relevante encontrada nelas.

**Veredito: `[REQUER REFATORAÇÃO MENOR]`**

**Achados novos, não cobertos pela autocrítica original** (mais grave → menos grave):
1. **Escopo errado** (CONFIRMED) — a tabela de skills globais foi anexada a `sync-skills/SKILL.md`, uma skill cuja responsabilidade declarada é sincronizar skills *de projeto* entre repositórios. Catalogar plugins globais não-relacionados é uma responsabilidade nova e desacoplada, escondida onde ninguém procuraria por ela.
2. **Informação não-portável documentada como portável** (CONFIRMED, com evidência de propagação real — a seção já tinha sido puxada para 2 repositórios consumidores antes desta correção) — "disponíveis em qualquer projeto" é falso fora desta máquina/usuário; `~/.claude/plugins/` não viaja com um `git clone`.
3. **`using-superpowers` (a skill de invocação mandatória) não recebeu destaque na regra de convivência** (CONFIRMED, lendo o `SKILL.md` real dela) — as outras 13 são "use quando aplicável"; esta é "invoque sempre, sem negociar".

**Correção aplicada nesta mesma rodada** (sem precisar de nova rodada de auditoria — achados de escopo/clareza, não de lógica quebrada): conteúdo movido de `sync-skills/SKILL.md` § 4 para uma nova seção em `CLAUDE.md` ("Skills Globais Disponíveis Neste Ambiente"), com aviso explícito de que é informação de máquina/usuário (não de projeto), instrução para conferir com `/plugin list` antes de confiar na tabela num clone/máquina diferente, e destaque específico para `using-superpowers`.

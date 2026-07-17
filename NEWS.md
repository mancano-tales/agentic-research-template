# NEWS — Decisões de Design e Evolução Metodológica

> Entrada mais recente no topo.
> **Convenção de timestamp**: Todas as datas em cabeçalhos (## YYYY-MM-DD HH:MM) e no campo Data/Hora dos metadados DEVEM incluir hora e minuto no fuso local. Nunca use datas isoladas.

## 2026-07-17 10:38 — `disable-model-invocation` revertida para `false` em grill-me/grill-with-docs/edit-article

Decisão do autor (2026-07-17): as três skills portadas de Matt Pocock que vinham com `disable-model-invocation: true` (ação só-por-pedido-explícito, preservado fielmente do original desde a instalação em 2026-07-14) passam a `false` — o autor quer as três invocáveis pelo agente como as demais skills do template, em todos os consumidores. Atualizado em conjunto o `agents/openai.yaml` de cada uma (`allow_implicit_invocation: true`) para não divergir entre plataformas (Claude vs. Copilot/OpenAI). `CLAUDE.md` (§ Skills Compartilhadas) atualizado para refletir a mudança. Como de praxe, a edição do `CLAUDE.md` quebrou o hard link físico de `AGENTS.md`/`.github/copilot-instructions.md` — backups dos divergentes salvos em `9-vers/backups/` antes de recriar os links.

Próximo passo (fora deste repositório): consumidores (`MancanoSync` raiz, `Mancano2026-MA-Thesis`, e demais que adotaram o template) precisam rodar `sync-skills --apply` para as três skills para receber a mudança — não é automático.

**Metadados de Execução**:
- **Data/Hora**: 2026-07-17 10:38 (Horário Local)
- **Agente**: Claude Code / Claude Sonnet 5 / VS Code
- **Mensagem do Commit**: "feat(governance): disable-model-invocation=false em grill-me/grill-with-docs/edit-article"
- **Arquivos afetados**: `.claude/skills/grill-me/SKILL.md`, `.claude/skills/grill-me/agents/openai.yaml`, `.claude/skills/grill-with-docs/SKILL.md`, `.claude/skills/grill-with-docs/agents/openai.yaml`, `.claude/skills/edit-article/SKILL.md`, `.claude/skills/edit-article/agents/openai.yaml`, `CLAUDE.md`, `AGENTS.md`, `.github/copilot-instructions.md`, `NEWS.md`

## 2026-07-15 12:05 — Backups do self-heal de hard link movidos da raiz para 9-vers/backups/

Achado promovido de um repositório consumidor deste template (`Nahoum-Mancano-2026-Antitrust`): a seção 0 de `tools/validate-governance.R` (self-heal do hard link `CLAUDE.md`/`AGENTS.md` quando os dois divergem) escrevia os backups `AGENTS.md.bak.<timestamp>`/`CLAUDE.md.bak.<timestamp>` direto na raiz do repositório — sem limpeza, acumulavam a cada divergência (5 arquivos reais encontrados na raiz deste próprio template). Como é tooling compartilhado, todo consumidor do template tinha o mesmo problema. Corrigido: os dois pontos de `file.copy()` agora escrevem em `9-vers/backups/` (nova pasta, já coberta pelo `*.bak.*` existente no `.gitignore`, via novo helper `make_backup_path()`); os 5 arquivos encontrados na raiz foram movidos para lá, nenhum deletado.

**Metadados de Execução**:
- **Data/Hora**: 2026-07-15 12:05 (Horário Local)
- **Agente**: Claude Sonnet 5 / Claude Code / VS Code
- **Mensagem do Commit**: "fix(governance): relocate hard-link self-heal backups from repo root to 9-vers/backups/"
- **Arquivos afetados**: `tools/validate-governance.R`, `9-vers/backups/AGENTS.md.bak.*` (movidos), `NEWS.md`, `TODO.md`

## 2026-07-14 12:45 — Auditoria da adição de skills globais (superpowers) concluída: REQUER REFATORAÇÃO MENOR, corrigido na mesma rodada

Auditoria independente (prompt deixado pelo agente autor em `9-vers/plan/2026-07-14_Prompt_Auditoria_Sync-Skills-Superpowers.md`) do commit `37c28f8`, que tinha adicionado uma tabela de skills globais do plugin `superpowers` como § 4 de `sync-skills/SKILL.md`. Verificado fisicamente antes de aceitar qualquer alegação: commit e diff conferem, as 14 skills listadas existem de verdade no plugin instalado (nomes e contagem 1:1), as 5 fragilidades autodeclaradas pelo autor original são precisas. Veredito: `[REQUER REFATORAÇÃO MENOR]` — achado principal não coberto pela autocrítica: a tabela estava no lugar errado (escopo de `sync-skills` é sincronizar skills *de projeto*, não catalogar plugins *de máquina*) e documentava informação não-portável (`~/.claude/plugins/`, local por usuário/máquina) como se fosse portável — já tinha sido propagada para 2 repositórios consumidores antes da correção. Corrigido: conteúdo movido para nova seção em `CLAUDE.md` ("Skills Globais Disponíveis Neste Ambiente"), com aviso explícito de que é inventário de máquina (não de projeto) e destaque para `using-superpowers`, a única skill do pacote com invocação mandatória por design. Resultado completo da auditoria registrado no próprio prompt.

**Metadados de Execução**:
- **Data/Hora**: 2026-07-14 12:45 (Horário Local)
- **Agente**: Claude Sonnet 5 / Claude Code / VS Code
- **Mensagem do Commit**: "docs(governance): fix scope of superpowers skills catalog - move from sync-skills to CLAUDE.md with machine-caveat"
- **Arquivos afetados**: `.claude/skills/sync-skills/SKILL.md`, `CLAUDE.md`, `AGENTS.md`, `.github/copilot-instructions.md`, `9-vers/plan/2026-07-14_Prompt_Auditoria_Sync-Skills-Superpowers.md`, `9-vers/plan/README.md`, `NEWS.md`

## 2026-07-14 12:26 — 5 skills de mattpocock/skills instaladas após triagem; reconciliado com instalação concorrente do plugin superpowers

Instaladas 5 skills de [mattpocock/skills](https://github.com/mattpocock/skills) (MIT) — `grill-me`, `grilling`, `grill-with-docs`, `edit-article`, `code-review` — escolhidas depois de mapear as ~32 skills do repositório original e apresentar uma triagem ao autor (a maioria é específica de TypeScript/Node, descartada). `git-guardrails-claude-code` foi descartada nesta rodada: dependia de `jq` (não instalado neste ambiente) e bloquearia `git push` incondicionalmente, o que conflitaria com o fluxo já estabelecido nesta sessão. Instaladas fielmente ao original, sem adaptar ao padrão config-driven das skills de governança (não são deste projeto). Detalhe completo, incluindo os gaps conhecidos (`grill-with-docs`→`/domain-modeling` ausente; `code-review`→workflow de issue-tracker ausente, degrada graciosamente), em `9-vers/plan/2026-07-14_Plano_Skills_Compartilhadas_TODO.md` § "Terceira rodada".

**Concorrência real**: esta rodada aconteceu em paralelo a outro agente (Claude Sonnet 4.6) instalando o plugin `superpowers` no mesmo repositório físico — ver entrada abaixo, escrita por ele. Auditoria do trabalho dele feita a seguir, a pedido do autor.

**Metadados de Execução**:
- **Data/Hora**: 2026-07-14 12:26 (Horário Local)
- **Agente**: Claude Sonnet 5 / Claude Code / VS Code
- **Mensagem do Commit**: "feat(governance): revert disable-model-invocation, add 5 mattpocock/skills after triage"
- **Arquivos afetados**: `.claude/skills/grill-me/`, `.claude/skills/grilling/`, `.claude/skills/grill-with-docs/`, `.claude/skills/edit-article/`, `.claude/skills/code-review/`, `CLAUDE.md`, `AGENTS.md`, `.github/copilot-instructions.md`, `9-vers/plan/2026-07-14_Plano_Skills_Compartilhadas_TODO.md`, `NEWS.md`

## 2026-07-14 11:45 — Plugin superpowers instalado; skills globais referenciadas em sync-skills

Instalado o plugin `superpowers` (14 skills globais do Claude Code) e adicionada a seção § 4 ao `sync-skills/SKILL.md` com tabela completa das skills do pacote, regra de convivência com as skills de projeto e orientação de quando usar cada uma. O objetivo é que sempre que `sync-skills` for carregada no contexto, o agente já tenha o inventário das skills globais disponíveis em memória — evitando que elas sejam ignoradas no fluxo de trabalho. O plano `2026-07-14_Plano_Skills_Compartilhadas_TODO.md` é encerrado nesta sessão com todas as tarefas concluídas.

**Metadados de Execução**:
- **Data/Hora**: 2026-07-14 11:45 (Horário Local)
- **Agente**: Claude Sonnet 4.6 / Claude Code / VS Code
- **Mensagem do Commit**: "feat(governance): reference superpowers global skills in sync-skills, close active plan"
- **Arquivos afetados**: `.claude/skills/sync-skills/SKILL.md`, `9-vers/plan/2026-07-14_Plano_Skills_Compartilhadas_TODO.md`, `9-vers/llm-reviews/README.md`, `NEWS.md`

## 2026-07-14 11:45 — Reversão: disable-model-invocation removido de close-task/git-cleanup/sync-skills, a pedido do autor

O autor decidiu que quer essas 3 skills de volta ao alcance autônomo do agente (model-invoked, o padrão) — flag `disable-model-invocation: true` removida das 3. Nenhuma outra mudança de conteúdo.

**Metadados de Execução**:
- **Data/Hora**: 2026-07-14 11:45 (Horário Local)
- **Agente**: Claude Sonnet 5 / Claude Code / VS Code
- **Mensagem do Commit**: "revert(governance): remove disable-model-invocation from close-task/git-cleanup/sync-skills per author decision"
- **Arquivos afetados**: `.claude/skills/close-task/SKILL.md`, `.claude/skills/git-cleanup/SKILL.md`, `.claude/skills/sync-skills/SKILL.md`, `NEWS.md`

## 2026-07-14 11:22 — Refinamentos vindos de referências externas: disable-model-invocation e formato de achados alinhado ao /code-review nativo

O autor pediu para checar se recursos já circulando no mercado (a skill de referência `writing-great-skills` de mattpocock/skills no GitHub, e a funcionalidade nativa de code review do próprio Claude Code) melhoravam o trabalho antes de propagar. Duas mudanças concretas:

1. **`disable-model-invocation: true`** adicionado a `close-task`, `git-cleanup` e `sync-skills` — são ações consequentes (encerram sessão, commits em lote, sobrescrevem skills locais) que só devem rodar por invocação explícita do usuário pelo nome; a flag remove a `description` do alcance do agente, então nada dispara essas skills sozinho por inferência. `request-audit`/`export-conversation`/`pdf-text-extractor` ficam sem a flag (baixo risco, faz sentido o agente alcançar por conta própria). Documentado em `CLAUDE.md` § "Skills Compartilhadas Entre Projetos".
2. **`request-audit` § D (Formato de Resposta)** reescrita para exigir, por achado: cenário de falha concreto (input/estado → output errado, não uma alegação vaga) e um veredito `CONFIRMED`/`PLAUSIBLE` — mesma convenção da ferramenta nativa `ReportFindings` do Claude Code, incluindo `outcome` (`fixed`/`skipped`/`no_change_needed`) para re-reportar achados numa segunda rodada em vez de reescrever a lista do zero.

**Metadados de Execução**:
- **Data/Hora**: 2026-07-14 11:22 (Horário Local)
- **Agente**: Claude Sonnet 5 / Claude Code / VS Code
- **Mensagem do Commit**: "refactor(governance): add disable-model-invocation to consequential skills, align request-audit findings format with native /code-review"
- **Arquivos afetados**: `.claude/skills/close-task/SKILL.md`, `.claude/skills/git-cleanup/SKILL.md`, `.claude/skills/sync-skills/SKILL.md`, `.claude/skills/request-audit/SKILL.md`, `CLAUDE.md`, `AGENTS.md`, `.github/copilot-instructions.md`, `NEWS.md`

## 2026-07-14 11:15 — Skills renomeadas para inglês e reescritas config-driven; pdf-text-extractor entra no mecanismo compartilhado

O autor apontou um problema real na primeira rodada: as skills compartilhadas tinham texto específico de cada projeto hardcoded (caminhos da tese), fazendo o relatório do `sync-skills` marcá-las como "desatualizada" permanentemente nos consumidores — sinal sem significado. Detalhe completo em `9-vers/plan/2026-07-14_Plano_Skills_Compartilhadas_TODO.md` § "Segunda rodada".

Skills renomeadas: `finalizar-tarefa`→`close-task`, `exportar-conversa`→`export-conversation`, `limpar-pendencias-git`→`git-cleanup`, `sincronizar-skills`→`sync-skills` (`request-audit`/`pdf-text-extractor` já em inglês, mantidos). `close-task`/`export-conversation`/`git-cleanup` reescritas para consumir chaves nomeadas em vez de hardcode — `git-cleanup` foi a reescrita mais pesada (variantes de autoria protegida, agrupamento por pasta de trabalho contínuo, e o caso do arquivo gerenciado externamente, todos generalizados). Nova seção `## Configuração de Skills (Skill Configuration)` em `CLAUDE.md`, com tabela `Chave | Usada por | Valor` e 4 chaves (`diretorio_autoria_primaria`, `arquivo_gerenciado_externamente`, `script_exportar_conversa`, `diretorios_trabalho_continuo`) — skills agora apontam para lá explicitamente, nunca hardcodeiam. `pdf-text-extractor` (com `scripts/extract_pdf.R`) portado da tese para a mãe, sem hardcode encontrado. `tools/sync-skills.ps1`/`.sh` reescritos para comparar/copiar a **pasta inteira** de cada skill (hash recursivo), não só `SKILL.md` — necessário para skills com arquivos auxiliares.

**Metadados de Execução**:
- **Data/Hora**: 2026-07-14 11:15 (Horário Local)
- **Agente**: Claude Sonnet 5 / Claude Code / VS Code
- **Mensagem do Commit**: "refactor(governance): rename skills to English, make them config-driven via CLAUDE.md, add pdf-text-extractor to shared mechanism"
- **Arquivos afetados**: `.claude/skills/close-task/`, `.claude/skills/export-conversation/`, `.claude/skills/git-cleanup/`, `.claude/skills/sync-skills/`, `.claude/skills/pdf-text-extractor/`, `CLAUDE.md`, `AGENTS.md`, `.github/copilot-instructions.md`, `README.md`, `tools/sync-skills.ps1`, `tools/sync-skills.sh`, `9-vers/plan/2026-07-14_Plano_Skills_Compartilhadas_TODO.md`, `NEWS.md`

## 2026-07-14 09:58 — Repositório mãe de skills compartilhadas, convenção definitiva de TODO.md, junction .agents corrigida

Formalizado este repositório como repositório mãe de skills de governança reutilizáveis entre projetos correlatos (ver `9-vers/plan/2026-07-14_Plano_Skills_Compartilhadas_TODO.md`). `TODO.md` reescrito com 3 seções (Pendente/Prospectivo/Concluído), cada item com data+hora de criação/conclusão e quem criou/concluiu (agente e humano), e link para plano em `9-vers/plan/` quando complexo — corrige a convenção anterior (item novo no fim, sem metadados) antes que ela se espalhasse para mais projetos. Skill `request-audit` portada e generalizada da tese; `finalizar-tarefa` conferida por diff contra a fonte — já estava corretamente generalizada, sem mudanças necessárias. Criados `tools/sync-skills.ps1`/`.sh` (relatório dry-run por padrão, `--apply` para puxar skills específicas, nunca commita sozinho) e a skill `sincronizar-skills` que envolve o script com a cerimônia de revisão/staging explícito. Achado e corrigido: a junction `.agents` apontava para o caminho antigo `mancano-project-template/.claude`, órfão desde a renomeação deste repositório — recriada apontando para `.claude` deste mesmo repositório.

**Metadados de Execução**:
- **Data/Hora**: 2026-07-14 09:58 (Horário Local)
- **Agente**: Claude Sonnet 5 / Claude Code / VS Code
- **Mensagem do Commit**: "feat(governance): establish shared-skills mother repo, definitive TODO.md convention, fix stale .agents junction"
- **Arquivos afetados**: TODO.md, CLAUDE.md, AGENTS.md, .claude/skills/request-audit/SKILL.md, .claude/skills/sincronizar-skills/SKILL.md, tools/sync-skills.ps1, tools/sync-skills.sh, 9-vers/plan/2026-07-14_Plano_Skills_Compartilhadas_TODO.md, 9-vers/plan/README.md, .agents

## 2026-07-13 22:37 — Sincronização de Governança com a Tese

Atualização massiva do template para incorporar as últimas travas de segurança desenvolvidas no repositório da tese. As mudanças incluem o self-heal de links (com UNC guard e system2), parser YAML mais tolerante, checks T5/T6 e genericização das ferramentas para uso em novos projetos.

**Metadados de Execução**:
- **Data/Hora**: 2026-07-13 22:37 (Horário Local)
- **Agente**: Antigravity / Gemini 1.5 Pro / Antigravity IDE
- **Mensagem do Commit**: "chore: finalização da tarefa sincronizacao-governanca"
- **Arquivos afetados**: tools/validate-governance.R, CLAUDE.md, NEWS.md, setup.ps1, setup.sh, hooks/, .claude/skills/, 9-vers/plan/

## YYYY-MM-DD HH:MM — [Título Curto da Entrega/Decisão]

[Descreva aqui em prosa contínua as principais decisões de design, mudanças de arquitetura e evolução do projeto implementadas nesta sessão.]

**Metadados de Execução**:
- **Data/Hora**: YYYY-MM-DD HH:MM (Horário Local)
- **Agente**: [Nome do Agente] / [Modelo] / [Plataforma] (ex: Antigravity / Gemini 1.5 Pro / Antigravity CLI)
- **Mensagem do Commit**: "sua mensagem de commit aqui"
- **Arquivos afetados**: caminho/do/arquivo1, caminho/do/arquivo2

# NEWS — Decisões de Design e Evolução Metodológica

> Entrada mais recente no topo.
> **Convenção de timestamp**: Todas as datas em cabeçalhos (## YYYY-MM-DD HH:MM) e no campo Data/Hora dos metadados DEVEM incluir hora e minuto no fuso local. Nunca use datas isoladas.

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

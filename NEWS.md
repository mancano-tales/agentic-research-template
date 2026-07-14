# NEWS — Decisões de Design e Evolução Metodológica

> Entrada mais recente no topo.
> **Convenção de timestamp**: Todas as datas em cabeçalhos (## YYYY-MM-DD HH:MM) e no campo Data/Hora dos metadados DEVEM incluir hora e minuto no fuso local. Nunca use datas isoladas.

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

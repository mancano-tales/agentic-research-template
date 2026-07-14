---
tipo: Plano
titulo: "Skills compartilhadas entre projetos (repositório mãe) e convenção definitiva de TODO.md"
status: EM EXECUÇÃO
criado: "2026-07-14 09:10"
concluido: null
agentes:
  orquestrador: "Claude Sonnet 5 (Claude Code, VS Code)"
  executor: "Claude Sonnet 5 (Claude Code, VS Code)"
  auditor: null
autor_humano: "Tales Mançano"
tarefas:
  - { desc: "Reescrever TODO.md com formato Pendente/Prospectivo/Concluído + metadados (data+hora, agente, humano, link de plano)", status: concluida, data: "2026-07-14 09:15" }
  - { desc: "Portar skill request-audit (generalizada, sem referências específicas da tese)", status: concluida, data: "2026-07-14 09:20" }
  - { desc: "Verificar finalizar-tarefa contra a versão-fonte da tese (diff) — confirmado, generalização já correta, sem mudanças necessárias", status: concluida, data: "2026-07-14 09:25" }
  - { desc: "Investigar e corrigir junction .agents quebrada (apontava para o caminho antigo mancano-project-template, pré-renomeação)", status: concluida, data: "2026-07-14 09:35" }
  - { desc: "Criar tools/sync-skills.ps1 e .sh (relatório dry-run + --apply, sem commit automático)", status: concluida, data: "2026-07-14 09:50" }
  - { desc: "Criar skill sincronizar-skills (camada de julgamento sobre o script mecânico)", status: concluida, data: "2026-07-14 09:55" }
  - { desc: "Documentar em CLAUDE.md/AGENTS.md: convenção de TODO.md e fluxo de sync-skills", status: concluida, data: "2026-07-14 09:58" }
  - { desc: "Portar o mecanismo para Mancano2026-MA-Thesis (TODO.md novo, sync-skills copiado)", status: pendente, data: null }
  - { desc: "Reconciliar Nahoum-Mancano-2026-Antitrust (TODO.md reformatado preservando conteúdo, sync-skills copiado, teste --apply real)", status: pendente, data: null }
  - { desc: "Alinhar agentic-institutionalism (TODO.md fresco, sem histórico a preservar)", status: pendente, data: null }
relacionados:
  - "2026-07-13_Plano_Sincronizar_Governanca_Com_Tese.md"
news: ["2026-07-14"]
---

# Plano — Skills Compartilhadas Entre Projetos + Convenção de `TODO.md`

> **Status**: EM EXECUÇÃO
> **O que é este documento**: formaliza este repositório (`agentic-research-template`) como o repositório mãe de um conjunto de skills de governança reutilizáveis entre projetos correlatos, define a convenção definitiva do `TODO.md` (append-only, 3 seções, metadados de criação/conclusão, link para planos), e cria o mecanismo de sincronização (`tools/sync-skills.ps1`/`.sh` + skill `sincronizar-skills`) usado pelos projetos consumidores.
> **Elaborado por**: Claude Sonnet 5 (Claude Code, VS Code), a pedido do autor, dentro de uma sessão de trabalho no repositório `Mancano2026-MA-Thesis`.
> **Por quê**: o autor quer as skills de governança (`finalizar-tarefa`, `request-audit`, `exportar-conversa`, `limpar-pendencias-git`) disponíveis em vários projetos correlatos sob `MancanoSync/`, hoje espalhados em repositórios git distintos, sem duplicar manualmente nem depender de link físico entre repositórios (já provou ser frágil — ver achados abaixo). Também quer um `TODO.md` de governança, no espírito do `NEWS.md`, mas com fluxo de trabalho ativo (pendências, backlog prospectivo, histórico de conclusão) em vez de só um changelog.
> **Como usar**: as tarefas 1-7 (concluídas) definem o mecanismo neste repositório. As tarefas 8-10 (pendentes) portam o mecanismo para os repositórios consumidores já existentes — cada um recebe seu próprio commit, com entrada de `NEWS.md` referenciando este plano pelo caminho relativo (repositórios git distintos não têm convenção de link clicável entre si).

---

## Achados que mudaram o desenho

Antes de desenhar do zero, uma investigação encontrou trabalho concorrente já em andamento (feito por outro agente, Antigravity, em paralelo):
- Este repositório se chamava `mancano-project-template` e foi **renomeado** para `agentic-research-template`. Um plano de sincronização escrito anteriormente (`2026-07-13_Plano_Sincronizar_Governanca_Com_Tese.md`) já tinha sido **executado** aqui via a skill `finalizar-tarefa` (commit `5938ec7`), trazendo T5/T6, migração de hooks, correções de parser YAML etc. do repositório da tese.
- Um `TODO.md` inicial já tinha sido criado (commit `4a4bb87`) — mas com a ordem invertida (item novo no fim, não no topo) e sem metadados. Corrigido nesta rodada.
- A **junction `.agents` estava quebrada**: apontava para o caminho antigo `mancano-project-template/.claude`, que deixou de existir após a renomeação — gerava um aviso a cada rodada do validador. Recriada apontando para `.claude` dentro deste mesmo repositório (mesmo padrão usado no repositório da tese).
- Dois projetos reais já nasceram deste template (`Nahoum-Mancano-2026-Antitrust`, com conteúdo real de `TODO.md` já na convenção antiga; `agentic-institutionalism`, ainda sem nenhum commit) — cobertos nas tarefas pendentes 8-10.

## Decisões de design

1. **Repositório mãe = este próprio repositório**, não um repositório novo só para skills. Template de projeto e biblioteca de skills vivem juntos.
2. **Sincronização via script de pull explícito**, não junction/symlink entre repositórios (frágil sob renomeação/sync de nuvem, como o achado da junction `.agents` acima demonstra ao vivo) nem git submodule (fricção conhecida no Windows). `tools/sync-skills.ps1`/`.sh` roda em modo relatório por padrão; só escreve com `-Apply`/`--apply`; nunca commita sozinho.
3. **A sincronização vira uma skill** (`sincronizar-skills`), não só um script nu — mesma lógica de por que `finalizar-tarefa`/`request-audit` existem como skills: o script faz a parte mecânica, a skill carrega a cerimônia de governança (revisão de diff, staging explícito, documentação).
4. **`TODO.md` tem 3 seções**: Pendente (pronto para trabalhar), Prospectivo (identificado mas não pronto — falta decisão ou depende de outra tarefa), Concluído (log cronológico, mais recente primeiro). Todo item tem data+hora de criação e quem criou (agente e humano); ao concluir, some-se data+hora e quem concluiu; itens complexos linkam o plano correspondente em `9-vers/plan/`.
5. **Escopo desta rodada**: só os repositórios já alinhados com esta governança (este template + `Mancano2026-MA-Thesis` + os 2 projetos já nascidos daqui). Repositórios mais antigos com governança parcial adotam depois, sob demanda, usando o mesmo `sync-skills`.

## Arquivos deste repositório

- `TODO.md` — reescrito.
- `.claude/skills/request-audit/SKILL.md` — novo, portado e generalizado da tese.
- `.claude/skills/sincronizar-skills/SKILL.md` — novo.
- `tools/sync-skills.ps1` / `.sh` — novos.
- `CLAUDE.md`/`AGENTS.md` — nova seção "Skills Compartilhadas Entre Projetos", linha da tabela de `TODO.md` atualizada.
- `.agents` — junction recriada (apontava para caminho pré-renomeação).

## Verificação

1. `Rscript tools/validate-governance.R` limpo, sem o aviso de junction quebrada.
2. `.\tools\sync-skills.ps1` rodado dentro deste próprio repositório retorna o aviso "já é a mãe" e sai sem erro (testado).
3. Pendente: rodar o mesmo script a partir de `Mancano2026-MA-Thesis` e `Nahoum-Mancano-2026-Antitrust` (tarefas 8-9) e confirmar que o relatório reflete o estado real de cada um.

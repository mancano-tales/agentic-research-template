---
tipo: Plano
titulo: "Skills compartilhadas entre projetos (repositório mãe) e convenção definitiva de TODO.md"
status: CONCLUÍDO
criado: "2026-07-14 09:10"
concluido: "2026-07-14 12:15"
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
  - { desc: "Portar o mecanismo para Mancano2026-MA-Thesis (TODO.md novo, sync-skills copiado)", status: concluida, data: "2026-07-14 10:05" }
  - { desc: "Reconciliar Nahoum-Mancano-2026-Antitrust (TODO.md reformatado preservando conteúdo, sync-skills copiado, teste --apply real)", status: concluida, data: "2026-07-14 10:15" }
  - { desc: "Alinhar agentic-institutionalism (TODO.md fresco, sem histórico a preservar)", status: concluida, data: "2026-07-14 10:20" }
  - { desc: "Segunda rodada: renomear todas as skills para inglês, torná-las config-driven (sem hardcode de repositório), adicionar pdf-text-extractor ao mecanismo compartilhado, criar seção Configuração de Skills em CLAUDE.md", status: concluida, data: "2026-07-14 11:15" }
  - { desc: "Terceira rodada: portar 5 skills de mattpocock/skills (grill-me, grilling, grill-with-docs, edit-article, code-review) após triagem com o autor; reconciliação com instalação concorrente do plugin superpowers por outro agente", status: concluida, data: "2026-07-14 12:15" }
relacionados:
  - "2026-07-13_Plano_Sincronizar_Governanca_Com_Tese.md"
  - "2026-07-14_1128_instalar-skills-superpowers_conversa-claude.md"
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
3. `Mancano2026-MA-Thesis` e `Nahoum-Mancano-2026-Antitrust`: `sync-skills` testado de ponta a ponta, incluindo `--apply` real em `Nahoum-Mancano-2026-Antitrust` (`request-audit`, byte-idêntico confirmado, nada commitado sozinho). Ver detalhe completo no `NEWS.md` de cada repositório.

---

## Segunda rodada (2026-07-14) — renomeio para inglês e refatoração config-driven

O autor revisou o trabalho da primeira rodada e apontou um problema real: as skills compartilhadas (`finalizar-tarefa`, `limpar-pendencias-git`) tinham texto específico de cada projeto hardcoded (caminhos de `3-texts/`, nome exato do `.bib` da tese, `4-DA-Code/`), o que fazia o relatório do `sync-skills` marcá-las como "desatualizada" **permanentemente** nos repositórios consumidores — um sinal sem significado, já que a divergência nunca seria resolvida. Proposta do autor, adotada integralmente: as skills compartilhadas devem ser **byte-idênticas** em todo repositório; particularidades de projeto vivem só em `CLAUDE.md`, numa seção nova e explicitamente rotulada como "Configuração de Skills" — as skills apontam para lá por chave nomeada, nunca hardcodeiam.

**Achado de suporte à mudança**: o `close-task` (então `finalizar-tarefa`) da própria mãe **já seguia esse padrão** num trecho (referência genérica a "diretórios de Autoria Primária... conforme configurado no CLAUDE.md") — a arquitetura certa já existia parcialmente, só não tinha sido aplicada de forma consistente nem formalizada como seção própria, e a tese nunca migrou sua cópia local para usar essa versão genérica.

**Tarefas adicionais pedidas pelo autor, executadas na mesma rodada**:
- Renomear todas as skills para nomes melhores em inglês.
- Garantir que todas as skills, **inclusive `pdf-text-extractor`** (até então só na tese), estejam disponíveis em todos os repositórios do mecanismo.
- Deixar explícito, no `CLAUDE.md`, que existe uma seção de configuração que as skills consomem.

**Execução**:
- `tools/sync-skills.ps1`/`.sh` reescritos: hash agora cobre a **pasta inteira** da skill (recursivo), não só `SKILL.md` — necessário porque `pdf-text-extractor` tem `scripts/extract_pdf.R` junto. `--apply` agora espelha a pasta inteira (remove e recopia), para que um arquivo removido na mãe também suma localmente.
- Nova seção `## Configuração de Skills (Skill Configuration)` em `CLAUDE.md`, com tabela `Chave | Usada por | Valor neste repositório` e placeholders para as 4 chaves identificadas: `diretorio_autoria_primaria`, `arquivo_gerenciado_externamente`, `script_exportar_conversa`, `diretorios_trabalho_continuo`.
- Skills renomeadas e reescritas para consumir essas chaves em vez de hardcode:
  - `finalizar-tarefa` → **`close-task`** (referencia `script_exportar_conversa` e `diretorio_autoria_primaria`).
  - `exportar-conversa` → **`export-conversation`** (referencia `script_exportar_conversa`).
  - `limpar-pendencias-git` → **`git-cleanup`** (reescrita mais pesada — a lógica de "variantes com/sem `.qmd`", os padrões de agrupamento por `4-DA-Code/`, e o caso especial do `.bib` do Zotero viraram genéricos via `diretorio_autoria_primaria`, `diretorios_trabalho_continuo` e `arquivo_gerenciado_externamente`).
  - `sincronizar-skills` → **`sync-skills`** (mesmo nome do script subjacente; auto-referências a `finalizar-tarefa` corrigidas para `close-task`; instruído a nunca deixar uma skill promovida com hardcode).
  - `request-audit` e `pdf-text-extractor` mantidos (já em inglês; `request-audit` já não tinha hardcode nenhum, confirmado por grep antes de decidir não mexer).
- `pdf-text-extractor` portado para a mãe (com `scripts/extract_pdf.R`) — não tinha hardcode de caminho, generalização mínima necessária.

**Propagado e verificado** (mesma sessão): `Mancano2026-MA-Thesis` e `Nahoum-Mancano-2026-Antitrust` receberam o renomeio + `pdf-text-extractor` + Configuração de Skills com valores reais de cada um; as 6 skills compartilhadas confirmadas com hash de pasta idêntico nos 3 repositórios; todos com push feito.

---

## Terceira rodada (2026-07-14) — reversão do disable-model-invocation e skills de terceiros (mattpocock/skills)

**Reversão**: o autor decidiu manter `close-task`/`git-cleanup`/`sync-skills` como model-invoked (sem a flag `disable-model-invocation`) — revertido nos 3 repositórios, cada um com seu próprio commit.

**Skills de terceiros**: o autor pediu para instalar skills de [mattpocock/skills](https://github.com/mattpocock/skills) (MIT). Antes de instalar tudo, mapeei as ~32 skills do repositório original (6 categorias) e apresentei uma triagem ("grill me") ao autor, já descartando as claramente específicas de TypeScript/Node. Escolhidas: `grill-me`, `grilling`, `grill-with-docs`, `edit-article`, `code-review`. Descartadas nesta rodada: `git-guardrails-claude-code` (dependia de `jq`, não instalado neste ambiente, e bloquearia `git push` incondicionalmente — conflito direto com o fluxo de trabalho desta sessão), `handoff`/`claude-handoff`, `obsidian-vault`, `loop-me`, e as 4 skills de escrita em estágio (`writing-fragments`/`writing-beats`/`writing-shape` — só `edit-article` ficou).

Instaladas **fielmente ao original** (mesmo texto, arquivos `agents/openai.yaml` de interoperabilidade inclusos) — não são deste projeto, não fazem parte do mecanismo config-driven das skills de governança. Gaps conhecidos e aceitos: `grill-with-docs` referencia `/domain-modeling` (não instalada); `code-review` referencia um workflow de issue-tracker que não existe aqui (degrada graciosamente, documentado no próprio `SKILL.md` do Pocock).

**Concorrência real durante a execução**: enquanto isso, outro agente (Claude Sonnet 4.6, sessão separada, mesmo repositório físico em disco) instalou o plugin `superpowers` (skills globais do Claude Code) e rodou sua própria cerimônia de encerramento — commit `37c28f8`, conversa exportada e registrada, `9-vers/plan/2026-07-14_Prompt_Auditoria_Sync-Skills-Superpowers.md` deixado como handoff. O autor pediu para eu terminar meu trabalho primeiro e depois auditar o dele — feito nesta ordem; auditoria registrada separadamente (ver `9-vers/llm-reviews/README.md` e o prompt de auditoria referenciado).

# TODO — Registro de Pendências (Governança Append-Only)

> **Regra de Governança:** este arquivo **nunca** tem itens apagados. Itens concluídos são **movidos** (não editados retroativamente) para o topo de "Concluído" — log cronológico, mais recente primeiro, igual ao `NEWS.md`. Todo item registra data+hora de criação (`YYYY-MM-DD HH:MM`, horário local) e quem criou (agente e humano); ao concluir, soma-se data+hora e quem concluiu. Itens complexos (múltiplas etapas, decisão arquitetural) linkam o plano correspondente em `9-vers/plan/YYYY-MM-DD_Plano_*.md` — o TODO é o índice curto, o plano é o detalhe. Agentes de IA devem consultar este arquivo ao iniciar rodadas complexas de planejamento, para alinhamento com a agenda pendente **e** prospectiva.
>
> **Três seções**: "Pendente" = pronto para ser trabalhado agora. "Prospectivo" = identificado mas não pronto ainda (falta decisão, depende de outra tarefa, ou é backlog de menor prioridade) — quando ficar pronto, é **movido** para o topo de "Pendente" preservando a data de criação original (não reescreve, só relocaliza e anota a promoção). "Concluído" = feito.

## Pendente

- [ ] Tarefa inicial do seu projeto...
  - Criado: YYYY-MM-DD HH:MM por [Nome do Agente] (a pedido de [Nome do Autor Humano])
  - Plano: `9-vers/plan/...` (se houver)

## Prospectivo

- [ ] Tarefa identificada mas ainda não pronta para execução imediata...
  - Criado: YYYY-MM-DD HH:MM por [Nome do Agente] (a pedido de [Nome do Autor Humano])
  - Motivo de não estar em Pendente: [depende de X / decisão pendente / baixa prioridade]
  - Plano: `9-vers/plan/...` (se houver)

## Concluído

- [x] Corrigir formato do TODO.md (ordem invertida, sem metadados) para o padrão Pendente/Concluído com data+hora, agente/humano e link de plano
  - Criado: 2026-07-13 23:50 por Antigravity (a pedido de Tales Mançano)
  - Concluído: 2026-07-14 09:10 por Claude Sonnet 5 (a pedido de Tales Mançano)
  - Plano: `9-vers/plan/2026-07-14_Plano_Skills_Compartilhadas_TODO.md`
- [x] Sincronizar governança do template com o estado da tese (T5/T6, parser YAML, migração de hooks, skills)
  - Criado: 2026-07-13 22:17 por Claude Sonnet 5 (a pedido de Tales Mançano)
  - Concluído: 2026-07-13 22:45 por Antigravity (a pedido de Tales Mançano)
  - Plano: `9-vers/plan/2026-07-13_Plano_Sincronizar_Governanca_Com_Tese.md`

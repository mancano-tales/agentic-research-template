# plan/ — Planejamento e Roteiros de Trabalho (Work Packages)

Esta pasta abriga os planos de trabalho estruturados e revisados. Nenhum agente de IA deve iniciar modificações complexas no repositório sem propor um plano nesta pasta e obter a aprovação do autor humano.

---

## Legenda de Status de Planos

Os planos declaram um status em seu cabeçalho YAML e na tabela do índice abaixo. Os status válidos são:

*   `ATIVO` — Aprovado pelo autor, aguardando início da execução ou em progresso passivo.
*   `EM EXECUÇÃO` — Tarefa sendo ativamente codificada/executada neste momento.
*   `PARCIAL` — Pausado, com entregas parciais registradas.
*   `CONCLUÍDO` — Concluído, auditado e com o log de conversa correspondente registrado no inventário de reviews.
*   `SUPERADO` — Substituído por outro plano mais recente (indica o link do novo plano).
*   `HISTÓRICO` — Roteiros antigos ou de referência preservados apenas para contexto histórico.

---

## Diretrizes de Formatação

Ao criar um plano, o arquivo **deve** começar com o cabeçalho YAML delimitado por `---` contendo:
```yaml
---
tipo: Plano
titulo: "Título descritivo do plano"
status: ATIVO # [ATIVO | EM EXECUÇÃO | PARCIAL | CONCLUÍDO | SUPERADO | HISTÓRICO]
criado: YYYY-MM-DD
concluido: null # Preencher com a data YYYY-MM-DD ao concluir
agentes:
  orquestrador: "Identificação do Agente/IA"
  executor: null
  auditor: null
autor_humano: "Nome do Desenvolvedor/Autor"
tarefas:
  - { desc: "Descrição da tarefa 1", status: pendente, data: null }
relacionados: []
news: []
---
```

---

## Índice

<!-- BEGIN_PLAN_INDEX -->
| `2026-07-11_Plano_TEMPLATE.md` | HISTÓRICO | Claude Fable 5 | Título do Plano de Trabalho |
<!-- END_PLAN_INDEX -->

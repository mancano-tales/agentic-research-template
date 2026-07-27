# GUIDANCE MAP — Índice de Diretrizes e Organização do Repositório

Este documento serve como o **Sitemap de Orientação e Governança** do repositório. Ele mapeia de forma lógica o papel de cada pasta do projeto, quais arquivos de diretrizes as controlam e o escopo de atuação que humanos e agentes de IA devem observar em cada uma delas.

---

## 1. Mapa de Diretrizes por Diretório

| Diretório | Função Primária | Arquivo de Diretriz Ativo | Escopo e Governança da Diretriz |
|---|---|---|---|
| `/` (Raiz) | Configurações globais e sumários | [CLAUDE.md](../CLAUDE.md) / [AGENTS.md](../AGENTS.md) | **Única fonte de verdade** sobre o estado atual do projeto, regras de precedência de documentos, gotchas de execução e regras anti-contaminação de agentes. |
| `tools/` | Scripts de utilidade geral e QA | `validate-governance.R` | Regras de validação automatizada de metadados de planos e indexadores. |
| `9-vers/plan/` | Planejamento de tarefas ativo | [plan/README.md](plan/README.md) | Índice de status dos planos de trabalho ativos e regras de frontmatter YAML estruturado para novos planos. |
| `9-vers/llm-reviews/` | Registro de auditoria de logs de IAs | [llm-reviews/README.md](llm-reviews/README.md) | Inventário de conversas de IAs exportadas associando planos concluídos aos seus UUIDs de chat. |

---

## 2. Mapa Temático: Onde encontrar orientações específicas

Se você (humano ou agente de IA) for realizar alguma das tarefas abaixo, consulte **obrigatoriamente** as seguintes âncoras antes de editar:

### A. Escrita de Código / Regras do Projeto
*   **Convenções de Estilo:** Siga as regras declaradas no `CLAUDE.md` § "Technical Stack & Commands".
*   **Tratamento de Erros:** Siga os padrões estabelecidos na documentação do projeto.

### B. Execução de Tarefas por Agentes de IA
*   **Proposição de Trabalho:** Antes de executar tarefas complexas, proponha um plano em `9-vers/plan/` contendo o YAML de metadados padrão detalhado nas diretivas de [plan/README.md](plan/README.md).
*   **Política de Commits:** Sempre comite apenas os arquivos trabalhados (`git add <file>`). É terminantemente proibido usar `git add .` para não arrastar modificações ativas do desenvolvedor humano.
*   **Export de Conversa:** Ao finalizar uma sessão de trabalho, execute `Rscript tools/export_conversa.R <session_uuid> [slug]` para exportar o log da conversa para a pasta `9-vers/llm-reviews/`.

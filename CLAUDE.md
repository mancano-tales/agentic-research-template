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
  - [Adicione outras proibições do seu projeto aqui...]
- **Planos ativos**: consulte o índice de status em `9-vers/plan/README.md`.

---

## Guidance Documents: Map and Precedence Rules

**Regras de Precedência:**
1. Em caso de conflito, a seção "Current State" acima + o plano ativo em `9-vers/plan/` correspondente prevalecem sobre qualquer outro documento.
2. Arquivos marcados com banner de desatualização/arquivamento são mantidos apenas para histórico e não devem orientar o trabalho corrente.
3. Cada documento de diretriz possui uma função única (tabela abaixo).

**Mapa de Diretrizes de Apoio**:

| Documento | Público-alvo | Função | Gatilho de Atualização |
|---|---|---|---|
| `CLAUDE.md` (este) | Agentes de IA | Estado atual do projeto, regras críticas e convenções de build | Decisão de design ou mudança no estado |
| `README.md` | Humanos | O que é o projeto, guia de instalação e execução rápida | Mudança estrutural do repositório |
| `GUIDANCE.md` | Ambos | Sitemap rápido apontando para o sitemap completo de diretrizes | Layout de pastas alterado |
| `9-vers/plan/README.md` | Ambos | Índice e status de todos os planos de execução de tarefas | Criação ou mudança de status de plano |

---

## Git and LLM Documentation Conventions for AI Agents

- **Commits Permitidos**: Os agentes de IA estão autorizados a fazer commits diretamente no repositório.
- **Política de Staging Cirúrgico**: Agentes **NUNCA** devem utilizar `git add .`. Devem adicionar cirurgicamente apenas os arquivos nos quais trabalharam (ex: `git add src/main.js`). Isso preserva o trabalho em andamento do autor humano.
- **Synchronized Commit Policy (Co-committing)**: Cada commit contendo mudanças de funcionalidade ou documentação deve obrigatoriamente incluir a atualização do [NEWS.md](NEWS.md) (e o status do plano em `9-vers/plan/README.md` se aplicável) na *mesma transação de commit*. Todo log de agente no `NEWS.md` deve terminar com o bloco **Metadados de Execução**:
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

# [NOME DO SEU PROJETO]

> Breve descrição de uma linha sobre o objetivo do seu projeto.

Este repositório adota um **modelo profissional de desenvolvimento cooperativo Humano-IA de nível industrial**. Ele foi projetado para permitir que agentes de IA autônomos (como Claude Code, Cursor, Antigravity, Aider) trabalhem de forma segura e sincronizada com desenvolvedores humanos, eliminando regressões de código, duplicidade de logs e perda de contexto.

---

## 1. Setup Rápido (Configuração de Links de IA)

Para iniciar o projeto e preparar as pontes de contexto das IAs:

*   **No Windows (PowerShell):**
    ```powershell
    Set-ExecutionPolicy Bypass -Scope Process -Force
    .\setup.ps1
    ```
*   **No Linux/macOS (Bash):**
    ```bash
    chmod +x setup.sh
    ./setup.sh
    ```

Isso criará automaticamente o hard link para `AGENTS.md` (OpenAI/Codex) e o link de junção para a pasta `.agents/` (Gemini/Antigravity), integrando ambos os ecossistemas sob a mesma base física de habilidades em `.claude/skills/`.

---

## 2. Organograma do Repositório

```
[seu-repositório]/
├── .claude/                         # Pasta unificada de customizações e skills compartilhadas de IAs
│   └── skills/                      # Scripts e instruções estendidas para agentes (ex: export-conversation)
├── .agents/                         # Atalho local (junction NTFS) apontando para .claude/ (gitignorado)
├── hooks/                           # Modelos de Git Hooks para automação e validação de commits
│   ├── pre-commit                   # Hook pre-commit (valida status e cobra NEWS.md)
│   └── post-merge                   # Hook post-merge (recria junctions e links físicos)
├── tools/                           # Scripts de utilidade geral e QA do repositório
│   ├── validate-governance.R        # Validador de integridade de metadados de planos (R)
│   └── export_conversa.R            # Extrator de logs de sessões de IA para Markdown (R)
├── 9-vers/                          # Pasta viva de planejamento e arquivo de histórico
│   ├── GUIDANCE_MAP.md              # Sitemap completo explicando a função de cada pasta
│   ├── plan/
│   │   ├── README.md                # Tabela de status e progresso de tarefas (Work Packages)
│   │   └── YYYY-MM-DD_Plano_TEMPLATE.md  # Template para novos planos de trabalho
│   └── llm-reviews/
│       └── README.md                # Registro de conversas e auditoria de IAs
│
├── CLAUDE.md                        # Contexto detalhado do projeto, regras estritas e tech stack (IA)
├── AGENTS.md                        # Hard link físico para CLAUDE.md (OpenAI/Codex)
├── GUIDANCE.md                      # Atalho para o sitemap completo de diretrizes
├── NEWS.md                          # Changelog de decisões de design e evolução (atualizado por commits)
└── README.md                        # Este documento (Visão geral de instalação e execução)
```

---

## 3. Como Começar a Desenvolver

1.  **Edite as Definições:** Atualize as configurações e descrições do seu projeto em `CLAUDE.md` e `README.md`.
2.  **Crie um Plano:** Para qualquer tarefa de arquitetura ou fluxo complexo, crie um plano em `9-vers/plan/` a partir do `2026-07-11_Plano_TEMPLATE.md` e adicione-o como `ATIVO` na tabela do `9-vers/plan/README.md`.
3.  **Audite a Governança:** Rode `Rscript tools/validate-governance.R` a qualquer momento para garantir que nenhuma IA quebrou os padrões de status do repositório.
4.  **Log de Conversa:** Ao finalizar uma sessão com um agente, rode `Rscript tools/export_conversa.R <session_uuid> [slug]` para gerar o log em `llm-reviews/` e indexá-lo.

---

## 4. Instalando Git Hooks de Governança

Para automatizar a verificação local e evitar erros em commits, os hooks agora são versionados diretamente na pasta `hooks/`.

Eles já são ativados automaticamente ao rodar o Setup Rápido (Seção 1). Se precisar ativá-los manualmente:

*   **No Linux/macOS ou Windows:**
    ```bash
    git config core.hooksPath hooks
    ```


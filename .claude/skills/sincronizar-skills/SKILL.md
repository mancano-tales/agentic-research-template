---
name: sincronizar-skills
description: SOP para trazer skills de governança atualizadas do repositório mãe (agentic-research-template) para este projeto, ou para promover uma skill melhorada/nova deste projeto de volta para a mãe. Roda tools/sync-skills.ps1/.sh em modo relatório primeiro, pede confirmação item a item antes de aplicar qualquer mudança, e nunca commita automaticamente.
---

# Sincronizar Skills com o Repositório Mãe

Esta skill é a camada de julgamento em torno do script mecânico `tools/sync-skills.ps1`/`.sh`. O script só compara arquivos e copia bytes; esta skill garante que a cópia é revisada, documentada e commitada com a mesma disciplina de governança do resto do repositório.

**Não confunda com `finalizar-tarefa`**: esta skill só trata da sincronização de skills entre repositórios — não faz a cerimônia de encerramento de tarefa (NEWS.md geral, export de conversa, etc.), embora o passo 4 abaixo aponte para lá quando fizer sentido.

## 1. Puxar atualizações da mãe (direção mãe → projeto)

1. Rode o relatório em modo dry-run:
   ```
   .\tools\sync-skills.ps1
   ```
   ou (bash) `tools/sync-skills.sh`. Isso nunca escreve nada — só lista `NOVA`, `desatualizada` ou `em dia` por skill.
2. **Não aplique tudo cegamente.** Para cada skill marcada `desatualizada` ou `NOVA`, decida com o usuário (ou por bom senso, se a mudança for claramente uma correção de bug/governança e não uma preferência de projeto) se ela deve mesmo ser puxada — um projeto pode ter customizado uma skill de propósito.
3. Aplique só o que foi confirmado:
   ```
   .\tools\sync-skills.ps1 -Apply <nome-da-skill>
   ```
   (ou `-Apply all` só se todas as pendências foram revisadas e aprovadas).
4. **Nunca use `git add .`** depois — stage explicitamente cada `.claude/skills/<nome>/SKILL.md` que foi de fato alterado (`git status` primeiro para confirmar o que mudou).
5. Documente no `NEWS.md` (bloco de Metadados de Execução) e, se a atualização for relevante o bastante para o histórico de trabalho, adicione um item em `TODO.md` (seção Concluído, se já foi feito na mesma sessão) linkando o commit.

## 2. Promover uma skill local para a mãe (direção projeto → mãe)

Não é automatizado por bom motivo: decidir se uma skill é genérica o bastante para virar parte da biblioteca compartilhada é julgamento, não mecânica. Fluxo:

1. Releia a skill local (`.claude/skills/<nome>/SKILL.md`) procurando por menções específicas deste projeto (nomes de pastas de conteúdo, arquivos de dados, convenções que só fazem sentido aqui) e generalize-as antes de promover — mesmo padrão já usado para portar `finalizar-tarefa`/`request-audit`/`limpar-pendencias-git` deste template.
2. Copie o arquivo generalizado para `<caminho-da-mãe>/.claude/skills/<nome>/SKILL.md` (localize o caminho da mãe do mesmo jeito que o script resolve: `tools/.skills-source` se existir, senão a pasta irmã `agentic-research-template`).
3. Commit **na mãe**, com entrada de `NEWS.md` lá (é um repositório git separado — nunca tente commitar mudanças de dois repositórios numa mesma operação).
4. Volte ao projeto de origem e, se quiser, rode o passo 1 acima para "puxar de volta" a versão generalizada, confirmando que bate com o que você promoveu.

## 3. Configuração de fonte não-padrão

Se este projeto não estiver como pasta irmã de `agentic-research-template` (layout diferente de máquina, clone em outro lugar), crie `tools/.skills-source` com o caminho absoluto ou relativo do repositório mãe, uma linha só, sem aspas.

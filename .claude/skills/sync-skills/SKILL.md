---
name: sync-skills
description: SOP para trazer skills de governança atualizadas do repositório mãe (agentic-research-template) para este projeto, ou para promover uma skill melhorada/nova deste projeto de volta para a mãe. Roda tools/sync-skills.ps1/.sh em modo relatório primeiro, pede confirmação item a item antes de aplicar qualquer mudança, e nunca commita automaticamente.
---

# Sincronizar Skills com o Repositório Mãe

Esta skill é a camada de julgamento em torno do script mecânico `tools/sync-skills.ps1`/`.sh`. O script só compara pastas inteiras (não só o `SKILL.md` — algumas skills têm arquivos auxiliares, ex.: `scripts/`) e copia bytes; esta skill garante que a cópia é revisada, documentada e commitada com a mesma disciplina de governança do resto do repositório.

**Regra de design das skills compartilhadas**: elas são **byte-idênticas** em todo repositório — nunca hardcodeiam caminho ou convenção específica de um projeto. Uma skill "desatualizada" no relatório deveria sempre significar "há uma correção real esperando", nunca "esta skill tem uma customização permanente que nunca vai bater". Se você notar uma skill compartilhada que hardcoda algo específico deste projeto, isso é um bug na skill — corrija na mãe (seção 2 abaixo), não aceite a divergência permanente.

**Não confunda com `close-task`**: esta skill só trata da sincronização de skills entre repositórios — não faz a cerimônia de encerramento de tarefa (NEWS.md geral, export de conversa, etc.), embora o passo 5 abaixo aponte para lá quando fizer sentido.

## 1. Puxar atualizações da mãe (direção mãe → projeto)

1. Rode o relatório em modo dry-run:
   ```
   .\tools\sync-skills.ps1
   ```
   ou (bash) `tools/sync-skills.sh`. Isso nunca escreve nada — só lista `NOVA`, `desatualizada` ou `em dia` por skill (comparação por hash da pasta inteira).
2. **Não aplique tudo cegamente.** Para cada skill marcada `desatualizada` ou `NOVA`, decida com o usuário (ou por bom senso, se a mudança for claramente uma correção de bug/governança) se ela deve mesmo ser puxada.
3. Aplique só o que foi confirmado:
   ```
   .\tools\sync-skills.ps1 -Apply <nome-da-skill>
   ```
   (ou `-Apply all` só se todas as pendências foram revisadas e aprovadas). Isso copia a **pasta inteira** da skill (SKILL.md e qualquer arquivo auxiliar), substituindo a versão local.
4. **Nunca use `git add .`** depois — stage explicitamente cada arquivo da pasta `.claude/skills/<nome>/` que foi de fato alterado (`git status` primeiro para confirmar o que mudou).
5. Documente no `NEWS.md` (bloco de Metadados de Execução) e, se a atualização for relevante o bastante para o histórico de trabalho, adicione um item em `TODO.md` (seção Concluído, se já foi feito na mesma sessão) linkando o commit.

## 2. Promover uma skill local para a mãe (direção projeto → mãe)

Não é automatizado por bom motivo: decidir se uma skill é genérica o bastante para virar parte da biblioteca compartilhada é julgamento, não mecânica. Fluxo:

1. Releia a skill local (`.claude/skills/<nome>/SKILL.md` e qualquer arquivo auxiliar) procurando por menções específicas deste projeto — nomes de pastas de conteúdo, arquivos de dados, caminhos de script. **Não deixe nada hardcoded**: se a skill precisa de um dado específico do repositório, ela deve referenciar uma chave em `CLAUDE.md` § "Configuração de Skills" (crie a chave se ainda não existir) em vez de citar o caminho diretamente. Mesmo padrão já usado em `close-task`/`git-cleanup` deste template.
2. Copie a pasta inteira generalizada para `<caminho-da-mãe>/.claude/skills/<nome>/` (localize o caminho da mãe do mesmo jeito que o script resolve: `tools/.skills-source` se existir, senão a pasta irmã `agentic-research-template`).
3. Commit **na mãe**, com entrada de `NEWS.md` lá (é um repositório git separado — nunca tente commitar mudanças de dois repositórios numa mesma operação).
4. Volte ao projeto de origem e, se quiser, rode o passo 1 acima para "puxar de volta" a versão generalizada, confirmando que bate com o que você promoveu.

## 3. Configuração de fonte não-padrão

Se este projeto não estiver como pasta irmã de `agentic-research-template` (layout diferente de máquina, clone em outro lugar), crie `tools/.skills-source` com o caminho absoluto ou relativo do repositório mãe, uma linha só, sem aspas.

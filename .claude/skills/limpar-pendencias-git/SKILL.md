---
name: limpar-pendencias-git
description: Limpa pendências acumuladas de `git status` neste repositório multiagente — inventaria, agrupa por assunto, entra em modo plano fazendo perguntas estilo /grill-me sobre como organizar os commits, e só então executa commits temáticos com staging explícito, checkpoints de governança e documentação sincronizada (NEWS.md, inventário de llm-reviews). Duas variantes: com ou sem arquivos sensíveis protegidos por governança.
---

# Limpar pendências de `git status`

Codifica o procedimento para organizar e comitar o backlog de `git status` de repositórios multiagente onde múltiplos agentes de IA (Claude Code, Antigravity) trabalham em paralelo, então "comitar tudo de uma vez" está fora de cogitação. O `CLAUDE.md` proíbe explicitamente `git add .`/`-A` (**Strict Staging Policy**) e exige confirmação para arquivos sensíveis/protegidos.

## Duas variantes

- **Sem arquivos sensíveis (padrão — use esta a menos que o autor peça a outra explicitamente)**: nenhum arquivo definido como protegido/autoria humana (ex. textos primários marcados no CLAUDE.md) entra em nenhum commit desta rodada, mesmo que apareça modificado no `git status`. Fica de fora e é reportado no final.
- **Com arquivos sensíveis**: permite incluir arquivos protegidos, mas só arquivo por arquivo com autorização explícita do autor **nesta própria conversa** — nunca por inferência ou porque "parece pronto". Pergunte por cada um individualmente na fase de plano (passo 2).

Se o autor não especificou a variante ao invocar a skill, pergunte antes de prosseguir.

## Passo 1 — Inventário fresco

Rode `git status --short` você mesmo, agora. Nunca reutilize um inventário de uma mensagem anterior do usuário ou de um plano — este repositório muda sob seus pés entre uma leitura e outra.

## Passo 2 — Modo plano: proponha o agrupamento e pergunte antes de executar

**Entre em modo plano (`EnterPlanMode`) antes de rodar qualquer comando git que mute o repositório.** Nesta fase você só lê — `git status`, `git diff`, abrir arquivos para entender o que mudou.

Agrupe os itens do inventário por assunto lógico, não por "tudo junto". Padrões recorrentes:

1. Uma série de scripts que formam um trabalho contínuo ou uma funcionalidade.
2. Ferramentas novas em `tools/` — sempre precisam de entrada em `NEWS.md` (Regra 2 do `CLAUDE.md`: qualquer mudança relevante em código exige log).
3. Scripts arquivados — podem entrar sozinhos ou junto de suas novas versões, com nota do porquê.
4. Exports de conversa em `9-vers/llm-reviews/*.md` — **sempre exigem uma linha na tabela `## Inventário` de `9-vers/llm-reviews/README.md` antes de comitar**, no mesmo commit.
5. Arquivos de geradores externos (ex. lockfiles, bibliotecas) declarados no `CLAUDE.md` — **sempre commit próprio, nunca misturado com mais nada** (ver passo 5).
6. Arquivos sensíveis protegidos (ex. prosa primária) — só se a variante respectiva foi escolhida e cada arquivo foi autorizado.
7. Qualquer coisa que não se encaixe nos padrões acima — pergunte ao autor como agrupar.

Depois de montar a proposta de agrupamento, **pergunte ao autor com perguntas objetivas estilo /grill-me** (uma ou mais chamadas de `AskUserQuestion`) cobrindo pelo menos:
- Confirmação do agrupamento proposto (aceitar como está / ajustar / dividir mais).
- Para cada arquivo que você não escreveu nesta sessão e não consegue avaliar com confiança: perguntar em vez de comitar às cegas.
- Se a variante "com sensíveis" estiver em jogo: quais arquivos específicos estão autorizados.

Só saia do modo plano apresentando o agrupamento final depois que as perguntas forem respondidas.

## Passo 3 — Revisão de conteúdo antes de stagear

Para qualquer arquivo que você não escreveu nesta conversa: dê uma olhada rápida no conteúdo antes de incluí-lo num commit. Se parecer um rascunho a meio caminho, **volte e pergunte ao autor** em vez de comitar.

## Passo 4 — Execução, grupo por grupo

Para cada grupo confirmado no passo 2, **nesta ordem**:

1. `git status --short` de novo — não presuma que o índice está vazio; outro agente pode ter deixado algo staged que não é seu.
2. Se o grupo exige `NEWS.md`: escreva/prepend a entrada agora, formato `## YYYY-MM-DD HH:MM — Título` (no seu fuso horário local), terminando com o bloco **Metadados de Execução** (Data/Hora, Agente, Mensagem do Commit, Arquivos afetados) — mesma convenção do `NEWS.md` já documentada no topo do próprio arquivo.
3. Se o grupo inclui export(s) novo(s) de `9-vers/llm-reviews/`: registre cada um na tabela `## Inventário` do `README.md` dessa pasta, no mesmo grupo.
4. `git add <caminho1> <caminho2> ...` — caminhos explícitos, um por um. **Nunca `git add .` nem `git add -A`.**
5. `Rscript tools/validate-governance.R` (sem `--sync`) como checkpoint. Trate os achados conforme o validador indicar.
6. Confirme `git status --short` mostrando **só** os arquivos deste grupo como staged.
7. `git commit -- <caminho1> <caminho2> ...` com pathspec explícito.

## Passo 5 — Casos especiais

- **Arquivos gerenciados por ferramentas externas** (ex. lockfiles): nunca editar o conteúdo manualmente. Comitar um lockfile/exportação que você não editou é seguro. Antes de comitar, certifique-se que o arquivo está bem formado. Comite **sozinho, em commit próprio**, nunca junto com mais nada.
- **`.git/index.lock`**: se o git acusar que o lock existe, espere ~3-5s e tente de novo, no máximo 3 vezes (~15s total). Se persistir, **pare e avise o autor** — nunca apague o lock sozinho; um lock órfão parece idêntico a um ativo do ponto de vista do agente.

## Passo 6 — Relatório final

Depois de todos os grupos comitados e `git status --short` limpo (ou só com o que ficou de fora deliberadamente), reporte ao autor:
- Quantos commits, o que entrou em cada um e por quê.
- O que ficou de fora e por quê.
- Qualquer correção que você precisou fazer no caminho (ex.: YAML dessincronizado).
- Se algo mudou entre o inventário do passo 1 e a execução.

## Não fazer

- Não rodar a cerimônia de encerramento de sessão (`finalizar-tarefa`) como parte desta skill.
- Não usar `--no-verify` para contornar o hook `pre-commit` sem autorização explícita do autor.
- Não decidir sozinho incluir um arquivo protegido "porque parece pronto".

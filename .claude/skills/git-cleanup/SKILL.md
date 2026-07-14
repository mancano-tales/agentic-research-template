---
name: git-cleanup
description: Limpa pendências acumuladas de `git status` num repositório multiagente — inventaria, agrupa por assunto, entra em modo plano fazendo perguntas objetivas sobre como organizar os commits, e só então executa commits temáticos com staging explícito, checkpoints de governança e documentação sincronizada (NEWS.md, inventário de llm-reviews). Consulta `CLAUDE.md` § "Configuração de Skills" para as particularidades deste repositório (diretório de autoria protegida, arquivo gerenciado externamente, pastas de trabalho contínuo).
---

# Limpar pendências de `git status`

Esta skill é **idêntica em todo repositório que a usa**. Toda particularidade de projeto (qual pasta é de autoria humana protegida, qual arquivo é gerenciado por ferramenta externa, quais pastas têm séries de trabalho contínuo) vem de `CLAUDE.md` § "Configuração de Skills" — nunca hardcoded aqui.

Procedimento para organizar e comitar o backlog de `git status` num repositório onde múltiplos agentes de IA trabalham em paralelo, então "comitar tudo de uma vez" está fora de cogitação. O `CLAUDE.md` de qualquer repositório que use esta skill proíbe explicitamente `git add .`/`-A` (**Strict Staging Policy**).

## Duas variantes, se a chave `diretorio_autoria_primaria` estiver preenchida

Se `CLAUDE.md` § "Configuração de Skills" tiver um valor para `diretorio_autoria_primaria`, existem duas variantes de execução:

- **Sem autoria primária (padrão — use esta a menos que o autor peça a outra explicitamente)**: nenhum arquivo dentro do `diretorio_autoria_primaria` entra em nenhum commit desta rodada, mesmo que apareça modificado no `git status`. Fica de fora e é reportado no final.
- **Com autoria primária**: permite incluir arquivos do `diretorio_autoria_primaria`, mas só arquivo por arquivo (ou unidade por unidade) com autorização explícita do autor **nesta própria conversa** — nunca por inferência ou porque "parece pronto". Pergunte por cada um individualmente na fase de plano (passo 2).

Se a chave estiver vazia, ignore esta seção — não há restrição de autoria a aplicar. Se o autor não especificou a variante ao invocar a skill (e a chave está preenchida), pergunte antes de prosseguir (pode ser a primeira pergunta do passo 2, não precisa ser uma etapa separada).

## Passo 1 — Inventário fresco

Rode `git status --short` você mesmo, agora. Nunca reutilize um inventário de uma mensagem anterior do usuário ou de um plano — o repositório muda sob seus pés entre uma leitura e outra (concorrência multiagente real, não hipotética).

## Passo 2 — Modo plano: proponha o agrupamento e pergunte antes de executar

**Entre em modo plano (`EnterPlanMode`) antes de rodar qualquer comando git que mute o repositório.** Nesta fase você só lê — `git status`, `git diff`, abrir arquivos para entender o que mudou.

Agrupe os itens do inventário por assunto lógico, não por "tudo junto". Padrões a considerar:

1. Uma série de scripts/arquivos dentro de uma pasta listada em `diretorios_trabalho_continuo` (`CLAUDE.md` § "Configuração de Skills") que forma um trabalho contínuo (mesmo prefixo, mesma pasta de análise).
2. Ferramentas novas em `tools/` — sempre precisam de entrada em `NEWS.md` (Regra 2 do `CLAUDE.md`: qualquer mudança relevante em código exige log; por analogia e pela "Synchronized Commit Policy", `tools/` recebe o mesmo tratamento das pastas de trabalho contínuo).
3. Scripts arquivados (ex.: uma pasta `old-scripts/`) — podem entrar sozinhos ou junto do item 2, com nota do porquê.
4. Exports de conversa em `9-vers/llm-reviews/*.md` — **sempre exigem uma linha na tabela `## Inventário` de `9-vers/llm-reviews/README.md` antes de comitar**, no mesmo commit.
5. O arquivo da chave `arquivo_gerenciado_externamente`, se preenchida — **sempre commit próprio, nunca misturado com mais nada** (ver passo 5).
6. Arquivos dentro de `diretorio_autoria_primaria` — só se a variante "com autoria primária" foi escolhida e cada arquivo foi autorizado individualmente.
7. Qualquer coisa que não se encaixe nos padrões acima — pergunte ao autor como agrupar, não decida sozinho.

Depois de montar a proposta de agrupamento, **pergunte ao autor com perguntas objetivas** (uma ou mais chamadas de `AskUserQuestion`) cobrindo pelo menos:
- Confirmação do agrupamento proposto (aceitar como está / ajustar / dividir mais).
- Para cada arquivo que você não escreveu nesta sessão e não consegue avaliar com confiança se está completo: perguntar em vez de comitar às cegas.
- Se a variante "com autoria primária" estiver em jogo: quais unidades específicas estão autorizadas.

Só chame `ExitPlanMode` (apresentando o agrupamento final acordado como o plano) depois que as perguntas relevantes tiverem sido respondidas. Não pule esta fase mesmo que o agrupamento pareça óbvio — é o checkpoint que existe precisamente para pegar os casos não-óbvios.

## Passo 3 — Revisão de conteúdo antes de stagear

Para qualquer arquivo que você não escreveu nesta conversa: dê uma olhada rápida no conteúdo antes de incluí-lo num commit. Se parecer um rascunho a meio caminho, ou você não conseguir avaliar com confiança, **volte e pergunte ao autor** em vez de comitar.

## Passo 4 — Execução, grupo por grupo

Para cada grupo confirmado no passo 2, **nesta ordem**:

1. `git status --short` de novo — não presuma que o índice está vazio; outro agente pode ter deixado algo staged que não é seu.
2. Se o grupo exige `NEWS.md` (regra 2 do `CLAUDE.md`): escreva/prepend a entrada agora, formato `## YYYY-MM-DD HH:MM (N) — Título` (fuso horário local do repositório — ver convenção no topo do próprio `NEWS.md`), terminando com o bloco **Metadados de Execução** (Data/Hora, Agente, Mensagem do Commit, Arquivos afetados).
3. Se o grupo inclui export(s) novo(s) de `9-vers/llm-reviews/`: registre cada um na tabela `## Inventário` do `README.md` dessa pasta, no mesmo grupo.
4. `git add <caminho1> <caminho2> ...` — caminhos explícitos, um por um. **Nunca `git add .` nem `git add -A`.**
5. `Rscript tools/validate-governance.R` (sem `--sync`) como checkpoint. Trate os achados:
   - **Caminho absoluto local (T1)** num script que você não escreveu: não reescreva a lógica de outra pessoa sem necessidade. Se o fix óbvio e seguro é trocar por um helper de caminho relativo do projeto preservando o comportamento, aplique e documente por quê. Se não for óbvio, pare e pergunte.
   - **Styler não-conforme** (aviso, não bloqueia): rode `styler::style_file()` nos arquivos apontados, confirme com um teste rápido (`source()`/rodar o script) que nada quebrou, re-stage.
   - **Divergência de status YAML×README de plano**, ou **plano concluído sem log de conversa vinculado**: corrija o campo específico que a mensagem de erro aponta (`status`, `relacionados`) antes de prosseguir — não são erros genéricos, o validador diz exatamente o que está errado.
6. Confirme `git status --short` mostrando **só** os arquivos deste grupo como staged.
7. `git commit -- <caminho1> <caminho2> ...` (pathspec explícito — nunca `-a`, nunca um `git commit` simples confiando num índice pré-populado por você ou por outro processo). Mensagem no padrão Conventional Commits + `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`.

## Passo 5 — Casos especiais

- **Arquivo da chave `arquivo_gerenciado_externamente`** (se preenchida): nunca editar o conteúdo — é gerenciado por uma ferramenta externa (ver a descrição da chave no `CLAUDE.md` deste repositório para qual ferramenta e por quê). Comitar um arquivo que você não editou é seguro (git não distingue quem escreveu os bytes); o risco real é pegar uma exportação/geração pela metade. Antes de comitar: confira que o arquivo termina bem-formado para o seu formato (ex.: `}` fechado no lugar certo para `.bib`/JSON, não truncado no meio de um campo). Comite **sozinho, em commit próprio**, nunca junto com mais nada. Não é preciso perguntar ao autor — só checar que não está truncado. Não precisa de entrada em `NEWS.md` (conteúdo não é decisão de agente).
- **`.git/index.lock`**: se o git acusar que o lock existe, espere ~3-5s e tente de novo, no máximo 3 vezes (~15s total). Se persistir, **pare e avise o autor** — nunca apague o lock sozinho; um lock órfão parece idêntico a um ativo do ponto de vista do agente.
- **Arquivos dentro de `diretorio_autoria_primaria`**: fora do commit por padrão (variante "sem autoria primária"). Só entram na variante "com autoria primária", arquivo por arquivo autorizado no passo 2.

## Passo 6 — Relatório final

Depois de todos os grupos comitados e `git status --short` limpo (ou só com o que ficou de fora deliberadamente), reporte ao autor:
- Quantos commits, o que entrou em cada um e por quê.
- O que ficou de fora e por quê (autoria primária não autorizada, arquivo que pareceu incompleto, arquivo gerenciado externamente truncado, etc.).
- Qualquer correção que você precisou fazer no caminho (ex.: caminho absoluto, YAML dessincronizado) — são achados reais, não ruído.
- Se algo mudou entre o inventário do passo 1 e a execução (esperado, dado o ritmo de um repositório multiagente).

## Não fazer

- Não rodar a cerimônia de encerramento de sessão (skill `close-task`: marcar plano concluído, exportar a conversa) como parte desta skill — são responsabilidades diferentes. Só rode `close-task` se o autor pedir separadamente.
- Não usar `--no-verify` para contornar o hook `pre-commit` sem autorização explícita do autor nesta conversa.
- Não decidir sozinho incluir um arquivo de `diretorio_autoria_primaria` "porque parece pronto" — autorização explícita, sempre.

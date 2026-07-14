---
name: request-audit
description: Gera um prompt estruturado de auditoria (Red-Teaming) para ser entregue a um agente independente, e salva esse prompt como plano versionado em 9-vers/plan/. Sem argumento, audita o trabalho recente do próprio agente na conversa atual; com argumento (caminho de arquivo/plano, hash de commit, ou texto livre descrevendo o alvo), redireciona a auditoria para esse alvo. Obriga a compilar evidência mecânica (git status/diff e output bruto de pelo menos 1 comando de verificação, não só prosa), apontar um plano versionado (nunca um artefato efêmero fora do repo), e instruir o auditor a ser cético, a verificar empiricamente (não só ler) e a respeitar um teto de rodadas antes de escalar ao autor humano.
---

# Solicitar Auditoria Independente (Red-Teaming)

Esta skill define o Procedimento Operacional Padrão (SOP) para gerar um dossiê de auditoria rigoroso do seu próprio trabalho. Siga as instruções abaixo para compor o prompt que o usuário entregará ao agente avaliador (Auditor Independente), e para salvá-lo como artefato versionado — não apenas como texto de chat.

**Por que a estrutura é rígida assim**: versões anteriores de skills deste tipo, em projetos irmãos deste template, já produziram dois incidentes reais que motivam as exigências abaixo — (1) um agente auditando o próprio trabalho tende a subestimar a severidade dos próprios problemas (uma autoauditoria cobriu só 3 de 8 problemas reais que um auditor externo encontrou no mesmo artefato), e (2) um arquivo de governança foi corrompido no disco por um processo concorrente sem que ninguém notasse até um auditor ler os arquivos fisicamente em vez de confiar num resumo em prosa. Por isso a seção A exige evidência mecânica, não relato.

## 1. O que você deve fazer

Você deve redigir um bloco de código Markdown contendo o prompt exato que o usuário vai copiar e colar para o auditor. O seu prompt **DEVE** conter obrigatoriamente as seções e diretivas listadas no Passo 3. Depois de composto, **salve-o como plano versionado** seguindo o Passo 5 — não entregue só um bloco de chat efêmero.

## 2. Interprete o Argumento da Skill (Direcionamento do Alvo)

Por padrão, esta skill audita **o seu próprio trabalho recente nesta conversa**. Isso só muda se o usuário passar um argumento ao invocar `/request-audit <argumento>`. Interprete o argumento assim (nenhuma dessas regras é mutuamente exclusiva — combine se o texto tiver mais de um sinal):

- **Sem argumento:** o alvo é o seu próprio trabalho mais recente nesta conversa (desde o último plano/commit relevante). Componha a seção C a partir do que você mesmo fez.
- **Argumento que é um caminho existente no repositório** (ex.: `tools/validate-governance.R`, `9-vers/plan/2026-XX-XX_....md`): o alvo é esse arquivo/plano especificamente. Rode `git log --oneline -- <caminho>` e `git diff` relevante para compor a evidência mecânica de escopo (seção A) a partir dele, não do seu próprio trabalho geral na conversa.
- **Argumento que parece um hash de commit** (7 a 40 caracteres hexadecimais): o alvo é esse commit. Use `git show --stat <hash>` (e `git show <hash>` para o diff completo) para compor o Cabeçalho de Contexto e a evidência mecânica de escopo.
- **Argumento em texto livre** (frase descrevendo um alvo ou pedido): trate como a declaração do usuário sobre o que auditar — incorpore **literalmente** esse direcionamento na seção C, não substitua pelo seu próprio resumo do que você acha mais relevante.
- **Em qualquer caso onde o alvo não for o seu próprio trabalho recente**: declare isso explicitamente no Cabeçalho de Contexto — o campo "Agente Autor" deve refletir quem de fato produziu o trabalho sendo auditado (pode não ser você), não ser preenchido por omissão com o seu próprio nome.

## 3. Estrutura Obrigatória do Prompt de Auditoria

O prompt gerado deve ter a seguinte estrutura:

### A. Cabeçalho de Contexto (Obrigatório)
- **Agente Autor:** Declare o seu nome (ex: Antigravity, Claude Code).
- **Timestamps:** Informe a data e hora de início e conclusão da tarefa, formato `YYYY-MM-DD HH:MM` (se a tarefa estiver em andamento, inclua um marcador explícito `[EM PROGRESSO]`).
- **Plano Fonte (obrigatório, deve ser um arquivo versionado):** Forneça o caminho relativo ao repositório de um plano em `9-vers/plan/YYYY-MM-DD_...md` com frontmatter YAML. **Nunca cite um artefato efêmero fora do repositório** (ex.: um `implementation_plan.md` interno de uma ferramenta, em `~/.gemini/...`, `~/.claude/...` ou equivalente) como se fosse equivalente — esses arquivos não são versionados, podem ser rotacionados/apagados pela própria ferramenta a qualquer momento, e citá-los quebra a Política de Planejamento do `CLAUDE.md` (que exige plano versionado para qualquer tarefa complexa). Se a tarefa não tiver um plano em `9-vers/plan/` ainda, **crie um antes de pedir a auditoria** — não use este campo como desculpa para pular essa etapa.
- **Evidência mecânica do escopo (obrigatório, não é opcional):** cole a saída literal de `git status --short` e/ou `git diff --cached --stat` (ou `git diff --stat` se ainda não estiver staged) diretamente no prompt. **Nunca substitua isto por um resumo em prosa do que foi alterado** — o auditor precisa de uma lista mecanicamente verificável do escopo real, não da versão que o autor lembra ou quer destacar.
- **Evidência bruta de verificação (obrigatório, mínimo 1):** cole o output literal e completo (não resumido, não parafraseado) de pelo menos um comando de teste/validação que você de fato rodou (ex.: a saída de `Rscript tools/validate-governance.R`, de um teste isolado, de um comando que reproduz o comportamento esperado). Um agente que está alucinando o próprio sucesso ou não tem consciência de um erro não consegue relatar corretamente esse erro em prosa — mas não consegue forjar convincentemente um output bruto de terminal sem que a fabricação fique aparente para o auditor. Isso não substitui a evidência mecânica de escopo acima; complementa.
- **Aviso de caminho absoluto:** antes de finalizar o prompt, releia-o procurando por `C:\Users\`, `/home/`, `/Users/` ou qualquer caminho absoluto local. Se encontrar, substitua por caminho relativo ao repositório. Isso importa porque, se este prompt for salvo como plano em `9-vers/plan/` (Passo 5), **as travas de governança existentes podem não cobrir esse caso automaticamente** — confira no `tools/validate-governance.R` deste projeto se a checagem de caminho absoluto (tipicamente chamada T1/T5 nos projetos que seguem este template) varre novos arquivos de plano/prompt, ou só um conjunto fixo de documentos. Se não varrer, a responsabilidade de não vazar caminho local aqui é sua, não do validador.

### B. Diretiva de Ceticismo e Verificação Empírica (A Regra de Ouro)
Você deve inserir explicitamente este aviso no início do prompt para o auditor:
> *"IMPORTANTE: Não tome nada do que o agente autor diz neste prompt pelo valor de face. O agente que escreveu o código/texto pode estar alucinando o seu próprio sucesso ou ignorando falhas lógicas. Você deve ser extremamente crítico, cético, e verificar os arquivos fisicamente de forma independente. Comece em modo leitura (visualizando arquivos, lendo diffs, conferindo a evidência mecânica de escopo e o output bruto acima). Depois de formar uma hipótese sobre um problema, você PODE e DEVE rodar comandos de verificação não-destrutivos para confirmá-la empiricamente antes de reportá-la como achado — por exemplo `Rscript tools/validate-governance.R`, um teste isolado num diretório temporário, ou reproduzir o bug alegado com um script mínimo. Não aceite nem rejeite uma alegação técnica só por parecer plausível na leitura; teste."*

### C. Escopo do Trabalho e Áreas de Vulnerabilidade (Foco da Auditoria)
- **Resumo do que foi feito:** Explique brevemente o que você implementou.
- **Auto-Crítica / Fragilidades:** Liste áreas onde a sua solução pode ser frágil. Para cada uma, declare explicitamente **se você já tentou mitigar e como, ou se está deliberadamente deixando sem mitigação e por quê** — não liste fragilidades como perguntas retóricas em aberto para o auditor resolver sozinho (ex.: em vez de "isso pode ser um problema de concorrência?", escreva "não tratei concorrência aqui; risco aceito porque X" ou "tratei com Y, mas não testei o caso Z"). Exemplos de categorias a considerar: limitações de regex, tratamento de concorrência/`index.lock`, encoding, edge cases esquecidos.

### D. Formato de Resposta Exigido do Auditor
O seu prompt deve instruir o auditor a retornar a análise estruturada com as seguintes seções (mesma convenção da funcionalidade nativa de code review do Claude Code — se o ambiente do auditor tiver a ferramenta `ReportFindings`, ele deve usá-la; senão, replicar a mesma estrutura em prosa):
1. **Avaliação Geral:** Uma análise qualitativa rigorosa da robustez da arquitetura implementada.
2. **Veredito Categórico:** O auditor DEVE escolher e declarar exatamente um destes vereditos:
   - `[APROVADO]` (A solução é robusta e pronta para produção).
   - `[REQUER REFATORAÇÃO MENOR]` (Pequenos ajustes necessários).
   - `[REQUER REFATORAÇÃO ESTRUTURAL]` (A solução possui vulnerabilidades graves).
   - `[DESCARTADO]` (Over-engineering excessivo, ou a abordagem está incorreta desde a premissa).
3. **Lista de Achados, ordenada do mais grave ao menos grave.** Cada achado individual DEVE ter:
   - **Resumo de uma frase** do defeito.
   - **Cenário de falha concreto**: input/estado específico → output errado/crash. Não "isso pode falhar sob concorrência" — sim "dois agentes rodando X ao mesmo tempo perdem a atualização de Y, reproduzido rodando Z".
   - **Veredito do achado**: `CONFIRMED` (reproduziu empiricamente — rodou o código/comando e viu o problema acontecer) ou `PLAUSIBLE` (identificou por leitura/raciocínio, não testou). Nunca omita esta tag — é o que diferencia um achado verificado de uma suspeita.
   - Se houver uma rodada de correção seguida de nova auditoria (ver seção E), o agente executor re-reporta cada achado antigo com `outcome`: `fixed` / `skipped` / `no_change_needed`, em vez de reescrever a lista do zero.

### E. Após o Veredito (Teto de Rodadas)
O seu prompt deve instruir explicitamente:
> *"Se o veredito for `[REQUER REFATORAÇÃO MENOR]` ou `[REQUER REFATORAÇÃO ESTRUTURAL]`, o agente executor deve corrigir os itens e pode pedir **no máximo mais uma rodada** de auditoria independente. Se a segunda rodada também resultar em `[REQUER REFATORAÇÃO ESTRUTURAL]` ou `[DESCARTADO]`, o agente executor PARA e escala a decisão ao autor humano em vez de iniciar uma terceira rodada de auditoria sozinho — sem isso, o ciclo de auditoria cruzada entre agentes pode continuar indefinidamente, gastando tempo e tokens sem convergir. Uma autoauditoria do próprio agente autor (em vez de um agente independente) nunca conta como uma dessas rodadas."*

## 4. Registro no `NEWS.md`
Se a criação ou alteração desta skill (ou de qualquer skill em `.claude/skills/`) for o próprio objeto da tarefa, ela segue a Synchronized Commit Policy do `CLAUDE.md` como qualquer outra mudança de governança: precisa de entrada em `NEWS.md` com o bloco de Metadados de Execução, no mesmo commit.

## 5. Entrega e Versionamento

Depois de compor o prompt com a estrutura acima:
1. **Salve-o** como `9-vers/plan/YYYY-MM-DD_Prompt_<slug-descritivo>.md`, com o frontmatter YAML padrão do repositório (`tipo: Prompt`, `status: ATIVO`, `criado: "YYYY-MM-DD HH:MM"`, etc. — ver `9-vers/plan/README.md` § Diretrizes de Formatação). O corpo do arquivo, depois do cabeçalho em blockquote padrão (Status/O que é/Elaborado por/Por quê/Como usar), é o prompt em si.
2. **Registre-o** no índice rodando `Rscript tools/validate-governance.R --sync`.
3. **Só então** entregue ao usuário, informando o caminho do arquivo salvo (para ele copiar/apontar o auditor) — nunca só um bloco de chat sem contrapartida versionada.

# Princípios

> O que este template acredita, e por quê. O [README](README.md) explica *como instalar*; este documento explica *o que você está adotando*.

Este template existe para tornar seguro o trabalho cooperativo entre humanos e agentes de IA num repositório de pesquisa. Cada princípio abaixo nasceu de uma falha medida, não de preferência estética — onde houver um incidente na origem, ele está citado.

---

## 1. Policy-as-code

> *"Prompt-level safety ('please follow the rules') is not a control surface. It is a polite request to a stochastic system."*
> — [`microsoft/agent-governance-toolkit`](https://github.com/microsoft/agent-governance-toolkit)

Uma regra escrita em prosa no `AGENTS.md` é uma intenção. Uma regra que roda no `pre-commit` é uma trava. As duas são necessárias e **não são intercambiáveis**: o arquivo de instruções carrega o que exige julgamento, os hooks carregam o que é verificável.

O corolário prático é que o `AGENTS.md` **não deve ser usado como linter**. "Sempre prefira caminhos relativos" não é uma linha de prosa — é a trava T1 do `tools/validate-governance.R`. Quando uma regra pode ser verificada mecanicamente, escrevê-la em prosa é escolher a versão mais fraca dela.

**Falso bloqueio é problema de segurança, não de conforto.** Uma trava reconhecidamente injusta é a que ensina o agente a usar `--no-verify` — e isso desliga junto todas as travas legítimas. Por isso a validação de `llm-reviews` foi rebaixada a aviso, e por isso o `hooks/commit-msg` bloqueia só o objetivamente verificável (forma do cabeçalho, tipo fora da lista, comprimento) e apenas **avisa** sobre heurísticas que produzem falso positivo.

**Limites que este template não finge remover**, todos comprovados por teste: `--no-verify` desliga qualquer hook client-side; `core.hooksPath` é configuração local e não viaja no clone; e um hook versionado não se protege contra um commit que o substitua por `exit 0`. Onde a garantia precisa ser real, a mesma validação tem de rodar no CI, exigida como status check na proteção de branch.

## 2. Transparência

O agente declara o que fez, o que pulou e por quê. **Passo pulado e declarado é aceitável; pulado em silêncio corrompe a auditoria** — a diferença entre as duas coisas é toda a diferença entre um log e uma ficção.

Daí decorrem três regras concretas:

- **Staging cirúrgico.** Agentes nunca usam `git add .` ou `-A`, apenas os arquivos em que trabalharam. Isso preserva o trabalho em andamento do humano e torna cada commit legível.
- **Contexto declarado, nunca inferido.** O `hooks/pre-commit` passa `--hook` explicitamente ao validador. A versão anterior inferia o contexto a partir do número de arquivos no stage — e um `git commit --allow-empty` produzia lista vazia, fazendo o validador concluir que não estava rodando como hook e pular a trava inteira. Inferir contexto a partir de dados que o usuário controla é a forma errada de detectar contexto.
- **Válvulas nomeadas em vez de escape genérico.** `GOVERNANCE_AMEND=1` declara a intenção de emendar um commit, avalia contra `HEAD^` e **mantém todas as outras travas rodando**. É preferível a `--no-verify` porque nomeia o que está sendo dispensado e fica visível no histórico.

## 3. Reprodutibilidade

O repositório precisa funcionar em outra máquina, com outro usuário, em outro ponto de montagem. Três consequências:

- **Nenhum caminho absoluto.** Trava T1 do validador. Um `C:\Users\Fulano\...` num plano ou num log quebra no instante em que alguém clona. Já custou caro: um único log de conversa exportado chegou a conter 108 ocorrências, reprovado pelo próprio validador que o repositório impõe.
- **Nada de específico do projeto dentro de artefato compartilhado.** Skills e scripts leem o que varia da tabela **§ Configuração de Skills** do `AGENTS.md` do consumidor — nunca fixam no texto. O diretório de governança é o exemplo canônico: já oscilou entre `9-vers/`, `0-meta/` e `0-governance/`, e cada edição consertava um repositório e quebrava os outros, porque **o valor não pertence à skill**.
- **Cópia, não link.** A sincronização entre repositórios é por cópia explícita (`tools/sync-skills.ps1`), nunca por junction ou symlink. Links entre repositórios distintos já se mostraram frágeis sob renomeação de pasta e sincronização de nuvem; cópia funciona em qualquer sistema operacional, sem exigir Developer Mode ou privilégio de administrador — o que importa para um template público. E **nunca há sincronização automática ou silenciosa**: puxar atualização é ato deliberado, com revisão e commit.

## 4. Changelog intelectual

O `NEWS.md` é um **changelog intelectual**: registra a decisão e o raciocínio que levou a ela, não a lista de arquivos tocados. Entrada mais recente no topo, **nunca reescrita** — é log histórico, não documentação viva. Quando uma afirmação antiga se revela errada, a correção é uma entrada nova que a contradiz com data; apagar o erro apagaria a própria evidência de que a governança funcionou.

Isto o separa de dois artefatos vizinhos, com os quais é frequentemente confundido:

| Artefato | O que é | Fonte |
|---|---|---|
| `NEWS.md` | changelog **intelectual** — decisões, raciocínio, incidentes | escrito à mão, editorial |
| `CHANGELOG` | changelog **de código** — o que mudou, por categoria | **derivado** do `git log` por `tools/render-changelog.R` |
| `git log` | o que aconteceu, com hash e autor | o Git |

**Por que derivar em vez de armazenar.** Uma versão anterior desta regra exigia o hash do commit escrito na entrada do changelog. É insatisfazível: o hash é o SHA do conteúdo do commit, então gravá-lo num arquivo que esse mesmo commit versiona altera o conteúdo e, portanto, o hash. É ponto fixo, não falha de implementação — `git commit --amend` só produz um hash novo, igualmente não registrado. Num repositório consumidor onde a regra foi adotada, o resultado foram **seis commits de "backfill do hash" num único dia**, cada um corrigindo o anterior e nenhum registrando o próprio. O `NEWS.md` segue como fonte editorial, sem hashes; o Git segue como fonte dos hashes; o `render-changelog.R` junta os dois.

O formato das entradas segue [**Keep a Changelog 1.1.0**](https://keepachangelog.com/), e as **linhas adicionadas** são validadas contra ele — não apenas a presença do arquivo no stage. Checar presença reduz a regra a ritual: um `NEWS.md` contendo a string `xxxxx` passaria.

**Synchronized Commit Policy (co-commit).** Todo commit com mudança de funcionalidade ou documentação inclui a atualização do `NEWS.md` — e o status do plano, quando aplicável — na **mesma transação**. Separar a mudança funcional do registro é exatamente o que produz deriva histórica. A trava roda fora do guarda de "há arquivos no stage", então `--allow-empty` não escapa.

**Rigor de timestamp.** Data isolada não basta: cabeçalhos de entrada, o campo `Data/Hora` dos Metadados de Execução e os campos `criado`/`concluido` dos planos exigem `YYYY-MM-DD HH:MM` no fuso local. Se a hora não puder ser recuperada com confiança, deixe só a data e explique — **nunca invente um horário**.

## 5. Conventional Commits

As mensagens seguem [**Conventional Commits 1.0.0**](https://www.conventionalcommits.org/), validadas por `hooks/commit-msg`. A razão não é cosmética: é o que torna o `CHANGELOG` derivável. `tools/render-changelog.R` mapeia tipo de commit para categoria do Keep a Changelog, e essa tradução só existe porque o tipo é obrigatório e vem de uma lista fechada.

O hook bloqueia o objetivamente verificável — forma do cabeçalho, tipo fora da lista, mais de 72 caracteres, ponto final, `BREAKING CHANGE:` sem `!` — e **apenas avisa** sobre descrição em gerúndio ou particípio, porque a heurística de sufixo não distingue verbo de substantivo: `estado`, `comando` e `pedido` seriam rejeitados indevidamente. Ignora `Merge`, `Revert`, `fixup!` e `squash!`, que o próprio Git gera.

## 6. Arquivamento dos logs de LLM

Toda sessão de agente termina com o log exportado para `{gov}/llm-reviews/` e registrado na tabela de inventário de `{gov}/llm-reviews/README.md`.

O motivo é que **a conversa é a única evidência do raciocínio**. O diff mostra o que mudou; o log mostra o que o agente considerou, o que descartou e o que o humano corrigiu no meio do caminho. Sem ele, uma decisão registrada no `NEWS.md` é uma afirmação sem procedência, e uma auditoria posterior não tem como distinguir julgamento de alucinação.

O exportador (`tools/export_conversa.R`) resolve o diretório de destino nesta ordem: **(1)** env var `GOV_DIR`, **(2)** detecção em disco, **(3)** fallback — e **sanea caminhos absolutos**, porque exportar um log que o próprio T1 vai reprovar transforma a regra numa armadilha.

Isto já falhou de modo instrutivo: um export gravado num diretório que o `.gitignore` do consumidor não rastreava ficou **fora do controle de versão por um dia**, existindo em disco e não existindo para o Git, sem que nada avisasse. A correção não foi mover o arquivo — foi eliminar o caminho fixo que causou a classe inteira do bug.

## 7. Plano antes de execução

Tarefa complexa, multi-etapas ou com decisão arquitetural exige um plano datado em `{gov}/plan/` **antes** de qualquer edição, aprovado pelo autor humano. O plano é o detalhe; o `TODO.md` é o índice curto; o `{gov}/plan/README.md` é o índice de status.

Só planos `ATIVO` ou `EM EXECUÇÃO` orientam o trabalho corrente. Os demais status — `PARCIAL`, `CONCLUÍDO`, `SUPERADO`, `HISTÓRICO` — são referência histórica e **nunca são reescritos retroativamente**, pela mesma razão do `NEWS.md`.

## 8. Uma peça, um dono

| Repositório | É dono de |
|---|---|
| [`skills`](https://github.com/mancano-tales/skills) | as skills — os procedimentos, o *como* |
| **este template** | hooks, policy-as-code, validador, estrutura — o que torna a regra obrigatória |

Este template é **consumidor** das skills, como qualquer outro projeto. A interface entre os dois é a seção § Configuração de Skills.

A regra existe porque a alternativa foi testada e falhou. Enquanto duas fontes se declaravam donas das mesmas skills, o relatório de sincronização comparava contra uma origem ambígua e dizia "em dia" ou "desatualizada" sem que a palavra significasse nada. Dois casos medidos, um em cada direção: uma correção nascida num consumidor nunca voltou para a origem e foi reimplementada do zero seis dias depois; e uma decisão registrada aqui nunca saiu daqui — onze dias depois o valor antigo persistia nas cópias que os agentes de fato carregam.

**Ainda não está resolvido.** A `close-task` pode ser tornada agnóstica ao repositório, mas ela invoca `validate-governance.R` e `export_conversa.R` — que vivem neste repositório. Um agente pode resolver o diretório certo e entregá-lo a ferramentas que o descartam em silêncio. A fronteira, como está desenhada, **corta no meio de um problema único**, e isso é uma questão aberta e não um detalhe de implementação.

---

## Onde cada princípio é aplicado

| Princípio | Artefato |
|---|---|
| Policy-as-code | `tools/validate-governance.R`, `hooks/pre-commit`, `hooks/commit-msg` |
| Transparência | staging cirúrgico (`AGENTS.md`), `--hook`, `GOVERNANCE_AMEND` |
| Reprodutibilidade | trava T1, § Configuração de Skills, `tools/sync-skills.*` |
| Changelog intelectual | `NEWS.md`, `tools/render-changelog.R`, trava T7 |
| Conventional Commits | `hooks/commit-msg` |
| Arquivamento de logs | `tools/export_conversa.R`, `{gov}/llm-reviews/README.md` |
| Plano antes de execução | `{gov}/plan/`, `{gov}/plan/README.md`, `TODO.md` |
| Uma peça, um dono | § Skills Compartilhadas do `AGENTS.md` |

> **Convenção de caminho**: `{gov}` representa o valor da chave `diretorio_governanca` na § Configuração de Skills do `AGENTS.md` — `9-vers/` neste template, outro valor nos consumidores que renomeiam.

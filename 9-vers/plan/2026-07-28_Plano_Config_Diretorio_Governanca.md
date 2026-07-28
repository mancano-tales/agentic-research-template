---
tipo: Plano
titulo: "Promover a chave de configuração diretorio_governanca (skills config-driven, sem hardcode de 9-vers/)"
status: ATIVO
criado: "2026-07-28 01:54"
concluido: null
agentes:
  orquestrador: "Claude Opus 4.8 (Claude Code, VS Code)"
  executor: null
  auditor: null
autor_humano: "Tales Mançano"
tarefas:
  - { desc: "Adicionar chave diretorio_governanca à tabela § Configuração de Skills do CLAUDE.md", status: pendente, data: null }
  - { desc: "Trocar 9-vers/ hardcoded por referência à chave nas 4 skills de governança", status: pendente, data: null }
  - { desc: "Parametrizar PATH_* de 9-vers em tools/validate-governance.R e export_conversa.R", status: pendente, data: null }
  - { desc: "Atualizar README, GUIDANCE_MAP e .cursor com a convenção config-driven", status: pendente, data: null }
relacionados: ["2026-07-14_Plano_Skills_Compartilhadas_TODO.md"]
news: []
---

# Plano — Promover a chave de configuração `diretorio_governanca`

> **Status**: ATIVO (proposto — aguarda aprovação do autor antes de execução da refatoração)
> **O que é este documento**: proposta para eliminar o hardcode de `9-vers/` nas skills de governança e nas ferramentas, movendo o nome do diretório de governança para uma chave nomeada na § "Configuração de Skills" do `CLAUDE.md` — do mesmo jeito que `diretorio_autoria_primaria`, `script_exportar_conversa` etc. já são resolvidos.
> **Elaborado por**: Claude Opus 4.8 (Claude Code, VS Code)
> **Por quê**: ver § Motivação abaixo.
> **Como usar**: revisar as mudanças propostas na § 1; ao aprovar, executar o checklist da § 2 em um único round temático e validar pela § 3. **Não executar a refatoração das skills sem aprovação explícita** (lição da padronização revertida — ver § Motivação).

---

## Motivação (o problema de design)

O próprio `CLAUDE.md` deste repositório-mãe (§ "Skills Compartilhadas Entre Projetos") estabelece a doutrina:

> "Skills de governança... **nunca hardcodeiam caminho, nome de arquivo ou convenção específica de um projeto.** Qualquer particularidade de repositório vem da seção 'Configuração de Skills', nunca do texto da própria skill — isso é o que permite comparar skills por hash entre repositórios e ter um sinal de 'em dia'/'desatualizada' que significa alguma coisa de verdade."

Na prática, **4 skills violam essa própria doutrina** ao hardcodar o literal `9-vers/`:

- `.claude/skills/close-task/SKILL.md` — `9-vers/plan/`, `9-vers/llm-reviews/README.md`, `9-vers/llm-reviews/`
- `.claude/skills/export-conversation/SKILL.md` — `9-vers/llm-reviews/` (inclusive na `description` do frontmatter)
- `.claude/skills/git-cleanup/SKILL.md` — `9-vers/llm-reviews/*.md`, `9-vers/llm-reviews/README.md`
- `.claude/skills/request-audit/SKILL.md` — `9-vers/plan/...`, `9-vers/plan/README.md`

As ferramentas em R também fixam o nome: `tools/validate-governance.R` (`PATH_PLAN_DIR`, `PATH_REVIEWS_INDEX`, `PATH_BACKUP_DIR`, `GOVERNANCE_DOCS`) e `tools/export_conversa.R`.

**Consequência concreta, já observada:** o consumidor `MancanoSync` (raiz) usa `0-meta/` como diretório de governança e precisou, no seu próprio `CLAUDE.md`, criar a chave `diretorio_governanca` **e** anotar um remendo textual — *"skills que citarem `9-vers/` literalmente devem ser lidas como `0-meta/` aqui"*. Ou seja: as skills chegam byte-idênticas da mãe (bom para o sinal de hash do `sync-skills`), mas **factualmente erradas** naquele repositório, corrigidas só por uma nota de rodapé que o agente precisa lembrar de aplicar. Esse é exatamente o tipo de deriva que a doutrina config-driven existe para evitar.

Há ainda a tentativa de **padronização revertida** (`78b5315` → revert `40bc2d6`): renomear fisicamente `9-vers/ → 0-governance/` foi tentado e desfeito. Isso reforça a leitura de que **renomear o diretório não é o caminho** — a solução correta é parametrizar o nome por configuração, deixando cada repositório escolher o seu (`9-vers/` na mãe, `0-meta/` no MancanoSync) sem tocar no texto das skills.

---

## 1. Mudanças Propostas

### CLAUDE.md (§ Configuração de Skills)

*   **[MODIFY]** `CLAUDE.md` — adicionar a linha da chave nova à tabela:

    | Chave | Usada por | Valor neste repositório |
    |---|---|---|
    | `diretorio_governanca` | `close-task`, `export-conversation`, `git-cleanup`, `request-audit`, `tools/*.R` | `9-vers/` (mãe). Consumidores sobrescrevem: `MancanoSync` usa `0-meta/`. |

    (Propagará via hard link para `AGENTS.md` e `.github/copilot-instructions.md` — usar o self-heal de `validate-governance.R`, não editar os links à mão.)

### Skills de governança (trocar literal por referência à chave)

*   **[MODIFY]** `.claude/skills/close-task/SKILL.md`
*   **[MODIFY]** `.claude/skills/export-conversation/SKILL.md`
*   **[MODIFY]** `.claude/skills/git-cleanup/SKILL.md`
*   **[MODIFY]** `.claude/skills/request-audit/SKILL.md`

    Padrão de substituição: onde hoje está `9-vers/plan/`, passar a escrever "o diretório de planos (`<diretorio_governanca>/plan/`, ver `CLAUDE.md` § Configuração de Skills)" — mesma fórmula que as skills já usam para as outras chaves. **Decisão de design a bater com o autor**: manter um exemplo concreto entre parênteses (legibilidade) OU referência pura (hash idêntico entre mãe e consumidores). A segunda é mais fiel à doutrina; a primeira é mais legível. Recomendo referência pura com o valor-exemplo saindo só da tabela do `CLAUDE.md`.

### Ferramentas em R (parametrizar o prefixo)

*   **[MODIFY]** `tools/validate-governance.R` — extrair o literal `"9-vers"` para uma constante única (`GOV_DIR`), idealmente lida de uma fonte de verdade (env var `GOV_DIR`, ou 1ª linha de um `tools/.gov-dir`, com fallback para `"9-vers"`), e derivar `PATH_PLAN_DIR`, `PATH_REVIEWS_INDEX`, `PATH_BACKUP_DIR`, `GOVERNANCE_DOCS` e os filtros `^9-vers/llm-reviews/` a partir dela.
*   **[MODIFY]** `tools/export_conversa.R` — mesmo tratamento para o destino de export.

### Documentação de apoio

*   **[MODIFY]** `README.md` (organograma cita `9-vers/`), `9-vers/GUIDANCE_MAP.md`, `.cursor/rules/governance.mdc` — anotar que o nome do diretório é configurável e que `9-vers/` é apenas o default da mãe.

---

## 2. Cronograma de Tarefas (Checklist)

- [ ] Bater com o autor a decisão de design (referência pura vs. exemplo entre parênteses) e a fonte de verdade do `GOV_DIR` nas ferramentas R (env var vs. arquivo `tools/.gov-dir`).
- [ ] Adicionar `diretorio_governanca` à tabela § Configuração de Skills do `CLAUDE.md`.
- [ ] Refatorar as 4 skills para consumir a chave, sem hardcode de `9-vers/`.
- [ ] Parametrizar `validate-governance.R` e `export_conversa.R`.
- [ ] Atualizar `README.md`, `GUIDANCE_MAP.md`, `.cursor/rules/governance.mdc`.
- [ ] Recriar hard links de `AGENTS.md`/`copilot-instructions.md` via self-heal; co-commitar `NEWS.md` + índice de planos.
- [ ] Registrar no plano de consumidores (fora deste repo) que um `sync-skills --apply` é necessário para receber as skills refatoradas.

---

## 3. Plano de Validação e Verificação

### Testes Automatizados
- `Rscript tools/validate-governance.R` (default `9-vers/`) — deve continuar passando byte-a-byte com o comportamento atual: a parametrização não pode alterar nenhum caminho na mãe.
- Rodar o validador com `GOV_DIR=0-meta` (ou equivalente) apontando para uma árvore de teste, confirmando que os caminhos derivam corretamente.

### Verificação Manual
- `git grep -n "9-vers" .claude/skills/` deve voltar **vazio** após a refatoração das skills (o literal só pode sobrar em `CLAUDE.md`/README/GUIDANCE como valor-default documentado).
- Conferir que `sync-skills.ps1` em modo relatório reporta as 4 skills como "em dia" contra um consumidor que use `0-meta/` — o que só é verdade se o texto ficou realmente livre de particularidade de repositório.

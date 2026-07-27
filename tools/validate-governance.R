#!/usr/bin/env Rscript
# ==============================================================================
# validate-governance.R — QA de Governança para Planos e Logs de IA
#
# Uso:
#   Rscript tools/validate-governance.R [--sync]
#
# Parâmetros:
#   --sync  Atualização CONSERVADORA do índice plan/README.md: só reescreve a
#           linha de um plano quando o frontmatter YAML existe e o status
#           diverge do índice; preserva verbatim linhas legadas/curadas e
#           adiciona no topo planos novos com YAML. Nunca inventa status.
#
# Retorna exit code 0 se tudo estiver íntegro, ou 1 se houver inconsistências.
# ==============================================================================

# ── Configurações de Caminho ──────────────────────────────────────────────────
CWD <- getwd()
PATH_PLAN_DIR <- file.path(CWD, "9-vers", "plan")
PATH_PLAN_INDEX <- file.path(PATH_PLAN_DIR, "README.md")
PATH_REVIEWS_INDEX <- file.path(CWD, "9-vers", "llm-reviews", "README.md")

# Backups do self-heal de hard link (seção 0) vão para uma subpasta dedicada,
# não a raiz do repo — antes de 2026-07-15 eram escritos direto em
# "AGENTS.md.bak.<timestamp>"/"CLAUDE.md.bak.<timestamp>" na raiz, que
# acumulava (achado em um repositório consumidor: 5 arquivos reais na raiz)
# e poluía visualmente o diretório principal do repositório. Gitignorado por
# *.bak.* já existente.
PATH_BACKUP_DIR <- file.path(CWD, "9-vers", "backups")
make_backup_path <- function(basename) {
  dir.create(PATH_BACKUP_DIR, recursive = TRUE, showWarnings = FALSE)
  file.path("9-vers", "backups", basename)
}

# ── Helpers de Impressão ──────────────────────────────────────────────────────
cat_info <- function(...) cat("ℹ ", paste0(...), "\n")
cat_success <- function(...) cat("✅ ", paste0(...), "\n")
cat_warn <- function(...) cat("⚠ ", paste0(...), "\n")
cat_error <- function(...) cat("❌ ", paste0(...), "\n")

# ── 0. Sincronizar CLAUDE.md e AGENTS.md se divergirem (Self-healing Link) ───
if (file.exists("CLAUDE.md") && file.exists("AGENTS.md")) {
  mtime_claude <- file.info("CLAUDE.md")$mtime
  mtime_agents <- file.info("AGENTS.md")$mtime
  content_claude <- readLines("CLAUDE.md", warn = FALSE, encoding = "UTF-8")
  content_agents <- readLines("AGENTS.md", warn = FALSE, encoding = "UTF-8")

  # Nova verificação de segurança contra conflitos de merge nos arquivos de contexto
  if (any(grepl("^<<<<<<<", content_claude)) || any(grepl("^<<<<<<<", content_agents))) {
    cat_error("Conflitos de merge detectados em CLAUDE.md ou AGENTS.md. Sincronização automática suspensa.")
    quit(status = 1)
  }

  if (!identical(content_claude, content_agents)) {
    cat_warn("Divergência detectada entre CLAUDE.md e AGENTS.md (possível quebra de link por salvamento atômico).")

    # Calcular diferença absoluta de tempo em segundos
    diff_time <- abs(difftime(mtime_claude, mtime_agents, units = "secs"))

    if (diff_time <= 2) {
      cat_error("Timestamps de modificação muito próximos (<= 2s). Sincronização automática suspensa para evitar perda de dados.")
      cat_error("Por favor, verifique manualmente os arquivos CLAUDE.md e AGENTS.md.")
      quit(status = 1)
    } else {
      if (mtime_claude > mtime_agents) {
        cat_info("Sincronizando: CLAUDE.md (mais recente) -> AGENTS.md. Recriando Hard Link...")
        bak_name <- make_backup_path(sprintf("AGENTS.md.bak.%s", format(Sys.time(), "%Y%m%d-%H%M%S")))
        file.copy("AGENTS.md", bak_name, overwrite = TRUE)
        cat_warn(paste("Backup criado em:", bak_name))

        file.remove("AGENTS.md")
        link_success <- FALSE
        if (.Platform$OS.type == "windows") {
          # system2("cmd.exe", ...) diretamente, NUNCA shell("cmd /c ...").
          # Causa raiz encontrada e confirmada empiricamente: quando a
          # variável de ambiente SHELL aponta para o bash do Git (é o caso
          # sob o hook de pre-commit, que roda dentro do Git Bash/MSYS2),
          # shell() não invoca cmd.exe — abre um cmd.exe interativo aninhado
          # que nunca executa "mklink" de fato (o mklink real nunca roda; o
          # link nunca é criado). system2() chamando cmd.exe diretamente,
          # com os argumentos como vetor, contorna esse problema por
          # completo — testado e confirmado neste exato ambiente.
          mklink_out <- suppressWarnings(tryCatch(
            system2("cmd.exe", c("/c", "mklink", "/h", "AGENTS.md", "CLAUDE.md"), stdout = TRUE, stderr = TRUE),
            error = function(e) character(0)
          ))
          mklink_status <- attr(mklink_out, "status")
          link_success <- (is.null(mklink_status) || mklink_status == 0) && file.exists("AGENTS.md")
        } else {
          link_success <- tryCatch(
            {
              system("ln CLAUDE.md AGENTS.md", intern = TRUE)
              TRUE
            },
            error = function(e) FALSE
          )
        }
        if (!link_success || !file.exists("AGENTS.md")) {
          cat_warn("Falha ao criar link físico (permissão ou volumes distintos). Fazendo fallback para cópia física...")
          file.copy("CLAUDE.md", "AGENTS.md", overwrite = TRUE)
        }
      } else {
        cat_info("Sincronizando: AGENTS.md (mais recente) -> CLAUDE.md. Recriando Hard Link...")
        bak_name <- make_backup_path(sprintf("CLAUDE.md.bak.%s", format(Sys.time(), "%Y%m%d-%H%M%S")))
        file.copy("CLAUDE.md", bak_name, overwrite = TRUE)
        cat_warn(paste("Backup criado em:", bak_name))

        file.remove("CLAUDE.md")
        link_success <- FALSE
        if (.Platform$OS.type == "windows") {
          # Ver comentário no ramo espelhado acima (CLAUDE.md -> AGENTS.md)
          # sobre por que system2("cmd.exe", ...) substitui shell("cmd /c ...").
          mklink_out <- suppressWarnings(tryCatch(
            system2("cmd.exe", c("/c", "mklink", "/h", "CLAUDE.md", "AGENTS.md"), stdout = TRUE, stderr = TRUE),
            error = function(e) character(0)
          ))
          mklink_status <- attr(mklink_out, "status")
          link_success <- (is.null(mklink_status) || mklink_status == 0) && file.exists("CLAUDE.md")
        } else {
          link_success <- tryCatch(
            {
              system("ln AGENTS.md CLAUDE.md", intern = TRUE)
              TRUE
            },
            error = function(e) FALSE
          )
        }
        if (!link_success || !file.exists("CLAUDE.md")) {
          cat_warn("Falha ao criar link físico (permissão ou volumes distintos). Fazendo fallback para cópia física...")
          file.copy("AGENTS.md", "CLAUDE.md", overwrite = TRUE)
        }
      }
    }
  }
}

# ── 0b. Sincronizar .github/copilot-instructions.md a partir de CLAUDE.md ────
# Terceiro hard link criado por setup.ps1/setup.sh, mas que a auto-cura da
# seção 0 nunca cobriu (achado da auditoria de 2026-07-12) — CLAUDE.md podia
# divergir dele indefinidamente sem nenhum alerta do pre-commit. Direção
# única (CLAUDE.md -> copilot-instructions.md, não bidirecional como o par
# CLAUDE.md/AGENTS.md) porque copilot-instructions.md não tem conteúdo
# próprio — é sempre cópia/link de CLAUDE.md.
if (file.exists("CLAUDE.md") && file.exists(".github/copilot-instructions.md")) {
  content_claude_cp <- readLines("CLAUDE.md", warn = FALSE, encoding = "UTF-8")
  content_copilot <- readLines(".github/copilot-instructions.md", warn = FALSE, encoding = "UTF-8")
  if (!identical(content_claude_cp, content_copilot)) {
    cat_warn("Divergência detectada entre CLAUDE.md e .github/copilot-instructions.md (hard link provavelmente quebrado). Ressincronizando...")
    file.remove(".github/copilot-instructions.md")
    copilot_link_success <- FALSE
    if (.Platform$OS.type == "windows") {
      copilot_out <- suppressWarnings(tryCatch(
        system2("cmd.exe", c("/c", "mklink", "/h", ".github\\copilot-instructions.md", "CLAUDE.md"), stdout = TRUE, stderr = TRUE),
        error = function(e) character(0)
      ))
      copilot_status <- attr(copilot_out, "status")
      copilot_link_success <- (is.null(copilot_status) || copilot_status == 0) && file.exists(".github/copilot-instructions.md")
    } else {
      copilot_link_success <- tryCatch(
        {
          system("ln CLAUDE.md .github/copilot-instructions.md", intern = TRUE)
          TRUE
        },
        error = function(e) FALSE
      )
    }
    if (!copilot_link_success || !file.exists(".github/copilot-instructions.md")) {
      cat_warn("Falha ao recriar hard link de copilot-instructions.md. Fazendo fallback para cópia física...")
      file.copy("CLAUDE.md", ".github/copilot-instructions.md", overwrite = TRUE)
    }
  }
}

# ── 0c. Verificar validade da junction .agents -> .claude (informativo) ──────
# .agents é gitignorado (conveniência de ambiente local, não conteúdo
# versionado) — por isso só avisa, nunca bloqueia commit. Achado da
# auditoria de 2026-07-12: se .agents virasse um diretório comum (não-link)
# por qualquer motivo, nada detectava isso antes.
#
# Checagem por EQUIVALÊNCIA DE CONTEÚDO, não por metadado de link: testado
# ao vivo que Sys.readlink(".agents") devolve string vazia mesmo para uma
# junction NTFS genuína e funcional neste ambiente (base R não expõe essa
# informação para junctions, só para symlinks POSIX/NTFS) — checar reparse
# point exigiria uma chamada externa (fsutil/PowerShell) sem ganho real,
# já que o que importa de fato é se .agents aponta para o MESMO conteúdo de
# .claude, não o mecanismo técnico por trás.
if (dir.exists(".agents") && dir.exists(".claude")) {
  claude_listing <- sort(list.files(".claude"))
  agents_listing <- suppressWarnings(tryCatch(sort(list.files(".agents")), error = function(e) NULL))
  if (is.null(agents_listing) || !identical(claude_listing, agents_listing)) {
    cat_warn("'.agents' existe mas seu conteúdo não bate com '.claude' (junction quebrada ou virou diretório comum?). Re-execute setup.ps1/setup.sh para recriar.")
  }
}

# ── Inicialização ─────────────────────────────────────────────────────────────
errors_found <- FALSE
args <- commandArgs(trailingOnly = TRUE)
should_sync <- "--sync" %in% args

# Verificar se os caminhos fundamentais existem
if (!file.exists(PATH_PLAN_INDEX)) {
  cat_error("Índice de planos não encontrado em: ", PATH_PLAN_INDEX)
  quit(status = 1)
}
if (!file.exists(PATH_REVIEWS_INDEX)) {
  cat_error("Índice de llm-reviews não encontrado em: ", PATH_REVIEWS_INDEX)
  quit(status = 1)
}

# Carregar biblioteca yaml de forma segura
has_yaml <- requireNamespace("yaml", quietly = TRUE)
if (!has_yaml) {
  cat_warn("Pacote R 'yaml' não está instalado. Usando parser de fallback baseado em estados.")
  cat_info("Nota: Para validação YAML robusta e completa, instale o pacote 'yaml' no R (install.packages('yaml')).")
}

# Parseia um escalar single-quoted YAML a partir de uma string que começa
# com a aspa de abertura "'", respeitando o escape padrão YAML: uma aspa
# simples duplicada ('') dentro do escalar representa um apóstrofo literal.
# Sem isso, um valor como 'Plano do Autor''s Revisão' truncava
# silenciosamente no primeiro apóstrofo (bug real, achado em auditoria de
# 2026-07-12 — corrigido só aqui, no caminho `chave: valor`; os itens de
# lista de `relacionados`/`news`/`tarefas` continuam com strip simples, por
# serem tipicamente nomes de arquivo/strings curtas sem apóstrofo).
parse_yaml_single_quoted <- function(s) {
  chars <- strsplit(s, "")[[1]]
  n <- length(chars)
  out <- character(0)
  i <- 2 # pula a aspa de abertura na posição 1
  while (i <= n) {
    if (chars[i] == "'") {
      if (i < n && chars[i + 1] == "'") {
        out <- c(out, "'")
        i <- i + 2
      } else {
        return(paste(out, collapse = ""))
      }
    } else {
      out <- c(out, chars[i])
      i <- i + 1
    }
  }
  paste(out, collapse = "") # sem aspa de fechamento (malformado) — devolve o que tem
}

# Divide uma string em itens separados por vírgula, IGNORANDO vírgulas que
# estejam dentro de aspas (simples ou duplas). Sem isso,
# `relacionados: ["Plano A, revisão", "Plano B"]` quebrava o primeiro
# elemento em dois (bug real, achado em auditoria de 2026-07-12).
split_respecting_quotes <- function(s) {
  chars <- strsplit(s, "")[[1]]
  n <- length(chars)
  items <- character(0)
  buf <- character(0)
  quote_char <- NA_character_
  i <- 1
  while (i <= n) {
    ch <- chars[i]
    if (!is.na(quote_char)) {
      buf <- c(buf, ch)
      if (ch == quote_char) quote_char <- NA_character_
    } else if (ch == '"' || ch == "'") {
      quote_char <- ch
      buf <- c(buf, ch)
    } else if (ch == ",") {
      items <- c(items, paste(buf, collapse = ""))
      buf <- character(0)
    } else {
      buf <- c(buf, ch)
    }
    i <- i + 1
  }
  items <- c(items, paste(buf, collapse = ""))
  trimws(items)
}

# Helper para parsear YAML (R Base, baseado em estados)
parse_yaml_lines <- function(file_lines, full_path) {
  yaml_markers <- which(file_lines == "---")
  yaml_data <- list()
  if (length(yaml_markers) >= 2) {
    yaml_text <- file_lines[(yaml_markers[1] + 1):(yaml_markers[2] - 1)]

    in_agentes_block <- FALSE
    last_key <- NULL

    for (line in yaml_text) {
      line_clean <- trimws(line)
      if (line_clean == "") next

      # Tratar itens de lista (como "- item" ou "- conversa-123")
      if (grepl("^-\\s+", line_clean)) {
        item_val <- trimws(gsub("^-\\s*", "", line_clean))

        # Remover comentário inline se não houver aspas
        if (!grepl("^[\"']", item_val)) {
          item_val <- gsub("\\s+#.*$", "", item_val)
        }
        item_val <- gsub("^[\"']|[\"']$", "", item_val)

        if (!is.null(last_key)) {
          if (last_key == "relacionados") {
            yaml_data$relacionados <- c(yaml_data$relacionados, item_val)
          } else if (last_key == "news") {
            yaml_data$news <- c(yaml_data$news, item_val)
          } else if (last_key == "tarefas") {
            yaml_data$tarefas <- c(yaml_data$tarefas, item_val)
          }
        }
        next
      }

      # Detecção de bloco indentado de agentes
      if (grepl("^agentes:", line_clean)) {
        in_agentes_block <- TRUE
        yaml_data$agentes <- list()
        last_key <- "agentes"
        next
      }

      # Se começou outra chave não-indentada, sair do bloco de agentes
      if (in_agentes_block && grepl("^[a-zA-Z0-9_-]+:", line_clean) && !grepl("^\\s+", line)) {
        in_agentes_block <- FALSE
      }

      if (grepl(":", line_clean)) {
        parts <- strsplit(line_clean, ":")[[1]]
        key <- trimws(parts[1])
        value <- trimws(paste(parts[-1], collapse = ":"))

        # Arrays inline: chave: ["a", "b"] — split_respecting_quotes() não
        # quebra elementos que têm vírgula dentro das aspas.
        if (grepl("^\\[", value) && grepl("\\]\\s*(#.*)?$", value)) {
          inner <- sub("\\]\\s*(#.*)?$", "", sub("^\\[", "", value))
          items <- if (nchar(trimws(inner)) == 0) {
            character(0)
          } else {
            split_respecting_quotes(inner)
          }
          items <- gsub("^[\"']|[\"']$", "", items)
          if (in_agentes_block && grepl("^\\s+", line)) {
            yaml_data$agentes[[key]] <- items
          } else {
            yaml_data[[key]] <- items
            last_key <- key
          }
          next
        }

        # Limpar comentários inline de forma robusta
        # Se começar com aspas, o comentário real só pode vir após a aspa de fechamento correspondente
        if (grepl("^\"", value)) {
          val_match <- regexpr("^\"([^\"]*)\"", value)
          if (val_match > 0) {
            value <- regmatches(value, val_match)
          }
        } else if (grepl("^'", value)) {
          # parse_yaml_single_quoted() já devolve o valor sem aspas e com
          # '' colapsado a um apóstrofo literal; rewrap com uma aspa em
          # cada ponta para o strip genérico logo abaixo funcionar igual
          # ao caminho de aspas duplas, sem duplicar lógica.
          value <- paste0("'", parse_yaml_single_quoted(value), "'")
        } else {
          # Sem aspas, remover comentários cortando a partir de espaço + #
          value <- gsub("\\s+#.*$", "", value)
        }

        # Remover aspas externas se existirem
        value <- gsub("^[\"']|[\"']$", "", value)

        if (in_agentes_block && grepl("^\\s+", line)) {
          yaml_data$agentes[[key]] <- value
        } else {
          yaml_data[[key]] <- value
          last_key <- key
        }
      }
    }
  }
  return(yaml_data)
}

# Wrapper para parser unificado. Extrai APENAS o frontmatter (entre os dois
# primeiros marcadores ---) e o entrega ao pacote yaml; read_yaml no arquivo
# inteiro sempre falharia no corpo markdown, o que mandava TODOS os arquivos
# para o parser de fallback silenciosamente.
parse_yaml_file <- function(full_path) {
  file_lines <- readLines(full_path, encoding = "UTF-8", warn = FALSE)
  if (has_yaml) {
    yaml_markers <- which(file_lines == "---")
    if (length(yaml_markers) >= 2 && yaml_markers[1] == 1) {
      yaml_text <- paste(file_lines[(yaml_markers[1] + 1):(yaml_markers[2] - 1)], collapse = "\n")
      yaml_data <- tryCatch(
        {
          yaml::yaml.load(yaml_text)
        },
        error = function(e) {
          parse_yaml_lines(file_lines, full_path)
        }
      )
      return(yaml_data)
    }
    return(list())
  }
  parse_yaml_lines(file_lines, full_path)
}

# local helper equivalent to python %||% or R rlang::`%||%`
`%||%` <- function(a, b) if (!is.null(a)) a else b

# Trata NULL, "null" (parser de fallback) e string vazia como ausência de valor
nz <- function(x) {
  if (is.null(x) || length(x) == 0) {
    return(NULL)
  }
  if (is.character(x) && (identical(trimws(x[1]), "null") || identical(trimws(x[1]), ""))) {
    return(NULL)
  }
  x
}

# ── Convenções compartilhadas entre os modos ──────────────────────────────────
# Frontmatter YAML passou a ser obrigatório em planos NOVOS em 2026-07-09
# (decisão do autor; ver 9-vers/plan/README.md § Convenção de cabeçalho).
# Planos anteriores mantêm o cabeçalho em blockquote e são isentos das
# checagens modernas (nomenclatura, YAML, log de conversa).
YAML_CONVENTION_DATE <- "2026-07-09"

STATUS_KEYWORDS <- c("EM EXECUÇÃO", "CONCLUÍDO", "SUPERADO", "HISTÓRICO", "PARCIAL", "ATIVO")

# Normaliza uma célula de status do índice extraindo a palavra-chave inicial.
# Robusto a negrito e a anotações com parênteses aninhados:
# "**CONCLUÍDO** (2026-07-12; ver NEWS 2026-07-11 (2))" -> "CONCLUÍDO"
normalize_status <- function(x) {
  x <- trimws(gsub("\\*", "", x))
  for (kw in STATUS_KEYWORDS) {
    if (startsWith(x, kw)) {
      return(kw)
    }
  }
  x
}

# Data YYYY-MM-DD no prefixo do nome do arquivo, ou NA se não houver
filename_date <- function(fname) {
  m <- regexpr("^[0-9]{4}-[0-9]{2}-[0-9]{2}", fname)
  if (m > 0) regmatches(fname, m) else NA_character_
}

# ── MODO SYNC: Atualização Conservadora do Índice ─────────────────────────────
# O índice é uma tabela CURADA À MÃO. O --sync nunca inventa status (sem YAML,
# nada muda), nunca remove linhas e preserva as anotações manuais: uma linha só
# é reescrita quando o arquivo tem frontmatter YAML E o status normalizado do
# YAML diverge do status da linha. Arquivos novos com YAML entram no topo.
if (should_sync) {
  cat_info("Modo --sync ativado. Varrendo planos para atualizar o índice...")

  index_lines <- readLines(PATH_PLAN_INDEX, encoding = "UTF-8", warn = FALSE)

  if (any(grepl("^<<<<<<<", index_lines))) {
    cat_error("Conflitos de merge NÃO RESOLVIDOS detectados em plan/README.md. Sincronização cancelada.")
    quit(status = 1)
  }

  start_tag <- which(grepl("<!-- BEGIN_PLAN_INDEX -->", index_lines))
  end_tag <- which(grepl("<!-- END_PLAN_INDEX -->", index_lines))
  if (!(length(start_tag) == 1 && length(end_tag) == 1 && start_tag < end_tag)) {
    cat_error("Delimitadores <!-- BEGIN_PLAN_INDEX --> e <!-- END_PLAN_INDEX --> não encontrados em plan/README.md.")
    cat_info("Cancelando sincronização para evitar perda de dados manuais no README.")
    quit(status = 1)
  }

  # 1. Carregar metadados YAML dos arquivos de plano no disco
  plan_files <- list.files(PATH_PLAN_DIR, pattern = "^[0-9]{4}-[0-9]{2}-[0-9]{2}_.*\\.md$")
  plan_meta <- list()
  for (pf in plan_files) {
    meta <- parse_yaml_file(file.path(PATH_PLAN_DIR, pf))
    if (!is.null(nz(meta$status))) plan_meta[[pf]] <- meta
  }

  # Monta a célula de status a partir do YAML (negrito nos planos vivos,
  # data de conclusão quando disponível)
  build_status_cell <- function(meta) {
    status <- trimws(meta$status)
    if (status %in% c("ATIVO", "EM EXECUÇÃO")) {
      return(sprintf("**%s**", status))
    }
    concluido <- nz(meta$concluido)
    if (status == "CONCLUÍDO" && !is.null(concluido)) {
      return(sprintf("CONCLUÍDO (%s)", format(concluido)))
    }
    status
  }

  build_executor_cell <- function(meta, fallback) {
    nz(meta$agentes$executor) %||% nz(meta$agentes$orquestrador) %||%
      nz(meta$orquestrador) %||% fallback %||% "—"
  }

  # 2. Reprocessar a região entre as tags, linha a linha, preservando a ordem
  region <- if (end_tag - start_tag > 1) index_lines[(start_tag + 1):(end_tag - 1)] else character(0)
  seen_files <- character(0)
  out_rows <- character(0)
  n_updated <- 0

  for (line in region) {
    is_header <- grepl("^\\|\\s*Plano\\s*\\|", line)
    is_separator <- grepl("^\\|[\\s:|-]+\\|\\s*$", line, perl = TRUE)
    if (is_header || is_separator) next # cabeçalho é reescrito programaticamente

    if (!grepl("^\\|", line)) {
      out_rows <- c(out_rows, line) # linha não-tabular: preservar verbatim
      next
    }

    parts <- strsplit(line, "\\s*\\|\\s*")[[1]]
    fname <- if (length(parts) >= 2) trimws(sub("\\s*\\(.*$", "", gsub("`", "", parts[[2]]))) else ""
    meta <- if (nchar(fname) > 0) plan_meta[[fname]] else NULL

    if (is.null(meta)) {
      out_rows <- c(out_rows, line) # sem YAML (legado) ou fora da varredura: preservar verbatim
      next
    }

    seen_files <- c(seen_files, fname)
    yaml_status <- trimws(meta$status)
    index_status_cell <- if (length(parts) >= 3) parts[[3]] else ""

    if (normalize_status(index_status_cell) == yaml_status) {
      out_rows <- c(out_rows, line) # já em sincronia: preservar anotações manuais
    } else {
      desc <- if (length(parts) >= 5 && nchar(trimws(parts[[5]])) > 0) {
        trimws(parts[[5]])
      } else {
        (nz(meta$titulo) %||% nz(meta$title) %||% "—")
      }
      executor <- build_executor_cell(meta, if (length(parts) >= 4) nz(trimws(parts[[4]])) else NULL)
      out_rows <- c(out_rows, sprintf("| %s | %s | %s | %s |", parts[[2]], build_status_cell(meta), executor, desc))
      n_updated <- n_updated + 1
      cat_info(sprintf("Linha atualizada a partir do YAML: '%s' -> %s", fname, yaml_status))
    }
  }

  # 3. Arquivos novos com YAML que ainda não estão no índice entram no topo
  new_files <- sort(setdiff(names(plan_meta), seen_files), decreasing = TRUE)
  new_rows <- character(0)
  for (pf in new_files) {
    meta <- plan_meta[[pf]]
    desc <- nz(meta$titulo) %||% nz(meta$title) %||% "—"
    new_rows <- c(new_rows, sprintf("| `%s` | %s | %s | %s |", pf, build_status_cell(meta), build_executor_cell(meta, NULL), desc))
    cat_info(sprintf("Plano novo adicionado ao índice: '%s'", pf))
  }

  new_index_content <- c(
    index_lines[1:start_tag],
    "| Plano | Status | Executor | O que é |",
    "|---|---|---|---|",
    new_rows,
    out_rows,
    index_lines[end_tag:length(index_lines)]
  )
  writeLines(new_index_content, PATH_PLAN_INDEX, useBytes = TRUE)
  cat_success(sprintf(
    "Índice plan/README.md sincronizado: %d linha(s) atualizada(s), %d plano(s) novo(s), demais preservadas.",
    n_updated, length(new_rows)
  ))
  quit(status = 0)
}

# ── T0. Helpers de Git para os Guardas de Commit (T1-T4) ──────────────────────
# Todas as chamadas usam system2() com vetor de argumentos (nunca system()/
# shell() com string concatenada) para que nomes de arquivo com espaço/acento
# cheguem ao git corretamente, independente de quoting de shell.
GIT_BASE_ARGS <- c("-c", "core.quotepath=false")

git_capture <- function(args) {
  result <- suppressWarnings(tryCatch(
    system2("git", c(GIT_BASE_ARGS, args), stdout = TRUE, stderr = TRUE),
    error = function(e) character(0)
  ))
  status <- attr(result, "status")
  if (!is.null(status) && status != 0) {
    cat_warn(sprintf(
      "git %s retornou status %s: %s",
      paste(args, collapse = " "), status, paste(result, collapse = " | ")
    ))
    return(character(0))
  }
  Encoding(result) <- "UTF-8"
  result
}

# Arquivos staged para ESTE commit (Added/Copied/Modified/Renamed; Deleted não faz
# sentido escanear).
staged_files <- git_capture(c("diff", "--cached", "--name-only", "--diff-filter=ACMR"))
staged_files <- staged_files[nzchar(staged_files)]

# Mapa novo-caminho -> caminho-antigo para arquivos renomeados neste commit.
# Necessário porque `git diff --cached -- <novo-caminho>` SOZINHO não
# consegue parear o rename (o pathspec restringe a visão do git ao lado
# "novo" antes da lógica de detecção de rename rodar), e sem o pareamento o
# diff mostra o arquivo INTEIRO como adicionado — o que reintroduziria o
# mesmo lockout retroativo que o escopo "só linhas adicionadas" existe para
# evitar (confirmado empiricamente: um arquivo de 4-DA-Code/ renomeado com
# uma única linha nova aparecia com suas ~50-2000 linhas pré-existentes
# todas como "adicionadas"). Usar --name-status -M (não -z) é seguro aqui
# porque core.quotepath=false já garante nomes UTF-8 sem escaping octal.
rename_map <- local({
  ns <- git_capture(c("diff", "--cached", "--name-status", "-M", "--diff-filter=R"))
  ns <- ns[nzchar(ns)]
  if (length(ns) == 0) {
    return(list())
  }
  m <- list()
  for (line in ns) {
    parts <- strsplit(line, "\t")[[1]]
    if (length(parts) >= 3) m[[parts[3]]] <- parts[2] # m[[novo]] <- antigo
  }
  m
})

# Tamanho do BLOB staged (não do arquivo em disco): reflete corretamente um
# `git add -p` parcial. ls-files -> sha -> cat-file -s em vez do atalho
# ":caminho" porque ":" inicia "magic pathspec" no git.
get_staged_blob_size <- function(filepath) {
  ls_out <- git_capture(c("ls-files", "-s", "--", filepath))
  if (length(ls_out) == 0) {
    return(NA_real_)
  }
  sha <- sub("^\\S+\\s+(\\S+)\\s+\\S+\\t.*$", "\\1", ls_out[1])
  if (!grepl("^[0-9a-f]{40}$|^[0-9a-f]{64}$", sha)) {
    return(NA_real_)
  }
  size_out <- git_capture(c("cat-file", "-s", sha))
  if (length(size_out) == 0) {
    return(NA_real_)
  }
  suppressWarnings(as.numeric(size_out[1]))
}

# Linhas efetivamente ADICIONADAS pelo diff staged (sem prefixo "+", sem
# contexto -U0). Por construção, git diff -U0 nunca devolve linhas
# inalteradas/pré-existentes — checagens de conteúdo baseadas nesta função
# não podem travar retroativamente por causa de algo que já estava no
# arquivo antes deste commit.
get_staged_added_lines <- function(filepath) {
  old_path <- rename_map[[filepath]]
  if (!is.null(old_path)) {
    # Passar os DOIS caminhos (antigo + novo) com -M é o que permite ao git
    # parear o rename e devolver só a diferença real — testado empiricamente
    # contra a alternativa de um só caminho (mostra o arquivo inteiro).
    diff_out <- git_capture(c("diff", "--cached", "-M", "--no-color", "-U0", "--", old_path, filepath))
  } else {
    diff_out <- git_capture(c("diff", "--cached", "--no-color", "-U0", "--", filepath))
  }
  if (length(diff_out) == 0) {
    return(character(0))
  }
  # useBytes = TRUE: arquivos grandes com conteúdo exótico (ex.: os próprios
  # exports de conversa em 9-vers/llm-reviews/, que embutem JSON com
  # sequências de escape longas) fazem o grepl padrão (baseado em locale)
  # lançar "unable to translate to a wide string" / "input string is
  # invalid" — achado ao vivo commitando este mesmo arquivo. Os padrões
  # aqui são sempre ASCII puro, então casar por byte é equivalente e evita
  # por completo a detecção/tradução de encoding que estava falhando.
  added <- diff_out[grepl("^\\+", diff_out, useBytes = TRUE) &
    !grepl("^\\+\\+\\+", diff_out, useBytes = TRUE)]
  sub("^\\+", "", added, useBytes = TRUE)
}

# ── T2. Bloqueio de Arquivos Staged Grandes (> 10 MB) ─────────────────────────
# Protege contra upload acidental de dados brutos/scraping não anonimizados
# para o histórico do Git (o repo já tem tools/git-purgar-dados-historico.ps1
# — sinal de que esse problema já aconteceu aqui antes).
MAX_STAGED_BYTES <- 10485760 # 10 * 1024 * 1024

if (length(staged_files) > 0) {
  cat_info(sprintf(
    "Verificando tamanho de %d arquivo(s) staged (limite: %d bytes)...",
    length(staged_files), MAX_STAGED_BYTES
  ))
  for (f in staged_files) {
    blob_size <- get_staged_blob_size(f)
    if (is.na(blob_size)) {
      cat_warn(sprintf("Não foi possível determinar o tamanho staged de '%s'. Pulando.", f))
      next
    }
    if (blob_size > MAX_STAGED_BYTES) {
      cat_error(sprintf(
        "Arquivo staged '%s' excede o limite de %d bytes (tamanho: %d bytes / %.2f MB).",
        f, MAX_STAGED_BYTES, blob_size, blob_size / 1048576
      ))
      errors_found <- TRUE
    }
  }
}

# ── T6. Bloqueio de Marcadores de Conflito de Merge Staged ────────────────────
# Achado testando casos-limite não cobertos (2026-07-13): um arquivo staged
# com marcadores de conflito (`<<<<<<<`/`=======`/`>>>>>>>`) não resolvidos
# passava batido por T1/T2/T4 — nenhuma checagem existente olhava para isso
# fora do caso bem específico já coberto na seção 0 (só CLAUDE.md/AGENTS.md).
# Escopo "só linhas adicionadas", igual T1/T4: nenhum arquivo do repo tem
# esse padrão hoje (confirmado por `git grep`), então não há risco de
# lockout retroativo, mas mantém a mesma disciplina de design do resto do
# script. Aplica a TODOS os arquivos staged (não só .R/.qmd): marcador de
# conflito é um problema em qualquer arquivo de texto, inclusive .md.
#
# Exceção auto-referencial (mesmo padrão do T1 com "MancanoSync/"): os
# exports de conversa em 9-vers/llm-reviews/ são transcrição verbatim de
# sessões de agente — qualquer teste feito ali DENTRO da própria sessão
# (ex.: testar esta mesma regex contra ">>>>>>> outra-branch") fica
# registrado literalmente no log e dispararia T6 sem ser um conflito de
# verdade. Achado ao vivo commitando o export desta sessão.
CONFLICT_MARKER_REGEX <- r"{^(<{7}|>{7}|={7}$)}"
t6_files <- staged_files[!grepl("^9-vers/llm-reviews/", staged_files)]

if (length(t6_files) > 0) {
  cat_info(sprintf(
    "Verificando marcadores de conflito de merge em %d arquivo(s) staged (linhas adicionadas)...",
    length(t6_files)
  ))
  for (f in t6_files) {
    added_lines <- get_staged_added_lines(f)
    if (length(added_lines) == 0) next
    hits <- grepl(CONFLICT_MARKER_REGEX, added_lines, useBytes = TRUE)
    if (any(hits)) {
      offenders <- trimws(added_lines[hits])
      for (o in head(offenders, 5)) {
        cat_error(sprintf("Marcador de conflito de merge não resolvido em '%s': %s", f, o))
      }
      errors_found <- TRUE
    }
  }
}

# ── T1. Caminhos Absolutos Locais em .R/.qmd Staged ────────────────────────────
# Escopo: só linhas ADICIONADAS pelo diff staged (não o arquivo inteiro).
# Escanear o arquivo inteiro bloquearia retroativamente ~161 arquivos hoje
# trackeados (a maioria scripts em 4-DA-Code/ com setwd()/read.csv() de
# caminho absoluto, prática normal de workflow de um único pesquisador) e,
# especificamente, capítulos com "bibliography: C:/Users/.../Zotero-....bib"
# pré-existente no frontmatter — um lockout permanente e real, não hipotético.
ABS_PATH_REGEX <- r"{([A-Za-z]:[\\/]Users[\\/]|[\\/][Hh]ome[\\/]|[\\/][Uu]sers[\\/])[A-Za-z0-9_-]+}"
# file:///c:/Users/... (o formato de link Markdown que vazou 22 arquivos na
# auditoria de 2026-07-12) já cai no mesmo padrão acima ("c:/Users/" é
# substring da URI), então nenhuma regex adicional é necessária para cobrir
# esse caso — reaproveitado tal e qual pelo T5 abaixo.

# Helper compartilhado por T1 e T5: varre linhas adicionadas de um conjunto
# de arquivos staged em busca de caminho absoluto local, reportando até 5
# ocorrências por arquivo.
check_abs_path_in_added_lines <- function(files, label) {
  found_any <- FALSE
  for (f in files) {
    added_lines <- get_staged_added_lines(f)
    if (length(added_lines) == 0) next
    hits <- grepl(ABS_PATH_REGEX, added_lines, useBytes = TRUE) |
      grepl("MancanoSync/", added_lines, fixed = TRUE, useBytes = TRUE)
    if (any(hits)) {
      offenders <- trimws(added_lines[hits])
      for (o in head(offenders, 5)) {
        cat_error(sprintf("Caminho absoluto local introduzido em '%s': %s", f, o))
      }
      if (length(offenders) > 5) {
        cat_error(sprintf("... e mais %d linha(s) com o mesmo problema em '%s'.", length(offenders) - 5, f))
      }
      found_any <- TRUE
    }
  }
  found_any
}

# Exceção auto-referencial: tools/validate-governance.R contém, no próprio
# código-fonte, a string literal "MancanoSync/" (o termo que esta mesma
# checagem procura) e comentários citando "C:/Users/..." como exemplo — sem
# essa exceção, QUALQUER edição futura a este bloco se autodenunciaria como
# violação (confirmado ao vivo: aconteceu na primeira tentativa de commit
# desta implementação). Confirmado por grep que o arquivo não contém nenhum
# caminho absoluto real fora desses dois casos.
rq_files <- staged_files[grepl("\\.(R|qmd)$", staged_files, ignore.case = TRUE) &
  staged_files != "tools/validate-governance.R"]

if (length(rq_files) > 0) {
  cat_info(sprintf(
    "Verificando caminhos absolutos locais em %d arquivo(s) .R/.qmd staged (linhas adicionadas)...",
    length(rq_files)
  ))
  if (check_abs_path_in_added_lines(rq_files, "T1")) errors_found <- TRUE
}

# ── T5. Caminhos Absolutos Locais nos Documentos de Governança Ativos ─────────
# Fecha a lacuna encontrada na auditoria de 2026-07-12
# (2026-07-12_Avaliacao_Auditoria_Governanca_Blackbox.md): 22 arquivos
# vazavam "file:///c:/Users/Mancano/..." — o escopo do T1 (só .R/.qmd) nunca
# cobriria isso, porque o vazamento estava na PROSA de governança, não em
# código/capítulo. Lista curada (não glob) — deliberadamente não inclui
# `9-vers/llm-reviews/*.md` nem planos já CONCLUÍDO/HISTÓRICO (valor
# documental de sessão passada, não devem ser reescritos) nem entradas
# antigas do NEWS.md (CLAUDE.md § "Guidance Documents": "never rewrite NEWS
# entries" — mas o escopo "só linhas adicionadas" já protege isso por
# construção: uma entrada nova em NEWS.md que introduza um caminho absoluto
# É pega; entradas antigas nunca são escaneadas de novo).
GOVERNANCE_DOCS <- c(
  "CLAUDE.md", "AGENTS.md", "README.md", "GUIDANCE.md",
  "NEWS.md", "9-vers/GUIDANCE_MAP.md",
  "9-vers/plan/README.md", "9-vers/llm-reviews/README.md"
)
gov_files <- staged_files[staged_files %in% GOVERNANCE_DOCS]

if (length(gov_files) > 0) {
  cat_info(sprintf(
    "Verificando caminhos absolutos locais em %d documento(s) de governança staged (linhas adicionadas)...",
    length(gov_files)
  ))
  if (check_abs_path_in_added_lines(gov_files, "T5")) errors_found <- TRUE
}

# ── T4. Integridade de Citações vs. Biblioteca Zotero (.bib) ──────────────────
# Fonte do caminho do .bib: lida de _quarto.yml (campo "bibliography:"), não
# hardcodada de novo aqui — o nome do arquivo carrega a data do último export
# Zotero e é reexportado periodicamente; hardcodar de novo faria esta
# checagem degradar em silêncio na próxima reexportação.
PATH_QUARTO_YML <- file.path(CWD, "_quarto.yml")
resolve_bib_path <- function() {
  if (!file.exists(PATH_QUARTO_YML)) {
    return(NA_character_)
  }
  qy_lines <- readLines(PATH_QUARTO_YML, encoding = "UTF-8", warn = FALSE)
  bib_line <- grep("^bibliography:\\s*", qy_lines, value = TRUE)
  if (length(bib_line) == 0) {
    return(NA_character_)
  }
  bib_rel <- gsub("^[\"']|[\"']$", "", trimws(sub("^bibliography:\\s*", "", bib_line[1])))
  if (nchar(bib_rel) == 0) {
    return(NA_character_)
  }
  file.path(CWD, bib_rel)
}
PATH_BIB <- resolve_bib_path()

QUARTO_XREF_PREFIXES <- c("sec-", "fig-", "tbl-")

# Fronteira de citação Pandoc: "@" só conta como citação quando NÃO é
# precedido por barra invertida (macro LaTeX crua, ex.: \@title), chave de
# abertura "{" (ex.: \@ifundefined{@subtitle}) ou letra/dígito/underscore.
# Requer os DOIS backslashes na classe de caracteres: um só é consumido como
# escape do "{" seguinte e a exclusão de "\@title" etc. não funciona.
CITATION_REGEX <- r"{(?<![\\{A-Za-z0-9_])@([A-Za-z0-9_:.#$%&+?<>~/-]+)}"

if (is.na(PATH_BIB) || !file.exists(PATH_BIB)) {
  cat_info("Nenhum arquivo de bibliografia configurado ou encontrado. Checagem T4 pulada.")
} else {
  bib_lines <- readLines(PATH_BIB, encoding = "UTF-8", warn = FALSE)
  key_matches <- regmatches(bib_lines, regexec("^@[A-Za-z]+\\{([^,]+),", bib_lines))
  valid_bib_keys <- unique(vapply(key_matches, function(m) if (length(m) >= 2) m[2] else NA_character_, character(1)))
  valid_bib_keys <- valid_bib_keys[!is.na(valid_bib_keys)]
  cat_info(sprintf("Carregadas %d chaves de citação de '%s'.", length(valid_bib_keys), basename(PATH_BIB)))

  # Chaves reais do .bib contêm "." e ":" (ex.: "BontempiJr.-Boto2014",
  # "Chalhoub03:00:00+00:00"), então a classe de caracteres da chave não pode
  # excluir esses caracteres — mas isso faz a regex engolir pontuação de
  # fronteira de prosa (ponto final de frase, dois-pontos de locator). Se a
  # chave inteira não bate, apara "." / ":" à direita e tenta de novo.
  resolve_key <- function(candidate) {
    trial <- candidate
    repeat {
      if (trial %in% valid_bib_keys) {
        return(TRUE)
      }
      if (nchar(trial) == 0 || !grepl("[.:]$", trial)) {
        return(FALSE)
      }
      trial <- substr(trial, 1, nchar(trial) - 1)
    }
  }

  # Escopo: só .qmd, não .R. Comentários roxygen2 (#' @param, @export) usam a
  # mesma sintaxe "@palavra" em posição de fronteira de citação e gerariam
  # falso-positivo garantido (não há roxygen no repo hoje, mas é risco
  # latente dado o pacote educabr2 referenciado em _quarto.yml).
  citation_files <- staged_files[grepl("\\.qmd$", staged_files, ignore.case = TRUE)]

  if (length(citation_files) > 0) {
    cat_info(sprintf(
      "Verificando integridade de citações em %d arquivo(s) .qmd staged (linhas adicionadas)...",
      length(citation_files)
    ))
    for (f in citation_files) {
      added_lines <- get_staged_added_lines(f)
      if (length(added_lines) == 0) next

      bad_keys_in_file <- character(0)
      in_chunk <- FALSE
      for (line in added_lines) {
        # Pandoc NUNCA processa citações dentro de um bloco de código
        # cercado (``` ... ```, com ou sem {r}/{python}), então o conteúdo
        # de um chunk não deveria ser escaneado por T4 em absoluto — achado
        # real de auditoria (2026-07-13): `email <- c("a", "@boto2014")`,
        # uma linha comum de código R sem nada de roxygen, era capturada
        # como candidata a citação e bloquearia o commit se "boto2014" não
        # existisse no .bib. A guarda anterior (só pular linhas "#'") não
        # protegia contra isso.
        #
        # Rastreamos abertura/fechamento de cerca dentro das PRÓPRIAS
        # linhas adicionadas. Correto por construção quando um chunk novo é
        # adicionado por inteiro (caso comum). Limitação aceita e
        # documentada: se uma linha nova for inserida no MEIO de um chunk
        # já existente e não tocado, a linha de abertura da cerca não
        # aparece no diff (`-U0` só mostra linhas mudadas), então esse caso
        # residual não é pego por este rastreamento — a checagem de "#'"
        # abaixo continua como segunda camada, mas não cobre tudo. Rastrear
        # isso com 100% de precisão exigiria ler o arquivo staged inteiro e
        # cruzar com números de linha do hunk, o que não se justifica dado
        # o padrão da suite (todas as travas já aceitam alguma imprecisão
        # equivalente em favor de simplicidade).
        if (grepl("^\\s*```", line)) {
          in_chunk <- !in_chunk
          next
        }
        if (in_chunk) next
        if (grepl("^\\s*#'", line)) next
        found <- regmatches(line, gregexpr(CITATION_REGEX, line, perl = TRUE, useBytes = TRUE))[[1]]
        if (length(found) == 0) next
        keys <- sub("^@", "", found)
        keys <- keys[!grepl(paste0("^(", paste(QUARTO_XREF_PREFIXES, collapse = "|"), ")"), keys)]
        if (length(keys) == 0) next
        unresolved <- keys[!vapply(keys, resolve_key, logical(1))]
        # Ignorar chaves não resolvidas que sejam puramente numéricas ou decimais (evita falsos-positivos de comentários)
        unresolved <- unresolved[!grepl("^[0-9.]+$", unresolved)]
        bad_keys_in_file <- c(bad_keys_in_file, unresolved)
      }

      bad_keys_in_file <- unique(bad_keys_in_file)
      if (length(bad_keys_in_file) > 0) {
        cat_error(sprintf(
          "Citação(ões) sem entrada em '%s' no arquivo '%s': %s",
          basename(PATH_BIB), f, paste(bad_keys_in_file, collapse = ", ")
        ))
        errors_found <- TRUE
      }
    }
  }
}

# ── T3. Verificação de Formatação de .R Staged com {styler} ───────────────────
# Modo conservador (dry-run + aviso): NÃO escreve nem re-adiciona
# automaticamente. Scripts .R aqui são análise de dados versionada por
# timestamp no nome do arquivo, editados lado a lado com prosa de capítulos;
# misturar reformatação automática com edição de conteúdo no mesmo commit
# degrada git blame/bisect (README §8.4). Para trocar para o modo automático
# (auto-estiliza + re-adiciona silenciosamente), troque AUTO_STYLE_FIX para
# TRUE.
AUTO_STYLE_FIX <- FALSE

has_styler <- requireNamespace("styler", quietly = TRUE)
if (!has_styler) {
  cat_warn("Pacote R 'styler' não está instalado. Checagem de formatação (T3) pulada.")
  cat_info("Para habilitar, instale com install.packages('styler').")
} else {
  # Só .R puro — styler não tokeniza .qmd (prosa + chunks) de forma segura o
  # bastante para reescrever no lugar; escopo intencionalmente restrito.
  style_targets <- staged_files[grepl("\\.R$", staged_files, ignore.case = TRUE)]

  if (length(style_targets) > 0) {
    cat_info(sprintf("Verificando formatação de %d arquivo(s) .R staged com styler...", length(style_targets)))
    needs_style <- character(0)

    for (f in style_targets) {
      full_path <- file.path(CWD, f)
      if (!file.exists(full_path)) next

      # style_file() devolve (de forma invisível) um data.frame com a coluna
      # lógica `changed` — inclusive em dry="on", onde NADA é escrito em
      # disco. Comparar hash antes/depois NÃO funciona para detectar
      # "precisaria mudar" no modo dry: como o arquivo nunca é escrito, o
      # hash é sempre idêntico e o aviso nunca dispararia (bug encontrado e
      # corrigido durante os testes desta implementação).
      dry_mode <- if (AUTO_STYLE_FIX) "off" else "on"
      style_result <- tryCatch(
        {
          styler::style_file(full_path, dry = dry_mode)
        },
        error = function(e) {
          cat_warn(sprintf("styler falhou em '%s': %s", f, conditionMessage(e)))
          NULL
        }
      )
      if (is.null(style_result)) next

      changed <- isTRUE(style_result$changed[1])

      if (AUTO_STYLE_FIX) {
        if (changed) {
          git_capture(c("add", "--", f))
          cat_success(sprintf("Arquivo '%s' reformatado por styler e re-adicionado ao stage.", f))
        }
      } else if (changed) {
        needs_style <- c(needs_style, f)
      }
    }

    if (!AUTO_STYLE_FIX && length(needs_style) > 0) {
      cat_warn(sprintf("%d arquivo(s) .R staged não seguem o estilo do {styler}:", length(needs_style)))
      for (f in needs_style) cat_warn(sprintf("  - %s", f))
      cat_info("Rode styler::style_file() manualmente e refaça o `git add` (recomendado: commit de estilo isolado).")
      # Aviso, não bloqueio: NÃO seta errors_found <- TRUE.
    }
  }
}

# ── MODO VALIDATE: Execução Normal do QA ──────────────────────────────────────
plan_index_lines <- readLines(PATH_PLAN_INDEX, encoding = "UTF-8", warn = FALSE)

# Verificar se há conflitos de merge ativos no README de planos
if (any(grepl("^<<<<<<<", plan_index_lines))) {
  cat_error("Conflitos de merge NÃO RESOLVIDOS detectados em plan/README.md.")
  cat_info("Por favor, resolva os conflitos no arquivo, apague os marcadores e comite novamente.")
  quit(status = 1) # Bloqueia o commit para segurança do histórico
}

# Localizar linhas da tabela markdown do índice (apenas na seção Índice)
in_indice_section <- FALSE
table_lines <- c()
for (line in plan_index_lines) {
  if (grepl("^## Índice", line)) {
    in_indice_section <- TRUE
    next
  }
  if (in_indice_section && grepl("^## ", line)) {
    in_indice_section <- FALSE
  }
  if (in_indice_section && grepl("^\\|\\s*`[^`]+`\\s*\\|", line)) {
    table_lines <- c(table_lines, line)
  }
}

if (length(table_lines) == 0) {
  cat_error("Nenhuma linha de tabela de planos ativa localizada no índice.")
  errors_found <- TRUE
}

# Estruturar os dados do índice
indexed_plans <- list()
for (line in table_lines) {
  parts <- strsplit(line, "\\s*\\|\\s*")[[1]]
  if (length(parts) >= 3) {
    file_raw <- trimws(parts[[2]])
    filename <- gsub("`", "", file_raw)

    # Remover observações em parênteses do nome do arquivo
    filename <- trimws(gsub("\\s*\\([^)]+\\)", "", filename))
    status_raw <- trimws(parts[[3]])

    # Ignorar outlines explicativos
    if (filename %in% c("ATIVO", "EM EXECUÇÃO", "PARCIAL", "CONCLUÍDO", "SUPERADO", "HISTÓRICO")) {
      next
    }

    indexed_plans[[filename]] <- status_raw
  }
}

cat_info(sprintf("Localizados %d planos indexados no %s.", length(indexed_plans), basename(PATH_PLAN_INDEX)))

# ── 2. Carregar e Parsear o Índice de llm-reviews (README.md) ─────────────────
reviews_index_lines <- readLines(PATH_REVIEWS_INDEX, encoding = "UTF-8", warn = FALSE)
reviews_table_lines <- grep("^\\|\\s*`[^`]+`\\s*\\|", reviews_index_lines, value = TRUE)
indexed_reviews <- c()
for (line in reviews_table_lines) {
  parts <- strsplit(line, "\\s*\\|\\s*")[[1]]
  if (length(parts) >= 2) {
    rev_file <- gsub("`", "", trimws(parts[[2]]))
    indexed_reviews <- c(indexed_reviews, rev_file)
  }
}

cat_info(sprintf("Localizados %d logs de conversas registrados no %s.", length(indexed_reviews), basename(PATH_REVIEWS_INDEX)))

# ── 3. Auditar cada arquivo listado no Índice ──────────────────────────────────
valid_types <- c("Plano", "Prompt", "Proposta", "Checklist", "Avaliacao", "Relatorio", "Walkthrough")

for (plan_file in names(indexed_plans)) {
  # Verificar existência física
  if (grepl("^3-texts/", plan_file)) {
    full_path <- file.path(CWD, plan_file)
  } else {
    full_path <- file.path(PATH_PLAN_DIR, plan_file)
  }

  if (!file.exists(full_path)) {
    cat_error(sprintf("Arquivo indexado não existe fisicamente: '%s' (caminho tentado: %s)", plan_file, full_path))
    errors_found <- TRUE
    next
  }

  # Legado: isento das checagens modernas. São legados os planos anteriores à
  # convenção de frontmatter YAML (data no nome < 2026-07-09), os marcados
  # HISTÓRICO no índice (curadoria manual) e os sem data no nome já indexados
  # como documentação (MA-TMancano.qmd etc., capturados pelo status HISTÓRICO).
  file_date <- filename_date(plan_file)
  index_status_norm <- normalize_status(indexed_plans[[plan_file]])
  is_legacy <- plan_file == "README.md" ||
    index_status_norm == "HISTÓRICO" ||
    (!is.na(file_date) && file_date < YAML_CONVENTION_DATE)

  if (!is_legacy && !grepl("^3-texts/", plan_file)) {
    # 3.1. Validar padrão de nome de arquivo
    filename_regex <- "^([0-9]{4}-[0-9]{2}-[0-9]{2})_([A-Za-z0-9]+)_(.+)\\.(md|qmd)$"
    matches <- regexec(filename_regex, plan_file)
    match_parts <- regmatches(plan_file, matches)[[1]]

    if (length(match_parts) == 0) {
      cat_error(sprintf("Nome do arquivo fora do padrão de nomenclatura: '%s'", plan_file))
      errors_found <- TRUE
    } else {
      plan_type <- match_parts[3]
      if (!(plan_type %in% valid_types)) {
        cat_error(sprintf(
          "Tipo de plano inválido no nome do arquivo '%s': '%s' (Esperado: %s)",
          plan_file, plan_type, paste(valid_types, collapse = ", ")
        ))
        errors_found <- TRUE
      }
    }
  }

  # 3.2. Validar cabeçalho YAML e sincronia de status
  yaml_data <- parse_yaml_file(full_path)

  # Se o arquivo tem cabeçalho YAML, validar sincronia de status
  if (!is.null(yaml_data$status)) {
    yaml_status <- trimws(yaml_data$status)
    index_status <- indexed_plans[[plan_file]]

    # Normalizar o status do índice: extrai a palavra-chave inicial (robusto a
    # negrito e a anotações com parênteses aninhados)
    norm_index_status <- normalize_status(index_status)

    if (yaml_status != norm_index_status) {
      cat_error(sprintf(
        "Divergência de status no plano '%s': YAML diz '%s' e README.md diz '%s'",
        plan_file, yaml_status, index_status
      ))
      errors_found <- TRUE
    }

    # 3.3. Verificar registro do log de conversa para planos CONCLUÍDOS
    # (só para planos pós-convenção; a exportação retroativa de sessões
    # antigas foi feita caso a caso — ver plano de 2026-07-12)
    if (yaml_status == "CONCLUÍDO" && !is_legacy) {
      concluido_data <- yaml_data$concluido
      if (is.null(concluido_data) || concluido_data == "null" || concluido_data == "") {
        cat_warn(sprintf("Plano '%s' está CONCLUÍDO no YAML, mas a data 'concluido' está vazia ou nula.", plan_file))
      }

      # Procurar por logs vinculados em 'relacionados'
      linked_conversas <- grep("conversa-", yaml_data$relacionados, value = TRUE)

      # Verificar se alguma conversa vinculada está listada no inventário
      found_in_inventory <- FALSE
      if (length(linked_conversas) > 0) {
        for (conv in linked_conversas) {
          if (conv %in% indexed_reviews) {
            found_in_inventory <- TRUE
            break
          }
        }
      }

      # Se não encontrou por relacionados, tentar encontrar no inventário de reviews por data
      if (!found_in_inventory && !is.null(concluido_data) && concluido_data != "null") {
        matching_date_reviews <- grep(paste0("^", concluido_data), indexed_reviews, value = TRUE)
        if (length(matching_date_reviews) > 0) {
          found_in_inventory <- TRUE
        }
      }

      if (!found_in_inventory) {
        cat_error(sprintf("Plano concluído '%s' não possui log de conversa correspondente registrado em llm-reviews/README.md", plan_file))
        errors_found <- TRUE
      }
    }
  } else {
    if (!is_legacy && !grepl("^3-texts/", plan_file)) {
      cat_warn(sprintf("Arquivo de plano '%s' não possui frontmatter YAML válido.", plan_file))
    }
  }
}

# ── 4. Veredito Final ─────────────────────────────────────────────────────────
if (errors_found) {
  cat("\n")
  cat_error("Auditoria de governança falhou. Por favor, corrija as inconsistências listadas acima.")
  quit(status = 1)
} else {
  cat("\n")
  cat_success("Auditoria de governança concluída com sucesso! Todos os arquivos estão consistentes.")
  quit(status = 0)
}

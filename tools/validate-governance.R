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

# ── Helpers de Impressão ──────────────────────────────────────────────────────
cat_info  <- function(...) cat("ℹ ", paste0(...), "\n")
cat_success <- function(...) cat("✅ ", paste0(...), "\n")
cat_warn  <- function(...) cat("⚠ ", paste0(...), "\n")
cat_error  <- function(...) cat("❌ ", paste0(...), "\n")

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
        bak_name <- sprintf("AGENTS.md.bak.%s", format(Sys.time(), "%Y%m%d-%H%M%S"))
        file.copy("AGENTS.md", bak_name, overwrite = TRUE)
        cat_warn(paste("Backup criado em:", bak_name))
        
        file.remove("AGENTS.md")
        link_success <- FALSE
        if (.Platform$OS.type == "windows") {
          link_success <- tryCatch({
            shell("cmd /c mklink /h AGENTS.md CLAUDE.md", translate = TRUE, intern = TRUE)
            TRUE
          }, error = function(e) FALSE)
        } else {
          link_success <- tryCatch({
            system("ln CLAUDE.md AGENTS.md", intern = TRUE)
            TRUE
          }, error = function(e) FALSE)
        }
        if (!link_success || !file.exists("AGENTS.md")) {
          cat_warn("Falha ao criar link físico (permissão ou volumes distintos). Fazendo fallback para cópia física...")
          file.copy("CLAUDE.md", "AGENTS.md", overwrite = TRUE)
        }
      } else {
        cat_info("Sincronizando: AGENTS.md (mais recente) -> CLAUDE.md. Recriando Hard Link...")
        bak_name <- sprintf("CLAUDE.md.bak.%s", format(Sys.time(), "%Y%m%d-%H%M%S"))
        file.copy("CLAUDE.md", bak_name, overwrite = TRUE)
        cat_warn(paste("Backup criado em:", bak_name))
        
        file.remove("CLAUDE.md")
        link_success <- FALSE
        if (.Platform$OS.type == "windows") {
          link_success <- tryCatch({
            shell("cmd /c mklink /h CLAUDE.md AGENTS.md", translate = TRUE, intern = TRUE)
            TRUE
          }, error = function(e) FALSE)
        } else {
          link_success <- tryCatch({
            system("ln AGENTS.md CLAUDE.md", intern = TRUE)
            TRUE
          }, error = function(e) FALSE)
        }
        if (!link_success || !file.exists("CLAUDE.md")) {
          cat_warn("Falha ao criar link físico (permissão ou volumes distintos). Fazendo fallback para cópia física...")
          file.copy("AGENTS.md", "CLAUDE.md", overwrite = TRUE)
        }
      }
    }
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

        # Suporte mínimo a arrays inline: chave: ["a", "b"] (sem vírgulas internas)
        if (grepl("^\\[", value) && grepl("\\]\\s*(#.*)?$", value)) {
          inner <- sub("\\]\\s*(#.*)?$", "", sub("^\\[", "", value))
          items <- if (nchar(trimws(inner)) == 0) character(0)
                   else trimws(strsplit(inner, ",")[[1]])
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
          val_match <- regexpr("^'([^']*)'", value)
          if (val_match > 0) {
            value <- regmatches(value, val_match)
          }
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
      yaml_data <- tryCatch({
        yaml::yaml.load(yaml_text)
      }, error = function(e) {
        parse_yaml_lines(file_lines, full_path)
      })
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
  if (is.null(x) || length(x) == 0) return(NULL)
  if (is.character(x) && (identical(trimws(x[1]), "null") || identical(trimws(x[1]), ""))) return(NULL)
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
    if (startsWith(x, kw)) return(kw)
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
    if (status %in% c("ATIVO", "EM EXECUÇÃO")) return(sprintf("**%s**", status))
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
    if (is_header || is_separator) next  # cabeçalho é reescrito programaticamente

    if (!grepl("^\\|", line)) {
      out_rows <- c(out_rows, line)  # linha não-tabular: preservar verbatim
      next
    }

    parts <- strsplit(line, "\\s*\\|\\s*")[[1]]
    fname <- if (length(parts) >= 2) trimws(sub("\\s*\\(.*$", "", gsub("`", "", parts[[2]]))) else ""
    meta <- if (nchar(fname) > 0) plan_meta[[fname]] else NULL

    if (is.null(meta)) {
      out_rows <- c(out_rows, line)  # sem YAML (legado) ou fora da varredura: preservar verbatim
      next
    }

    seen_files <- c(seen_files, fname)
    yaml_status <- trimws(meta$status)
    index_status_cell <- if (length(parts) >= 3) parts[[3]] else ""

    if (normalize_status(index_status_cell) == yaml_status) {
      out_rows <- c(out_rows, line)  # já em sincronia: preservar anotações manuais
    } else {
      desc <- if (length(parts) >= 5 && nchar(trimws(parts[[5]])) > 0) trimws(parts[[5]])
              else (nz(meta$titulo) %||% nz(meta$title) %||% "—")
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
  cat_success(sprintf("Índice plan/README.md sincronizado: %d linha(s) atualizada(s), %d plano(s) novo(s), demais preservadas.",
                      n_updated, length(new_rows)))
  quit(status = 0)
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
        cat_error(sprintf("Tipo de plano inválido no nome do arquivo '%s': '%s' (Esperado: %s)", 
                          plan_file, plan_type, paste(valid_types, collapse = ", ")))
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
      cat_error(sprintf("Divergência de status no plano '%s': YAML diz '%s' e README.md diz '%s'", 
                        plan_file, yaml_status, index_status))
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

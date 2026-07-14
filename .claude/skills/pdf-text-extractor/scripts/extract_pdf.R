library(pdftools)

args <- commandArgs(trailingOnly = TRUE)

parse_args <- function(args) {
  parsed <- list()
  i <- 1
  while(i <= length(args)) {
    arg <- args[i]
    if (arg == "--src" && i < length(args)) {
      parsed$src <- args[i+1]
      i <- i + 2
    } else if (arg == "--dest" && i < length(args)) {
      parsed$dest <- args[i+1]
      i <- i + 2
    } else if (arg == "--src-dir" && i < length(args)) {
      parsed$src_dir <- args[i+1]
      i <- i + 2
    } else if (arg == "--dest-dir" && i < length(args)) {
      parsed$dest_dir <- args[i+1]
      i <- i + 2
    } else {
      i <- i + 1
    }
  }
  return(parsed)
}

clean_filename <- function(f) {
  dest_name <- iconv(f, to = "ASCII//TRANSLIT")
  if (is.na(dest_name)) dest_name <- f
  dest_name <- gsub("([âáàãäÂÁÀÃÄ])", "a", dest_name)
  dest_name <- gsub("([êéèëÊÉÈË])", "e", dest_name)
  dest_name <- gsub("([îíìïÎÍÌÏ])", "i", dest_name)
  dest_name <- gsub("([ôóòõöÔÓÒÕÖ])", "o", dest_name)
  dest_name <- gsub("([ûúùüÛÚÙÜ])", "u", dest_name)
  dest_name <- gsub("([çÇ])", "c", dest_name)
  return(dest_name)
}

params <- parse_args(args)

if (!is.null(params$src) && !is.null(params$dest)) {
  if (file.exists(params$src)) {
    cat("Extracting text from:", params$src, "to", params$dest, "\n")
    txt <- pdf_text(params$src)
    txt <- paste(txt, collapse = "\n\n--- PAGE BREAK ---\n\n")
    writeLines(txt, params$dest, useBytes = TRUE)
    cat("Extraction complete!\n")
  } else {
    stop("Source PDF file does not exist.")
  }
} else if (!is.null(params$src_dir) && !is.null(params$dest_dir)) {
  if (dir.exists(params$src_dir)) {
    if (!dir.exists(params$dest_dir)) {
      dir.create(params$dest_dir, recursive = TRUE)
    }
    pdf_files <- list.files(params$src_dir, pattern = "\\.pdf$", ignore.case = TRUE)
    cat("Found", length(pdf_files), "PDF files to convert.\n")
    for (f in pdf_files) {
      src_file <- file.path(params$src_dir, f)
      dest_name <- clean_filename(f)
      dest_name <- gsub("\\.pdf$", ".txt", dest_name, ignore.case = TRUE)
      dest_file <- file.path(params$dest_dir, dest_name)
      
      cat("Converting:", f, "->", dest_name, "\n")
      tryCatch({
        txt <- pdf_text(src_file)
        txt <- paste(txt, collapse = "\n\n--- PAGE BREAK ---\n\n")
        writeLines(txt, dest_file, useBytes = TRUE)
      }, error = function(e) {
        cat("Error converting", f, ":", e$message, "\n")
      })
    }
    cat("Batch conversion complete!\n")
  } else {
    stop("Source directory does not exist.")
  }
} else {
  cat("Usage:\n")
  cat("  Rscript extract_pdf.R --src <input.pdf> --dest <output.txt>\n")
  cat("  Rscript extract_pdf.R --src-dir <pdf_folder> --dest-dir <txt_folder>\n")
}

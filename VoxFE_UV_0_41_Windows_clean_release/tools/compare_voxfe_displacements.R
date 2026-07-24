#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

usage <- function() {
  cat(
    "Usage:\n",
    "  Rscript compare_voxfe_displacements.R\n",
    "  Rscript compare_voxfe_displacements.R displacement1.txt displacement2.txt [output_dir]\n",
    "\n",
    "What it does:\n",
    "  - Aligns two VoxFE displacement files by node/coordinate when possible.\n",
    "  - Compares Ux, Uy, Uz and total displacement magnitude.\n",
    "  - Reports correlation, RMSE, bias, max absolute error and vector-angle agreement.\n",
    "  - If validation JSON files are provided, also compares residual/equilibrium metrics from the solver logs.\n",
    "\n",
    "Important:\n",
    "  The old VoxFEA result is not treated as ground truth. This script reports agreement and,\n",
    "  when available, independent validation metrics such as force/reaction balance.\n",
    sep = ""
  )
  quit(status = 1)
}

choose_file <- function(title) {
  message(title)
  if (.Platform$OS.type == "windows") {
    path <- choose.files(caption = title, multi = FALSE)
    if (!length(path) || !nzchar(path[[1]])) stop("No file selected.")
    return(path[[1]])
  }
  path <- file.choose()
  if (!length(path) || !nzchar(path[[1]])) stop("No file selected.")
  path[[1]]
}

if (length(args) == 0) {
  old_path <- normalizePath(choose_file("Choose displacement file 1"), mustWork = TRUE)
  new_path <- normalizePath(choose_file("Choose displacement file 2"), mustWork = TRUE)
  stamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  out_dir <- file.path(dirname(new_path), paste0("displacement_comparison_", stamp))
} else if (length(args) >= 2) {
  old_path <- normalizePath(args[[1]], mustWork = TRUE)
  new_path <- normalizePath(args[[2]], mustWork = TRUE)
  out_dir <- if (length(args) >= 3) args[[3]] else file.path(dirname(new_path), "displacement_comparison_output")
} else {
  usage()
}
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

read_disp <- function(path) {
  lines <- readLines(path, warn = FALSE)
  number_pattern <- "[-+]?(?:\\d+(?:\\.\\d*)?|\\.\\d+)(?:[eE][-+]?\\d+)?"
  values <- lapply(lines, function(line) {
    matches <- gregexpr(number_pattern, line, perl = TRUE)
    nums <- regmatches(line, matches)[[1]]
    if (!length(nums) || identical(nums, character(0))) return(numeric(0))
    suppressWarnings(as.numeric(nums))
  })
  values <- values[lengths(values) >= 3]
  if (!length(values)) stop("No numeric displacement rows found in: ", path)

  ncols <- max(lengths(values))
  padded <- t(vapply(values, function(v) {
    out <- rep(NA_real_, ncols)
    out[seq_along(v)] <- v
    out
  }, numeric(ncols)))
  padded <- padded[rowSums(is.finite(padded)) >= 3, , drop = FALSE]
  if (!nrow(padded)) stop("No usable numeric displacement rows found in: ", path)

  # Supported common formats:
  #   x y z ux uy uz
  #   node_id ux uy uz
  #   ux uy uz
  if (ncols >= 6) {
    x <- padded[, 1]
    y <- padded[, 2]
    z <- padded[, 3]
    ux <- padded[, ncols - 2]
    uy <- padded[, ncols - 1]
    uz <- padded[, ncols]
    key <- paste(x, y, z, sep = "_")
  } else if (ncols >= 4) {
    node_id <- padded[, 1]
    ux <- padded[, ncols - 2]
    uy <- padded[, ncols - 1]
    uz <- padded[, ncols]
    key <- as.character(node_id)
  } else {
    ux <- padded[, 1]
    uy <- padded[, 2]
    uz <- padded[, 3]
    key <- as.character(seq_len(nrow(padded)))
  }

  keep <- is.finite(ux) & is.finite(uy) & is.finite(uz)
  if (!any(keep)) {
    stop("The file was read, but no finite ux/uy/uz displacement triplets were found: ", path)
  }
  out <- data.frame(
    row_index = which(keep),
    key = key[keep],
    ux = ux[keep],
    uy = uy[keep],
    uz = uz[keep]
  )
  out$umag <- sqrt(out$ux^2 + out$uy^2 + out$uz^2)
  message("Read ", nrow(out), " displacement rows from: ", basename(path))
  out
}

metric <- function(a, b) {
  ok <- is.finite(a) & is.finite(b)
  a <- a[ok]
  b <- b[ok]
  d <- b - a
  data.frame(
    n = length(a),
    correlation = if (length(a) > 2) cor(a, b) else NA_real_,
    rmse = sqrt(mean(d^2)),
    mae = mean(abs(d)),
    bias_new_minus_old = mean(d),
    max_abs_error = max(abs(d)),
    old_min = min(a),
    old_mean = mean(a),
    old_max = max(a),
    new_min = min(b),
    new_mean = mean(b),
    new_max = max(b)
  )
}

old <- read_disp(old_path)
new <- read_disp(new_path)
merged <- merge(old, new, by = "key", suffixes = c("_old", "_new"))
if (nrow(merged) == 0) stop("No matching displacement rows/nodes between files.")
finite_plot <- is.finite(merged$umag_old) & is.finite(merged$umag_new)
if (!any(finite_plot)) {
  stop("The files were aligned, but no finite total displacement pairs were found. Check the displacement file format.")
}

dot <- merged$ux_old * merged$ux_new + merged$uy_old * merged$uy_new + merged$uz_old * merged$uz_new
norm_prod <- merged$umag_old * merged$umag_new
cosang <- dot / pmax(norm_prod, .Machine$double.eps)
cosang <- pmax(-1, pmin(1, cosang))
angle_deg <- acos(cosang) * 180 / pi

summary <- rbind(
  cbind(component = "ux", metric(merged$ux_old, merged$ux_new)),
  cbind(component = "uy", metric(merged$uy_old, merged$uy_new)),
  cbind(component = "uz", metric(merged$uz_old, merged$uz_new)),
  cbind(component = "umag", metric(merged$umag_old, merged$umag_new))
)
summary$median_vector_angle_deg <- c(NA, NA, NA, median(angle_deg, na.rm = TRUE))
summary$p95_vector_angle_deg <- c(NA, NA, NA, as.numeric(quantile(angle_deg, 0.95, na.rm = TRUE)))

write.csv(summary, file.path(out_dir, "displacement_comparison_summary.csv"), row.names = FALSE)

merged$diff_ux <- merged$ux_new - merged$ux_old
merged$diff_uy <- merged$uy_new - merged$uy_old
merged$diff_uz <- merged$uz_new - merged$uz_old
merged$diff_umag <- merged$umag_new - merged$umag_old
merged$vector_angle_deg <- angle_deg
write.csv(merged, file.path(out_dir, "displacement_comparison_by_node.csv"), row.names = FALSE)

png(file.path(out_dir, "umag_old_vs_new.png"), width = 1100, height = 900)
plot(merged$umag_old[finite_plot], merged$umag_new[finite_plot], pch = 16, cex = 0.35, col = rgb(0, 0, 0, 0.25),
     xlab = "Old VoxFEA total displacement", ylab = "New VoxFE total displacement",
     main = "Total displacement agreement")
abline(0, 1, col = "red", lwd = 2)
dev.off()

png(file.path(out_dir, "umag_difference_histogram.png"), width = 1100, height = 900)
hist(merged$diff_umag, breaks = 80, col = "grey70", border = "white",
     main = "New - old total displacement", xlab = "Difference")
abline(v = 0, col = "red", lwd = 2)
dev.off()

read_json_simple <- function(path) {
  if (!file.exists(path)) return(NULL)
  if (!requireNamespace("jsonlite", quietly = TRUE)) return(NULL)
  jsonlite::fromJSON(path, simplifyVector = TRUE)
}

validation_rows <- list()
if (length(args) >= 5) {
  old_val <- read_json_simple(normalizePath(args[[4]], mustWork = FALSE))
  new_val <- read_json_simple(normalizePath(args[[5]], mustWork = FALSE))
  extract <- function(label, val) {
    if (is.null(val)) return(data.frame(run = label, note = "validation JSON unavailable or jsonlite missing"))
    flat <- unlist(val)
    wanted <- flat[grepl("residual|reaction|force|balance|displacement|max|min|mean|material|voxel", names(flat), ignore.case = TRUE)]
    if (!length(wanted)) return(data.frame(run = label, note = "no recognized validation metrics"))
    data.frame(run = label, metric = names(wanted), value = as.character(wanted), row.names = NULL)
  }
  validation_rows <- rbind(extract("old", old_val), extract("new", new_val))
  write.csv(validation_rows, file.path(out_dir, "validation_metrics_comparison.csv"), row.names = FALSE)
}

cat("Compared rows:", nrow(merged), "\n")
cat("Summary:", file.path(out_dir, "displacement_comparison_summary.csv"), "\n")
cat("Per-node table:", file.path(out_dir, "displacement_comparison_by_node.csv"), "\n")
cat("Plots:", file.path(out_dir, "umag_old_vs_new.png"), "and", file.path(out_dir, "umag_difference_histogram.png"), "\n")
if (length(args) >= 5) cat("Validation metrics:", file.path(out_dir, "validation_metrics_comparison.csv"), "\n")

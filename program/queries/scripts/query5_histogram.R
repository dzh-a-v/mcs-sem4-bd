args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)

if (length(file_arg) == 0) {
  stop("Run this script with Rscript so it can locate the results directory.")
}

script_file <- sub("^--file=", "", file_arg[1])
script_dir <- dirname(normalizePath(script_file, mustWork = TRUE))
results_dir <- normalizePath(file.path(script_dir, "..", "results"), mustWork = FALSE)

input_file <- file.path(results_dir, "query5.csv")
output_file <- file.path(results_dir, "query5_histogram.png")

if (!file.exists(input_file)) {
  stop(
    paste(
      "Input file does not exist:",
      input_file,
      "\nRun query5.py first to create query5.csv."
    )
  )
}

data <- read.csv(input_file, stringsAsFactors = FALSE)

required_columns <- c("observations_count", "exoplanets_count")
missing_columns <- setdiff(required_columns, names(data))

if (length(missing_columns) > 0) {
  stop(
    paste(
      "Missing columns in query5.csv:",
      paste(missing_columns, collapse = ", ")
    )
  )
}

data <- data[order(data$observations_count), ]

png(
  filename = output_file,
  width = 1200,
  height = 800,
  res = 150
)

barplot(
  height = data$exoplanets_count,
  names.arg = data$observations_count,
  col = "#4C78A8",
  border = "#2F4F6F",
  xlab = "Number of observations",
  ylab = "Number of exoplanets",
  main = "Exoplanets by equal number of observations"
)

grid(nx = NA, ny = NULL, col = "gray85", lty = "dotted")

dev.off()

cat("Saved histogram to", output_file, "\n")

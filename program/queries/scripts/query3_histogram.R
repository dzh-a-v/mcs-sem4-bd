args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)

if (length(file_arg) == 0) {
  stop("Run this script with Rscript so it can locate the results directory.")
}

script_file <- sub("^--file=", "", file_arg[1])
script_dir <- dirname(normalizePath(script_file, mustWork = TRUE))
results_dir <- normalizePath(file.path(script_dir, "..", "results"), mustWork = FALSE)

input_file <- file.path(results_dir, "query3.csv")
output_file <- file.path(results_dir, "query3_histogram.png")

if (!file.exists(input_file)) {
  stop(
    paste(
      "Input file does not exist:",
      input_file,
      "\nRun query3.py first to create query3.csv."
    )
  )
}

data <- read.csv(input_file, stringsAsFactors = FALSE)

required_columns <- c("star_class", "stars_count", "observations_count")
missing_columns <- setdiff(required_columns, names(data))

if (length(missing_columns) > 0) {
  stop(
    paste(
      "Missing columns in query3.csv:",
      paste(missing_columns, collapse = ", ")
    )
  )
}

data <- data[order(data$star_class), ]

values <- rbind(
  Stars = data$stars_count,
  Observations = data$observations_count
)

png(
  filename = output_file,
  width = 1200,
  height = 800,
  res = 150
)

barplot(
  height = values,
  beside = TRUE,
  names.arg = data$star_class,
  col = c("#4C78A8", "#F58518"),
  border = c("#2F4F6F", "#9C520F"),
  xlab = "Star class",
  ylab = "Count",
  main = "Stars and observations by star class",
  legend.text = TRUE,
  args.legend = list(x = "topright", bty = "n")
)

grid(nx = NA, ny = NULL, col = "gray85", lty = "dotted")

dev.off()

cat("Saved histogram to", output_file, "\n")

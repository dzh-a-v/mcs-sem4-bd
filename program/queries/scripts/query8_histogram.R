args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)

if (length(file_arg) == 0) {
  stop("Run this script with Rscript so it can locate the results directory.")
}

script_file <- sub("^--file=", "", file_arg[1])
script_dir <- dirname(normalizePath(script_file, mustWork = TRUE))
results_dir <- normalizePath(file.path(script_dir, "..", "results"), mustWork = FALSE)

input_file <- file.path(results_dir, "query8.csv")

if (!file.exists(input_file)) {
  stop(
    paste(
      "Input file does not exist:",
      input_file,
      "\nRun query8.py first to create query8.csv."
    )
  )
}

if (!requireNamespace("rgl", quietly = TRUE)) {
  stop("Package 'rgl' is required. Install it with install.packages('rgl').")
}

data <- read.csv(input_file, stringsAsFactors = FALSE)

required_columns <- c("tele_id", "tele_type", "oper", "country", "observations_count")
missing_columns <- setdiff(required_columns, names(data))

if (length(missing_columns) > 0) {
  stop(
    paste(
      "Missing columns in query8.csv:",
      paste(missing_columns, collapse = ", ")
    )
  )
}

top_telescopes <- sort(unique(data$tele_id))
top_countries <- sort(unique(data$country))

data <- data[data$tele_id %in% top_telescopes & data$country %in% top_countries, ]
data <- data[order(data$tele_id, data$country), ]

if (nrow(data) == 0) {
  stop("No data found in query8.csv.")
}

data$tele_index <- as.integer(factor(data$tele_id, levels = top_telescopes))
data$country_index <- as.integer(factor(data$country, levels = top_countries))

max_count <- max(data$observations_count)
colors <- grDevices::hcl.colors(nrow(data), palette = "Viridis")

make_bar <- function(x, y, z, color) {
  x0 <- x - 0.35
  x1 <- x + 0.35
  y0 <- y - 0.35
  y1 <- y + 0.35
  z0 <- 0
  z1 <- z

  vertices <- rbind(
    c(x0, y0, z0), c(x1, y0, z0), c(x1, y1, z0), c(x0, y1, z0),
    c(x0, y0, z1), c(x1, y0, z1), c(x1, y1, z1), c(x0, y1, z1)
  )

  faces <- rbind(
    c(1, 2, 3, 4),
    c(5, 8, 7, 6),
    c(1, 5, 6, 2),
    c(2, 6, 7, 3),
    c(3, 7, 8, 4),
    c(4, 8, 5, 1)
  )

  rgl::quads3d(
    vertices[as.vector(t(faces)), ],
    col = color,
    alpha = 0.9
  )
}

rgl::open3d()
rgl::bg3d(color = "white")

for (i in seq_len(nrow(data))) {
  make_bar(
    data$tele_index[i],
    data$country_index[i],
    data$observations_count[i],
    colors[i]
  )
}

rgl::axes3d(edges = c("x--", "y--", "z"))
rgl::title3d(
  main = "Observations by telescope and country, all records",
  xlab = "Telescope",
  ylab = "Country",
  zlab = "Observations"
)

rgl::text3d(
  x = seq_along(top_telescopes),
  y = 0,
  z = -max_count * 0.04,
  texts = top_telescopes,
  cex = 0.35,
  adj = c(1, 0.5)
)

rgl::text3d(
  x = 0,
  y = seq_along(top_countries),
  z = -max_count * 0.04,
  texts = top_countries,
  cex = 0.35,
  adj = c(1, 0.5)
)

rgl::view3d(theta = 40, phi = 25, zoom = 0.75)

cat("Opened interactive 3D histogram for all records in an rgl window.\n")
cat("Use the mouse to rotate, zoom, and move the chart.\n")

while (rgl::rgl.cur() != 0) {
  Sys.sleep(0.2)
}

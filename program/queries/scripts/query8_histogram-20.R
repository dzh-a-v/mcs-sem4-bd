args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)

if (length(file_arg) == 0) {
  stop("Run this script with Rscript so it can locate the results directory.")
}

script_file <- sub("^--file=", "", file_arg[1])
script_dir <- dirname(normalizePath(script_file, mustWork = TRUE))
results_dir <- normalizePath(file.path(script_dir, "..", "results"), mustWork = FALSE)

input_file <- file.path(results_dir, "telescope_country_observations.csv")  # Имя файла соответствует Python‑скрипту

if (!file.exists(input_file)) {
  stop(
    paste(
      "Input file does not exist:",
      input_file,
      "\nRun the Python script first to create the CSV."
    )
  )
}

if (!requireNamespace("rgl", quietly = TRUE)) {
  stop("Package 'rgl' is required. Install it with install.packages('rgl').")
}

# Чтение данных
data <- read.csv(input_file, stringsAsFactors = FALSE)

# Проверка обязательных колонок
required_columns <- c("tele_id", "country", "observation_count")
missing_columns <- setdiff(required_columns, names(data))

if (length(missing_columns) > 0) {
  stop(
    paste(
      "Missing columns in CSV:",
      paste(missing_columns, collapse = ", ")
    )
  )
}

# Ограничение до первых 20 телескопов и стран (по порядку появления в данных)
top_telescopes_count <- 20
top_countries_count <- 20

# Берём первые N уникальных значений в порядке появления
top_telescopes <- unique(data$tele_id)[1:top_telescopes_count]
top_countries <- unique(data$country)[1:top_countries_count]

# Фильтрация данных
data_filtered <- data[
  data$tele_id %in% top_telescopes &
  data$country %in% top_countries,
]

if (nrow(data_filtered) == 0) {
  stop("No data left after selecting top telescopes and countries.")
}

# Преобразование категорий в числовые индексы для координат
data_filtered$tele_index <- as.integer(factor(data_filtered$tele_id, levels = top_telescopes))
data_filtered$country_index <- as.integer(factor(data_filtered$country, levels = top_countries))
data_filtered$observation_count <- as.numeric(data_filtered$observation_count)
data_filtered <- data_filtered[!is.na(data_filtered$observation_count), ]

# Цветовая палитра
max_count <- max(data_filtered$observation_count)
palette <- grDevices::hcl.colors(100, palette = "Viridis")

if (max_count > min(data_filtered$observation_count)) {
  color_index <- cut(
    data_filtered$observation_count,
    breaks = 100,
    labels = FALSE,
    include.lowest = TRUE
  )
} else {
  color_index <- rep(50, nrow(data_filtered))
}
colors <- palette[color_index]

# Функции для построения 3D-баров
close_rgl_devices <- function() {
  while (rgl::rgl.cur() != 0) {
    rgl::close3d()
  }
}

make_bars_vertices <- function(plot_data) {
  x0 <- plot_data$tele_index - 0.35
  x1 <- plot_data$tele_index + 0.35
  y0 <- plot_data$country_index - 0.35
  y1 <- plot_data$country_index + 0.35
  z0 <- rep(0, nrow(plot_data))
  z1 <- plot_data$observation_count

  vx <- cbind(x0, x1, x1, x0, x0, x1, x1, x0)
  vy <- cbind(y0, y0, y1, y1, y0, y0, y1, y1)
  vz <- cbind(z0, z0, z0, z0, z1, z1, z1, z1)

  face_vertex_order <- c(
    1, 2, 3, 4,
    5, 8, 7, 6,
    1, 5, 6, 2,
    2, 6, 7, 3,
    3, 7, 8, 4,
    4, 8, 5, 1
  )

  cbind(
    as.vector(t(vx[, face_vertex_order])),
    as.vector(t(vy[, face_vertex_order])),
    as.vector(t(vz[, face_vertex_order]))
  )
}

make_bar_edges <- function(plot_data) {
  x0 <- plot_data$tele_index - 0.35
  x1 <- plot_data$tele_index + 0.35
  y0 <- plot_data$country_index - 0.35
  y1 <- plot_data$country_index + 0.35
  z0 <- rep(0, nrow(plot_data))
  z1 <- plot_data$observation_count

  vx <- cbind(x0, x1, x1, x0, x0, x1, x1, x0)
  vy <- cbind(y0, y0, y1, y1, y0, y0, y1, y1)
  vz <- cbind(z0, z0, z0, z0, z1, z1, z1, z1)

  edge_vertex_order <- c(
    1, 2, 2, 3, 3, 4, 4, 1,
    5, 6, 6, 7, 7, 8, 8, 5,
    1, 5, 2, 6, 3, 7, 4, 8
  )

  cbind(
    as.vector(t(vx[, edge_vertex_order])),
    as.vector(t(vy[, edge_vertex_order])),
    as.vector(t(vz[, edge_vertex_order]))
  )
}

draw_z_perimeter_grid <- function(x_count, y_count, max_z) {
  x_min <- 0.5
  x_max <- x_count + 0.5
  y_min <- 0.5
  y_max <- y_count + 0.5
  z_levels <- pretty(c(0, max_z), n = 6)
  z_levels <- z_levels[z_levels >= 0 & z_levels <= max_z]

  for (z in z_levels) {
    rgl::segments3d(
      rbind(
        c(x_min, y_min, z), c(x_max, y_min, z),
        c(x_max, y_min, z), c(x_max, y_max, z),
        c(x_max, y_max, z), c(x_min, y_max, z),
        c(x_min, y_max, z), c(x_min, y_min, z)
      ),
      col = "gray78",
      alpha = 0.65,
      lwd = 1
    )
  }

  rgl::segments3d(
    rbind(
      c(x_min, y_min, 0), c(x_min, y_min, max_z),
      c(x_max, y_min, 0), c(x_max, y_min, max_z),
      c(x_max, y_max, 0), c(x_max, y_max, max_z),
      c(x_min, y_max, 0), c(x_min, y_max, max_z)
    ),
    col = "gray70",
    alpha = 0.75,
    lwd = 1
  )

  rgl::text3d(
    x = x_max + 0.45,
    y = y_min - 0.45,
    z = z_levels,
    texts = z_levels,
    cex = 0.55,
    adj = c(0, 0.5)
  )

  rgl::segments3d(
    rbind(c(x_max, y_min, 0), c(x_max, y_min, max_z)),
    col = "gray35",
    lwd = 2
  )
}

# Основной блок отрисовки
close_rgl_devices()
rgl::open3d()
rgl::bg3d(color = "white")
rgl::material3d(specular = "gray35")

# Рисуем сетку
draw_z_perimeter_grid(
  length(top_telescopes),
  length(top_countries),
  max_count
)

# Рисуем бары
rgl::quads3d(
  make_bars_vertices(data_filtered),
  col = rep(colors, each = 6),
  alpha = 0.9
)

# Рисуем рёбра баров
rgl::segments3d(
  make_bar_edges(data_filtered),
  col = "white",
  alpha = 0.95,
  lwd = 1
)

# Подписи осей
rgl::text3d(
  x = seq_along(top_telescopes),
  y = 0,
  z = -max_count * 0.04,
  texts = top_telescopes,
  cex = 0.55,
  adj = c(1, 0.5)
)

rgl::text3d(
  x = 0,
  y = seq_along(top_countries),
  z = -max_count * 0.04,
  texts = top_countries,
  cex = 0.55,
  adj = c(1, 0.5)
)

# Заголовок
# rgl::title3d(
#   main = "Observations by telescope and country (first 20)",
#   xlab = "Telescope",
#   ylab = "Country",
#   zlab = "Observations"
# )

# Настройка вида
rgl::view3d(theta = 40, phi = 25, zoom = 0.75)

cat("Opened interactive 3D histogram for first 20 telescopes and countries.\n")
cat("Use the mouse to rotate, zoom, and move the chart.\n")

# Ожидание закрытия окна
while (rgl::rgl.cur() != 0) {
  Sys.sleep(0.2)
}

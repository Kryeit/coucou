library(ggplot2)
library(plotly)

onlines_graph <- function(data) {
  if (nrow(data) == 0 || !all(c("hour", "count") %in% colnames(data))) {
    stop("Data is empty or does not contain required columns.")
  }
  
  data$formatted_hour <- sprintf("%02d:00", data$hour)
  data$tooltip <- sprintf("Hour: %s<br>Players: %d", data$formatted_hour, data$count)
  
  hour_labels <- c(paste0(1:12, "am"), paste0(1:12, "pm"))
  
  p <- ggplot(data, aes(x = hour, y = count)) +
    geom_line(color = "#1982C4", linewidth = 1.5) +
    labs(
      title = "Online Players per Hour",
      x = "Hour of Day",
      y = "Number of Players Online"
    ) +
    scale_x_continuous(
      breaks = 0:23,
      labels = hour_labels,
      limits = c(0, 23)
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
      axis.title.x = element_text(size = 14),
      axis.title.y = element_text(size = 14),
      axis.text = element_text(size = 12)
    )
  
  plotly_plot <- ggplotly(p, tooltip = "text") %>%
    layout(
      hovermode = "x",
      hoverlabel = list(
        bgcolor = "white",
        font = list(color = "black"),
        align = "left"
      )
    )
  
  plotly_plot <- plotly_plot %>%
    add_trace(
      data = data,
      x = ~hour,
      y = ~count,
      type = "scatter",
      mode = "markers",
      marker = list(color = "rgba(0,0,0,0)"),
      hoverinfo = "text",
      text = ~tooltip
    )
  
  plotly_plot
}
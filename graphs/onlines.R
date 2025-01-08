library(ggplot2)
library(plotly)

onlines_graph <- function(data) {
  # Check if data is not empty and has the expected columns
  if (nrow(data) == 0 || !all(c("hour", "count") %in% colnames(data))) {
    stop("Data is empty or does not contain required columns.")
  }
  
  # Add a formatted_hour column for the tooltip
  data$formatted_hour <- sprintf("%02d:00", data$hour)
  data$tooltip <- sprintf("Hour: %s<br>Players: %d", data$formatted_hour, data$count)
  
  # Create a vector of labels for the x-axis
  hour_labels <- c(paste0(1:12, "am"), paste0(1:12, "pm"))
  
  # Create the ggplot object with a modern theme
  p <- ggplot(data, aes(x = hour, y = count)) +
    geom_line(color = "#1982C4", linewidth = 1.5) +  # Blue line
    labs(
      title = "Online Players per Hour",
      x = "Hour of Day",
      y = "Number of Players Online"
    ) +
    scale_x_continuous(
      breaks = 0:23,              # Show each hour from 0 to 23
      labels = hour_labels,       # Use custom labels
      limits = c(0, 23)           # Ensure the x-axis limits are 0 to 23
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),  # Center and bold title
      axis.title.x = element_text(size = 14),
      axis.title.y = element_text(size = 14),
      axis.text = element_text(size = 12)
    )
  
  # Convert ggplot to plotly and customize hover behavior
  plotly_plot <- ggplotly(p, tooltip = "text") %>%
    layout(
      hovermode = "x",  # Show hover info for all traces at the same x
      hoverlabel = list(
        bgcolor = "white",  # Background color of the hover label
        font = list(color = "black"),
        align = "left"
      )
    )
  
  # Add a transparent scatter layer for hover effects
  plotly_plot <- plotly_plot %>%
    add_trace(
      data = data,
      x = ~hour,
      y = ~count,
      type = "scatter",
      mode = "markers",
      marker = list(color = "rgba(0,0,0,0)"),  # Transparent markers
      hoverinfo = "text",
      text = ~tooltip
    )
  
  # Ensure the line is above the markers
  plotly_plot <- plotly_plot %>%
    layout(
      dragmode = "select"  # Optional: change drag mode
    )
  
  plotly_plot
}
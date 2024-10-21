library(plotly)
library(shiny)
library(dplyr)

# Function to generate heatmap based on data and whether 3D is selected
player_movement_graph <- function(data, is_3d) {
  if (nrow(data) == 0) {
    return(NULL)  # If no data, return NULL
  }

  # For heatmap, we will aggregate data based on x, y, and z
  heatmap_data <- data %>%
    group_by(x, y, z) %>%
    summarise(count = n(), .groups = 'drop')

  if (is_3d) {
    # Create a 3D scatter plot with color based on count (y representing height)
    return(
      plot_ly(data = heatmap_data, x = ~x, y = ~z, z = ~y, 
              type = "scatter3d", mode = "markers",
              marker = list(size = ~sqrt(count), color = ~count, colorscale = "Viridis", showscale = TRUE)) %>%
        layout(title = "3D Heatmap - Player Movements",
               scene = list(
                 xaxis = list(title = "X"),
                 yaxis = list(title = "Z"),
                 zaxis = list(title = "Height (Y)")
               ))
    )
  } else {
    # Create a 2D heatmap using x and z with color based on counts
    heatmap_2d_data <- heatmap_data %>%
      group_by(x, z) %>%
      summarise(count = sum(count), .groups = 'drop')
    
    return(
      plot_ly(data = heatmap_2d_data, x = ~x, y = ~z, z = ~count,
              type = "heatmap", colorscale = "Viridis") %>%
        layout(title = "2D Heatmap - Player Movements",
               xaxis = list(title = "X"),
               yaxis = list(title = "Z"))
    )
  }
}
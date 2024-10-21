library(shiny)
library(plotly)

player_movement_ui <- function() {
  fluidPage(
    titlePanel("Player Movement Heatmap"),
    sidebarLayout(
      sidebarPanel(
        dateInput("date", "Select Date:", value = Sys.Date()), # Date picker to filter data by date
        checkboxInput("is_3d", "Show 3D Heatmap", value = FALSE), # Checkbox to toggle 3D heatmap
        actionButton("update", "Update Heatmap") # Update heatmap button
      ),
      mainPanel(
        plotlyOutput("heatmap_output") # Output for the heatmap
      )
    )
  )
}

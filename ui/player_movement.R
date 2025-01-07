library(shiny)
library(plotly)

player_movement_ui <- function(id) {
  ns <- NS(id)
  fluidPage(
    titlePanel("Player Movement Heatmap"),
    sidebarLayout(
      sidebarPanel(
        dateInput("date", "Select Date:", value = Sys.Date()),
        checkboxInput("is_3d", "Show 3D Heatmap", value = FALSE),
        actionButton("update", "Update Heatmap")
      ),
      mainPanel(
        plotlyOutput(ns("player_movement_output"))
      )
    )
  )
}

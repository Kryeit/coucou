library(shiny)

onlines_ui <- function() {
  ns <- NS("onlines_module")
  
  fluidPage(
    titlePanel("Online Players per Hour"),
    sidebarLayout(
      sidebarPanel(
        dateInput(ns("date"), "Select Date:", value = Sys.Date())
      ),
      mainPanel(
        plotlyOutput(ns("onlines_output"))
      )
    )
  )
}
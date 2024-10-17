library(shiny)

onlines_ui <- function() {
  fluidPage(
    titlePanel("Online Players per Hour"),
    sidebarLayout(
      sidebarPanel(
        dateInput("date", "Select Date:", value = Sys.Date())  # Date picker
      ),
      mainPanel(
        plotlyOutput("onlines_output")
      )
    )
  )
}

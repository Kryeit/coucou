library(shiny)
library(shiny.router)
library(shiny.tailwind)

options(shiny.port = 6968)

source_folder <- function(folder) {
  files <- list.files(folder, recursive = TRUE, full.names = TRUE, pattern = "\\.R$")
  for (f in files) source(f)
}

source_folder("components")
source_folder("routes/home")
source_folder("routes/onlines")
source_folder("routes/leaderboard")

addResourcePath("assets", "assets")

ui <- fluidPage(
  use_tailwind(),
  includeCSS("assets/main.css"),
  
  header_ui(),
  router_ui(
    route("/", home_ui()),
    route("leaderboard", leaderboard_ui()),
    route("onlines", onlines_ui())
  )
)

server <- function(input, output, session) {
  router_server()
}

shinyApp(ui, server)

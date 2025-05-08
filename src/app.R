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
  
  div(
    class = "min-h-screen flex flex-col",
    header_ui(),
    
    tags$main(class = "flex-grow",
              router_ui(
                route("/", home_ui()),
                route("onlines", onlines_ui()),
                route("leaderboard", leaderboard_ui("leaderboard"))
              )
    ),
    
    footer_ui()
  )
)

server <- function(input, output, session) {
  header_server(input, output, session)
  router_server(root_page = "/")

  observe({
    header_server(input, output, session, current_route = get_page())

    if (get_page() == "onlines") {
      onlines_server(input, output, session)
    } else if (get_page() == "leaderboard") {
      moduleServer("leaderboard", leaderboard_server)
    }
  })
  
}

shinyApp(ui, server)

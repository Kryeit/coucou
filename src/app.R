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
source_folder("routes/leaderboard")

addResourcePath("assets", "assets")

ui <- tagList(
  tags$head(
    tags$meta(charset = "utf-8"),
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
    tags$title("Kryeit Statistics")
  ),
  use_tailwind(tailwindConfig = "assets/tailwind.config.js"),
  includeCSS("assets/main.css"),

  div(
    class = "min-h-screen flex flex-col bg-slate-50 text-slate-900",
    header_ui(),
    tags$main(
      class = "flex-grow w-full max-w-5xl mx-auto px-4 sm:px-6 py-8",
      router_ui(
        route("/", home_ui()),
        route("leaderboard", leaderboard_ui("leaderboard"))
      )
    ),
    footer_ui()
  )
)

server <- function(input, output, session) {
  router_server(root_page = "/")
  header_server(input, output, session)
  moduleServer("leaderboard", leaderboard_server)
}

shinyApp(ui, server)

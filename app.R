library(shiny)
library(shinyjs)


options(shiny.port = 6968)

source("ui/onlines.R")
source("server/onlines.R")
source("ui/player_movement.R")
source("server/player_movement.R")
home_ui <- function() {
  fluidPage(
    h1("Coucou! (Named by Tess_, Developed by Muri)")
  )
}

ui <- fluidPage(
  useShinyjs(),
  uiOutput("page")
)

server <- function(input, output, session) {
  current_path <- reactiveVal("")
  
  observe({
    runjs('
      function getHash() {
        var hash = window.location.hash;
        console.log("JavaScript: Current Hash =", hash);  // Debug: Log hash in browser console
        return hash;
      }
      
      // Send the initial hash to Shiny
      Shiny.setInputValue("current_path", getHash());
      
      // Monitor hash changes
      window.addEventListener("hashchange", function() {
        Shiny.setInputValue("current_path", getHash());
      });
    ')
  })
  
  observeEvent(input$current_path, {
    path <- input$current_path
    current_path(path)
  })
  
  output$page <- renderUI({
    path <- current_path()
    if (path == "" || path == "#/") {
      home_ui()
    } else if (path == "#/onlines") {
      onlines_ui("onlines_module")
    } else if (path == "#/player_movement") {
      player_movement_ui("player_movement_module")
    } else {
      fluidPage(
        h1("404 Not Found")
      )
    }
  })
  
  observeEvent(current_path(), {
    if (current_path() == "#/onlines") {
      callModule(onlines_server, "onlines_module")
    } else if (current_path() == "#/player_movement") {
      callModule(player_movement_server, "player_movement_module")
    }
  })
}

shinyApp(ui = ui, server = server)
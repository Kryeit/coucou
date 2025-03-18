library(shiny)
library(shinyjs)

options(shiny.port = 6968)

source("routes/onlines/ui.R")
source("routes/onlines/server.R")

source("routes/leaderboard/ui.R")
source("routes/leaderboard/server.R")

# Configure static file serving for assets directory
addResourcePath("assets", "assets")

home_ui <- function() {
  fluidPage(
    h1("Coucou! (Named by Tess_, Developed by Muri)")
  )
}

ui <- fluidPage(
  tags$head(
    tags$link(rel = "shortcut icon", href = "assets/icon.png")
  ),
  useShinyjs(),
  uiOutput("page")
)

server <- function(input, output, session) {
  current_path <- reactiveVal("")
  
  observe({
    runjs('
      function getHash() {
        var hash = window.location.hash;
        // Extract just the route part if there are parameters
        var routeEnd = hash.indexOf("?");
        return routeEnd !== -1 ? hash.substring(0, routeEnd) : hash;
      }
      
      function getUrlParams() {
        // Parse parameters from the hash part
        var hash = window.location.hash;
        var paramIndex = hash.indexOf("?");
        
        if (paramIndex !== -1) {
          var paramString = hash.substring(paramIndex + 1);
          var urlParams = new URLSearchParams(paramString);
          
          // Store URL parameters as global data to be accessed by the module
          window.leaderboardParams = {
            stat_type: urlParams.get("stat_type"),
            item_filter: urlParams.get("item_filter")
          };
          
          return hash.substring(0, paramIndex);
        } else {
          window.leaderboardParams = null;
          return hash;
        }
      }
      
      // Send the initial hash to Shiny
      var hash = getUrlParams();
      Shiny.setInputValue("current_path", hash || "");
      
      // Monitor hash changes
      window.addEventListener("hashchange", function() {
        var hash = getUrlParams();
        Shiny.setInputValue("current_path", hash || "");
      });
      
      // Function to update URL with current selections
      window.updateLeaderboardUrl = function(stat_type, item_filter) {
        var baseHash = "#/leaderboard";
        var newHash = baseHash + "?stat_type=" + encodeURIComponent(stat_type) + 
                    "&item_filter=" + encodeURIComponent(item_filter);
        window.history.replaceState({}, "", newHash);
      };
    ')
  })
  
  observeEvent(input$current_path, {
    path <- input$current_path
    current_path(path)
  })
  
  # Router
  output$page <- renderUI({
    path <- current_path()
    if (path == "" || path == "#/") {
      home_ui()
    } else if (path == "#/onlines") {
      onlines_ui("onlines_module")
    } else if (path == "#/leaderboard") {
      leaderboard_ui("leaderboard_module")
    } else {
      fluidPage(
        h1("404 Not Found")
      )
    }
  })
  
  observeEvent(current_path(), {
    if (current_path() == "#/onlines") {
      callModule(onlines_server, "onlines_module")
    } else if (current_path() == "#/leaderboard") {
      callModule(leaderboard_server, "leaderboard_module")
    }
  })
}

shinyApp(ui = ui, server = server)
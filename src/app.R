library(shiny)
library(shinyjs)

options(shiny.port = 6968)

source("routes/onlines/ui.R")
source("routes/onlines/server.R")
source("routes/leaderboard/ui.R")
source("routes/leaderboard/server.R")

addResourcePath("assets", "assets")

home_ui <- function() {
  fluidPage(
    div(class = "banner-container",
        a(href = "https://coucou.kryeit.com",
          img(src = "assets/banner.png", class = "banner-image", alt = "Kryeit Banner")
        )
    ),
    a(href = "https://coucou.kryeit.com/#/leaderboard", "Leaderboard", class = "link"),
    a(href = "https://coucou.kryeit.com/#/onlines", "Onlines", class = "link"),
    
  )
}

ui <- fluidPage(
  tags$head(
    tags$title("Coucou"),
    tags$link(rel = "shortcut icon", href = "assets/icon.png"),
    tags$link(rel = "stylesheet", type = "text/css", href = "assets/main.css")
  ),
  useShinyjs(),
  uiOutput("page")
)

server <- function(input, output, session) {
  current_path <- reactiveVal("")
  
  observe({
    runjs('
      function getUrlParams() {
        var hash = window.location.hash;
        var paramIndex = hash.indexOf("?");
        var params = {};
        if (paramIndex !== -1) {
          var paramString = hash.substring(paramIndex + 1);
          new URLSearchParams(paramString).forEach((value, key) => {
            params[key] = value;
          });
        }
        window.urlParams = params;
        return hash.substring(0, paramIndex !== -1 ? paramIndex : hash.length);
      }
      
      var hash = getUrlParams();
      Shiny.setInputValue("current_path", hash || "");
      
      window.addEventListener("hashchange", function() {
        var hash = getUrlParams();
        Shiny.setInputValue("current_path", hash || "");
      });
      
      if (window.urlParams && window.urlParams.stat_type) {
        Shiny.setInputValue("leaderboard_module-url_params", window.urlParams);
      }
      
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
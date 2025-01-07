library(shiny)
library(shinyjs)  # Load shinyjs for JavaScript integration

# Source the UI and server files
source("ui/onlines.R")
source("server/onlines.R")

# Define UI function for the home page
home_ui <- function() {
  fluidPage(
    h1("Home Page")
  )
}

# Define the UI
ui <- fluidPage(
  useShinyjs(),  # Initialize shinyjs
  uiOutput("page")  # Dynamic UI for rendering pages
)

# Define the server logic
server <- function(input, output, session) {
  # Reactive value to store the current path
  current_path <- reactiveVal("")
  
  # JavaScript to monitor URL changes and send the path to Shiny
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
  
  # Observe changes to the path sent from JavaScript
  observeEvent(input$current_path, {
    path <- input$current_path
    # Debug: Print the current URL path
    print(paste("Shiny: Current URL Path =", path))
    
    # Update the reactive value
    current_path(path)
  })
  
  # Render the appropriate UI based on the path
  output$page <- renderUI({
    path <- current_path()
    # Debug: Print the path being evaluated
    print(paste("Shiny: Evaluating Path =", path))
    
    if (path == "" || path == "#/") {
      print("Shiny: Rendering Home Page")
      home_ui()
    } else if (path == "#/onlines") {
      print("Shiny: Rendering Onlines Page")
      onlines_ui()
    } else {
      print("Shiny: Rendering 404 Page")
      fluidPage(
        h1("404 Not Found")
      )
    }
  })
  
  # Call the onlines_server module when the /onlines route is active
  observeEvent(current_path(), {
    if (current_path() == "#/onlines") {
      print("Heeey")
      callModule(onlines_server, "#/onlines")
    }
  })
}

# Run the app
shinyApp(ui = ui, server = server)
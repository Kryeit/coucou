library(shiny)
library(DBI)

# Source the database connection and graph rendering scripts
source("db/clickhouse.R")  # Database connection logic
source("graphs/player_movement.R")  # Graph generation logic

# Define server logic for Player Movement Heatmap
player_movement_server <- function(input, output, session) {
  
  output$heatmap_output <- renderPlotly({
    # Validate the selected date
    if (is.null(input$date)) {
      showNotification("Please select a date.", type = "error")
      return(NULL)
    }
    
    # Establish connection to ClickHouse
    con <- tryCatch({
      connect_to_clickhouse()
    }, error = function(e) {
      showNotification("Failed to connect to the database.", type = "error")
      return(NULL)
    })
    
    # Ensure connection is closed after use
    on.exit({
      if (!is.null(con)) dbDisconnect(con)
    })
    
    # Fetch the selected date from input
    selected_date <- input$date
    print(paste("Selected Date:", selected_date))  # Debugging
    
    # Query the data for the selected date
    query <- sprintf("
      SELECT player, x, y, z, timestamp
      FROM player_movement
      WHERE toDate(timestamp) = '%s';", selected_date)
    
    # Execute the query and handle potential errors
    data <- tryCatch({
      dbGetQuery(con, query)
    }, error = function(e) {
      showNotification("Failed to fetch data from the database.", type = "error")
      return(NULL)
    })
    
    # Validate the fetched data
    if (is.null(data) || nrow(data) == 0) {
      showNotification("No data found for the selected date.", type = "warning")
      return(NULL)
    }
    
    # Print the fetched data for debugging
    print("Fetched Data:")
    print(head(data))  # Show the first few rows of the data
    
    # Generate the heatmap plot
    tryCatch({
      player_movement_graph(data, input$is_3d)
    }, error = function(e) {
      showNotification("Failed to generate the heatmap.", type = "error")
      return(NULL)
    })
  })
}
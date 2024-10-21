# player_movement_server.R
library(shiny)
library(DBI)

# Source the database connection and graph rendering scripts
source("db/clickhouse.R")  # Database connection logic
source("graphs/player_movement.R")  # Graph generation logic

# Define server logic for Player Movement Heatmap
player_movement_server <- function(input, output) {

  output$heatmap_output <- renderPlotly({
    con <- connect_to_clickhouse()  # Establish connection to ClickHouse
    on.exit(dbDisconnect(con))      # Ensure connection is closed after use

    # Fetch the selected date from input
    selected_date <- input$date
    # Print the selected date for debugging
    print(paste("Selected Date:", selected_date))

    # Query the data for the selected date
    query <- sprintf("
      SELECT player, x, y, z, timestamp
      FROM player_movement
      WHERE toDate(timestamp) = '%s';", selected_date)

    # Execute the query and store the result
    data <- dbGetQuery(con, query)

    # Print the fetched data for debugging
    print("Fetched Data:")
    print(head(data))  # Show the first few rows of the data

    # Pass the fetched data and 3D toggle state to the graphing function
    plot <- player_movement_graph(data, input$is_3d)

    # Print the plot object to see if it's created
    print(plot)

    return(plot)  # Ensure to return the plot
  })
}

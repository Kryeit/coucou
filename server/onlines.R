library(shiny)
library(DBI)

source("db/clickhouse.R")  # Source the database connection
source("graphs/onlines.R")  # Source the graph script

onlines_server <- function(input, output) {
  output$onlines_output <- renderPlotly({
    con <- connect_to_clickhouse()  # Establish connection
    on.exit(dbDisconnect(con))       # Ensure the connection is closed

    # Fetch the selected date from input
    selected_date <- input$date

    # Fetch all relevant data for the date
    query <- sprintf("
    SELECT start_time, end_time
    FROM sessions
    WHERE toDate(start_time) = '%s';", selected_date)

    data <- dbGetQuery(con, query)

    # Convert start_time and end_time to POSIXct for easier handling
    data$start_time <- as.POSIXct(data$start_time)
    data$end_time <- as.POSIXct(data$end_time)

    # Generate an hourly breakdown
    hours <- 0:23
    result <- data.frame(
      hour = hours,
      count = sapply(hours, function(hour) {
        sum(
          data$start_time <= as.POSIXct(sprintf("%s %02d:59:59", selected_date, hour)) &
          data$end_time >= as.POSIXct(sprintf("%s %02d:00:00", selected_date, hour))
        )
      })
    )

    # Pass the processed data to the graphing function
    onlines_graph(result)
  })
}

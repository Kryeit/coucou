library(shiny)
library(DBI)

source("db/clickhouse.R")  # Source the database connection
source("graphs/onlines.R")  # Source the graph script

# Define server logic for Online Players per Hour
onlines_server <- function(input, output) {
  output$onlines_output <- renderPlotly({
    con <- connect_to_clickhouse()  # Establish connection
    on.exit(dbDisconnect(con))       # Ensure the connection is closed

    # Fetch the selected date from input
    selected_date <- input$date

    # Fetch data from ClickHouse for the selected date
    query <- sprintf("
    SELECT t.number AS hour, COUNT(DISTINCT player) AS count
    FROM sessions,
         (
             SELECT * FROM numbers(0, 23)
         ) t
    WHERE extract(HOUR FROM start_time) <= t.number
      AND extract(HOUR FROM end_time) >= t.number
      AND toDate(start_time) = '%s'
    GROUP BY t.number
    ORDER BY t.number;", selected_date)

    # Execute the query and store the result
    data <- dbGetQuery(con, query)

    # Pass the fetched data to the graphing function
    onlines_graph(data)
  })
}

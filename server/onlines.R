source("graphs/onlines.R")
onlines_server <- function(input, output, session) {
  output$onlines_output <- renderPlotly({
    con <- connect_to_clickhouse()
    on.exit(dbDisconnect(con))
    
    selected_date <- input$date
    
    query <- sprintf("
    SELECT start_time, end_time
    FROM sessions
    WHERE toDate(start_time) = '%s';", selected_date)
    
    data <- dbGetQuery(con, query)
    
    data$start_time <- as.POSIXct(data$start_time)
    data$end_time <- as.POSIXct(data$end_time)
    
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
    
    onlines_graph(result)
  })
}
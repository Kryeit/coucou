library(shiny)
library(plotly)
library(dplyr)

# Import database connection function
source("db/clickhouse.R")
source("routes/onlines/graph.R")

onlines_server <- function(input, output, session) {
  data_reactive <- reactive({
    req(input$date)
    
    if (!inherits(input$date, "Date")) {
      stop("input$date is not a Date object")
    }
    
    con <- connect_to_clickhouse()
    on.exit(dbDisconnect(con))
    
    selected_date <- format(input$date, "%Y-%m-%d")
    
    query <- sprintf("
      SELECT start_time, end_time
      FROM sessions
      WHERE toDate(start_time) = '%s';", selected_date)
    
    data <- dbGetQuery(con, query)
    
    data$start_time <- as.POSIXct(data$start_time)
    data$end_time <- as.POSIXct(data$end_time)
    
    data
  })
  
  aggregated_data <- reactive({
    req(input$date)
    
    data <- data_reactive()
    
    selected_date <- format(input$date, "%Y-%m-%d")
    
    hours <- 0:23
    
    count_for_hour <- function(hour) {
      sum(
        data$start_time <= as.POSIXct(sprintf("%s %02d:59:59", selected_date, hour)) &
          data$end_time >= as.POSIXct(sprintf("%s %02d:00:00", selected_date, hour))
      )
    }
    
    result <- data.frame(
      hour = hours,
      count = sapply(hours, count_for_hour)
    )
    
    result
  })
  
  output$onlines_output <- renderPlotly({
    data <- aggregated_data()
    onlines_graph(data)
  })
}
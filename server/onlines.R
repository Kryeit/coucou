library(shiny)
library(crosstalk)
library(plotly)
library(dplyr)
library(ggplot2)

# Define a wrapper function to link the plot to SharedData
linked_onlines_graph <- function(data, shared_data) {
  p <- onlines_graph(data)
  p <- ggplotly(p, source = shared_data$id())
  p
}

onlines_server <- function(input, output, session) {
  # Create a reactive expression for data fetching
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
    
    # Add a unique row ID if not present
    if (!"row_id" %in% names(data)) {
      data$row_id <- rownames(data)
    }
    
    data
  })
  
  # Create a SharedData object from the reactive data
  shared_data <- SharedData$new(data_reactive, key = ~row_id)
  
  # Reactive expression for aggregated data
  aggregated_data <- reactive({
    req(input$date)
    
    data <- shared_data$data()
    
    selected_date <- format(input$date, "%Y-%m-%d")
    
    hours <- 0:23
    
    # Function to calculate count for a specific hour
    count_for_hour <- function(hour) {
      sum(
        data$start_time <= as.POSIXct(sprintf("%s %02d:59:59", selected_date, hour)) &
          data$end_time >= as.POSIXct(sprintf("%s %02d:00:00", selected_date, hour))
      )
    }
    
    # Create result data frame
    result <- data.frame(
      hour = hours,
      count = sapply(hours, count_for_hour)
    )
    
    result
  })
  
  output$onlines_output <- renderPlotly({
    # Get aggregated data
    data <- aggregated_data()
    
    # Create the linked plot
    p <- linked_onlines_graph(data, shared_data)
    
    p
  })
}
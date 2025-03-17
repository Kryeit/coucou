library(shiny)
library(dplyr)
library(DT)
library(jsonlite)
library(htmltools)
library(shinyjs)

source("db/postgres.R")
source("graphs/leaderboard.R")

# Function to create HTML for player heads in DT table
format_player_with_head <- function(username) {
  img_url <- paste0("https://kryeit.com/api/players/", username, "/head")
  img_tag <- tags$img(src = img_url, class = "dt-player-head", alt = username)
  return(as.character(tagList(img_tag, username)))
}

leaderboard_server <- function(input, output, session) {
  ns <- session$ns
  
  # Get available items for the selected stat type
  available_items <- reactive({
    req(input$stat_type)
    
    con <- connect_to_postgres()
    on.exit(dbDisconnect(con))
    
    # Fixed query using jsonb_object_keys with proper casting
    query <- sprintf("
      SELECT DISTINCT key as item
      FROM users, jsonb_object_keys(stats->'stats'->%s) key
      WHERE stats->'stats'->%s IS NOT NULL
      ORDER BY key
    ", 
                     paste0("'", input$stat_type, "'"),
                     paste0("'", input$stat_type, "'"))
    
    result <- tryCatch({
      dbGetQuery(con, query)
    }, error = function(e) {
      message("Error in query: ", e$message)
      return(data.frame(item = character(0)))
    })
    
    if (nrow(result) > 0) {
      return(result$item)
    } else {
      return(character(0))
    }
  })
  
  # Update item selection based on stat type
  observe({
    req(input$stat_type)
    
    items <- available_items()
    
    # Default selection for the first item
    selected_item <- if (length(items) > 0) items[1] else NULL
    
    updateSelectInput(session, "item_filter", 
                      choices = items,
                      selected = selected_item)
  })
  
  # Get player stats for the selected item
  player_stats <- reactive({
    req(input$stat_type, input$item_filter, input$min_value)
    
    con <- connect_to_postgres()
    on.exit(dbDisconnect(con))
    
    # Fixed query using proper casting
    query <- sprintf("
      SELECT 
        username,
        (stats->'stats'->%s->>%s)::numeric as count,
        last_seen
      FROM users
      WHERE 
        stats->'stats'->%s ? %s
        AND (stats->'stats'->%s->>%s)::numeric >= %d
      ORDER BY (stats->'stats'->%s->>%s)::numeric DESC
      LIMIT %d
    ", 
                     # Use proper quoting for JSON path components
                     paste0("'", input$stat_type, "'"), paste0("'", input$item_filter, "'"),
                     paste0("'", input$stat_type, "'"), paste0("'", input$item_filter, "'"),
                     paste0("'", input$stat_type, "'"), paste0("'", input$item_filter, "'"), input$min_value,
                     paste0("'", input$stat_type, "'"), paste0("'", input$item_filter, "'"), input$limit)
    
    result <- tryCatch({
      dbGetQuery(con, query)
    }, error = function(e) {
      message("Error in query: ", e$message)
      return(NULL)
    })
    
    if (!is.null(result) && nrow(result) > 0) {
      # Ensure count is numeric
      result$count <- as.numeric(result$count)
      return(result)
    } else {
      return(NULL)
    }
  })
  
  # Render custom HTML chart with player heads
  observe({
    req(player_stats())
    
    data <- player_stats()
    if (is.null(data) || nrow(data) == 0) return(NULL)
    
    # Get stat type name and formatted item name
    stat_name <- switch(input$stat_type,
                        "minecraft:used" = "Items Used",
                        "minecraft:broken" = "Items Broken", 
                        "minecraft:crafted" = "Items Crafted",
                        "minecraft:mined" = "Items Mined",
                        "minecraft:killed" = "Mob Kills",
                        "minecraft:killed_by" = "Deaths By",
                        "minecraft:custom" = "Custom Stats",
                        "Unknown")
    
    formatted_name <- format_item_name(input$item_filter)
    
    # Set chart header
    header_html <- paste(stat_name, "-", formatted_name)
    shinyjs::html("chart_header", header_html)
    
    # Calculate max value for scaling
    max_value <- max(data$count)
    avg_value <- mean(data$count)
    
    # Generate HTML for the custom chart
    bars_html <- lapply(1:nrow(data), function(i) {
      player <- data$username[i]
      count <- data$count[i]
      
      # Calculate percentage width based on max value (with minimum width)
      width_pct <- max(min(count / max_value * 100, 100), 8)  # Minimum 8% width
      
      # Generate the bar HTML
      bar_html <- div(
        class = "bar-container",
        title = paste0(player, "\nCount: ", count, "\nAverage: ", round(avg_value, 1)),
        img(
          src = paste0("https://kryeit.com/api/players/", player, "/head"),
          class = "player-head",
          alt = player
        ),
        div(
          class = "bar",
          style = paste0("width: ", width_pct, "%;"),
          span(class = "bar-label", count)
        )
      )
      
      return(as.character(bar_html))
    })
    
    # Combine all bars into a single HTML string
    chart_html <- paste(bars_html, collapse = "")
    
    # Update the chart container
    shinyjs::html("custom_chart", chart_html)
  })
  
  # Create leaderboard table with player heads
  output$leaderboard_table <- DT::renderDataTable({
    req(player_stats())
    
    data <- player_stats()
    if (is.null(data) || nrow(data) == 0) return(NULL)
    
    # Format player names with head images
    data$player_display <- sapply(data$username, format_player_with_head)
    
    table_data <- data %>%
      mutate(
        rank = row_number(),
        last_seen = as.character(last_seen)
      ) %>%
      select(
        Rank = rank,
        Player = player_display,
        Value = count,
        `Last Seen` = last_seen
      )
    
    DT::datatable(
      table_data,
      options = list(
        pageLength = 10,
        dom = 'frtip',
        orderClasses = TRUE
      ),
      rownames = FALSE,
      escape = FALSE,  # Allow HTML in the table
      caption = htmltools::tags$caption(
        style = 'caption-side: top; text-align: center; font-size: 18px; font-weight: bold;',
        paste("Leaderboard")
      )
    ) %>%
      DT::formatStyle(
        columns = 1:4,
        backgroundColor = 'rgba(240, 240, 240, 0.5)'
      )
  })
}
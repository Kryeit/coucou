library(shiny)
library(dplyr)
library(DT)
library(jsonlite)
library(htmltools)
library(shinyjs)

source("db/postgres.R")
source("routes/leaderboard/graph.R")

format_player_with_head <- function(username) {
  img_url <- paste0("https://kryeit.com/api/players/", username, "/head")
  img_tag <- tags$img(src = img_url, class = "dt-player-head", alt = username)
  return(as.character(tagList(img_tag, username)))
}

leaderboard_server <- function(input, output, session) {
  ns <- session$ns
  
  # Server-side selectize for item_filter
  observeEvent(input$stat_type, {
    req(input$stat_type)
    
    sql <- "
      SELECT DISTINCT key as item
      FROM users, jsonb_object_keys(stats->'stats'->$1) key
      WHERE stats->'stats'->$1 IS NOT NULL
      ORDER BY key
    "
    
    items <- safe_query(sql, input$stat_type)
    
    if (!is.null(items) && nrow(items) > 0) {
      updateSelectizeInput(session, "item_filter", 
                           choices = items$item,
                           server = TRUE)
      
      # Set default value to first item after a short delay
      if (nrow(items) > 0) {
        first_item <- items$item[1]
        shinyjs::delay(100, {
          updateSelectizeInput(session, "item_filter", selected = first_item)
        })
      }
    } else {
      updateSelectizeInput(session, "item_filter", 
                           choices = character(0),
                           server = TRUE)
    }
  })
  
  player_stats <- reactive({
    req(input$stat_type, input$item_filter)
    
    sql <- "
      SELECT 
        username,
        (stats->'stats'->$1->>$2)::numeric as count,
        last_seen
      FROM users
      WHERE 
        stats->'stats'->$1 ? $2
        AND (stats->'stats'->$1->>$2)::numeric > 0
      ORDER BY (stats->'stats'->$1->>$2)::numeric DESC
    "
    
    result <- safe_query(sql, input$stat_type, input$item_filter)
    
    if (!is.null(result) && nrow(result) > 0) {
      result$count <- as.numeric(result$count)
      return(result)
    } else {
      return(NULL)
    }
  })
  
  observe({
    req(player_stats())
    
    data <- player_stats()
    if (is.null(data) || nrow(data) == 0) return(NULL)
    
    # Update entries count
    entries_text <- paste0("(", nrow(data), " entries)")
    shinyjs::html("entries_count", entries_text)
    
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
    
    header_html <- paste(stat_name, "-", formatted_name)
    shinyjs::html("chart_header", header_html)
    
    max_value <- max(data$count)
    avg_value <- mean(data$count)
    
    bars_html <- lapply(1:nrow(data), function(i) {
      player <- data$username[i]
      count <- data$count[i]
      
      width_pct <- max(min(count / max_value * 100, 100), 8)
      
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
    
    chart_html <- paste(bars_html, collapse = "")
    
    shinyjs::html("custom_chart", chart_html)
  })
  
  output$leaderboard_table <- DT::renderDataTable({
    req(player_stats())
    
    data <- player_stats()
    if (is.null(data) || nrow(data) == 0) return(NULL)
    
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
        pageLength = 25,
        dom = 'frtip',
        orderClasses = TRUE
      ),
      rownames = FALSE,
      escape = FALSE,
      caption = htmltools::tags$caption(
        style = 'caption-side: top; text-align: center; font-size: 18px; font-weight: bold;',
        paste("Full Leaderboard")
      )
    ) %>%
      DT::formatStyle(
        columns = 1:4,
        backgroundColor = 'rgba(240, 240, 240, 0.5)'
      )
  })
}
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
  
  # Reactive value to track URL parameters
  url_params <- reactiveVal(NULL)
  
  # Flag to prevent multiple triggering
  url_params_processed <- reactiveVal(FALSE)
  
  # JavaScript to set URL parameters from window object
  runjs("
    if (window.leaderboardParams) {
      Shiny.setInputValue('leaderboard_module-url_params', window.leaderboardParams);
    }
  ")
  
  # Capture URL parameters
  observeEvent(input$url_params, {
    req(input$url_params)
    url_params(input$url_params)
    url_params_processed(FALSE)
  }, once = FALSE, priority = 100)
  
  # Process URL parameters
  observe({
    params <- url_params()
    processed <- url_params_processed()
    
    # Only process if params exist and haven't been processed
    if (!is.null(params) && !processed) {
      # Prioritize URL parameters
      if (!is.null(params$stat_type)) {
        updateSelectInput(session, "stat_type", selected = params$stat_type)
      }
      
      # Mark as processed to prevent repeated processing
      url_params_processed(TRUE)
    }
  }, priority = 99)
  
  # Handle stat type changes
  observeEvent(input$stat_type, {
    req(input$stat_type)
    
    sql <- "
            SELECT DISTINCT key as item, SPLIT_PART(key, ':', 2) as sort_key
            FROM users, jsonb_object_keys(stats->'stats'->$1) key
            WHERE stats->'stats'->$1 IS NOT NULL
            ORDER BY sort_key
        "
    
    items <- safe_query(sql, input$stat_type)
    
    if (!is.null(items) && nrow(items) > 0) {
      updateSelectizeInput(session, "item_filter", 
                           choices = items$item,
                           server = TRUE)
      
      shinyjs::delay(300, {
        params <- url_params()
        
        if (!is.null(params) && !is.null(params$item_filter) && params$item_filter %in% items$item) {
          # Prioritize URL parameter for item filter
          updateSelectizeInput(session, "item_filter", selected = params$item_filter)
        } else if (input$stat_type == "minecraft:custom" && "minecraft:play_time" %in% items$item) {
          updateSelectizeInput(session, "item_filter", selected = "minecraft:play_time")
        } else if (nrow(items) > 0) {
          updateSelectizeInput(session, "item_filter", selected = items$item[1])
        }
      })
    } else {
      updateSelectizeInput(session, "item_filter", 
                           choices = character(0),
                           server = TRUE)
    }
  }, priority = 10)
  
  # Update URL dynamically
  observeEvent(list(input$stat_type, input$item_filter), {
    req(input$stat_type, input$item_filter)
    session$sendCustomMessage(
      type = "updateUrl",
      message = list(
        stat_type = input$stat_type,
        item_filter = input$item_filter
      )
    )
  })
  
  observeEvent(input$copy_share_link, {
    # Placeholder for share link functionality
  })
  
  # Reactive to fetch player stats
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
  
  # Observe and update chart
  observe({
    req(player_stats())
    
    data <- player_stats()
    if (is.null(data) || nrow(data) == 0) return(NULL)
    
    entries_text <- paste0("(", nrow(data), " entries)")
    shinyjs::html("entries_count", entries_text)
    
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
  
  # Render leaderboard table
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
  
  # Download CSV handler
  output$download_csv <- downloadHandler(
    filename = function() {
      paste("leaderboard-", input$stat_type, "-", input$item_filter, "-", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      req(player_stats())
      data <- player_stats()
      data$rank <- seq_len(nrow(data))
      write.csv(data[, c("rank", "username", "count", "last_seen")], file, row.names = FALSE)
    }
  )
}
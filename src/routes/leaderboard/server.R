library(dplyr)
library(DT)
library(ggplot2)

source("db/postgres.R")
source("routes/leaderboard/graph.R")

format_player_with_head <- function(username) {
  img_url <- paste0("https://kryeit.com/api/players/", username, "/head")
  img_tag <- tags$img(src = img_url, class = "dt-player-head", alt = username)
  return(as.character(tagList(img_tag, username)))
}

leaderboard_server <- function(input, output, session) {
  ns <- session$ns
  
  observeEvent(input$category, {
    req(input$category)
    
    sql <- "
      SELECT DISTINCT key as item, SPLIT_PART(key, ':', 2) as sort_key
      FROM users, jsonb_object_keys(stats->'stats'->$1) key
      WHERE stats->'stats'->$1 IS NOT NULL
      ORDER BY sort_key
    "
    items <- safe_query(sql, input$category)
    updateSelectizeInput(session, "identifier", choices = items$item, server = TRUE)
  }, priority = 10)
  
  player_stats <- reactive({
    req(input$category, input$identifier)
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
    result <- safe_query(sql, input$category, input$identifier)
    if (!is.null(result) && nrow(result) > 0) {
      result$count <- as.numeric(result$count)
      result
    } else {
      NULL
    }
  })
  
  output$plot <- renderPlot({
    df <- player_stats()
    req(df)
    ggplot(df, aes(x = count)) +
      geom_bar() +
      labs(x = "Stat value", y = "Frequency")
  })
  
  output$download_csv <- downloadHandler(
    filename = function() {
      paste0("leaderboard-", input$category, "-", input$identifier, "-", Sys.Date(), ".csv")
    },
    content = function(file) {
      df <- player_stats()
      req(df)
      df$rank <- seq_len(nrow(df))
      write.csv(df[, c("rank", "username", "count", "last_seen")], file, row.names = FALSE)
    }
  )
}

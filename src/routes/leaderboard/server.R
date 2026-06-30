source("api/gerente.R")
library(plotly)

DISPLAY_LIMIT <- 40L       # players shown in the chart
CSV_LIMIT     <- 100000L   # rows pulled for a CSV export

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0 || !nzchar(a)) b else a

# "minecraft:diamond_ore" -> "Diamond Ore"
format_identifier <- function(item) {
  name <- sub("^[^:]*:", "", item)
  name <- gsub("[._]", " ", name)
  gsub("(^|[[:space:]])([[:alpha:]])", "\\1\\U\\2", name, perl = TRUE)
}

# Named choices for the item dropdown: label is the item id alone, but keeps the
# "namespace:" prefix when the same item id appears under more than one namespace.
label_choices <- function(keys) {
  if (length(keys) == 0) return(character(0))
  items <- sub("^[^:]*:", "", keys)
  conflicted <- items %in% items[duplicated(items)]
  stats::setNames(keys, ifelse(conflicted, keys, items))
}

# Horizontal plotly bar chart of the top players. Player heads are web images
# placed at a fixed x (so they line up), kept square via sizing = "contain".
build_plotly <- function(df, label) {
  df <- utils::head(df, DISPLAY_LIMIT)
  df <- df[order(df$value), ]                      # largest ends up on top
  df$hover <- sprintf("<b>%s</b><br>%s", df$name, df$formattedValue)
  uuids <- as.character(df$uuid)
  df$name <- factor(df$name, levels = df$name)     # keep order on the y axis
  n <- nrow(df)

  heads <- lapply(seq_len(n), function(i) list(
    source = player_head_url(uuids[i]),
    xref = "paper", yref = "y", x = -0.012, y = i - 1,
    sizex = 0.07, sizey = 0.92, xanchor = "right", yanchor = "middle",
    sizing = "contain", layer = "above"
  ))

  plot_ly(df, x = ~value, y = ~name, type = "bar", orientation = "h",
          height = max(420, n * 26 + 130),
          marker = list(color = "#539b32"),
          hovertext = ~hover, hoverinfo = "text") %>%
    layout(
      title = list(text = label, x = 0, xanchor = "left", font = list(size = 16)),
      font = list(family = "Minecraftia, monospace", size = 12, color = "#0f172a"),
      margin = list(l = 60, r = 28, t = 56, b = 36),
      xaxis = list(title = "", zeroline = FALSE, gridcolor = "#eef2f6", fixedrange = TRUE),
      yaxis = list(title = "", showticklabels = FALSE, fixedrange = TRUE),
      images = heads, bargap = 0.3,
      paper_bgcolor = "white", plot_bgcolor = "white"
    ) %>%
    config(displaylogo = FALSE,
           modeBarButtonsToRemove = list("lasso2d", "select2d", "zoom2d",
                                         "pan2d", "zoomIn2d", "zoomOut2d", "autoScale2d"))
}

leaderboard_server <- function(input, output, session) {
  # Holds a link-restored item to select once its namespace's items load.
  pending_identifier <- reactiveVal(NULL)

  load_items <- function(cat, select = NULL) {
    if (is.null(cat) || !nzchar(cat)) return(invisible())
    keys <- fetch_keys(cat)
    sel <- if (!is.null(select) && select %in% keys) select else ""
    updateSelectizeInput(session, "identifier",
                         choices = label_choices(keys), selected = sel)
  }

  observeEvent(input$category, {
    req(input$category)
    pend <- isolate(pending_identifier())
    pending_identifier(NULL)
    load_items(input$category, pend)
  }, priority = 10)

  # Restore a selection shared via URL (?category=...&identifier=...), once.
  restored <- reactiveVal(FALSE)
  observe({
    if (restored()) return()
    q_cat <- get_query_param("category")
    q_id  <- get_query_param("identifier")
    if (is.null(q_cat) && is.null(q_id)) return()
    restored(TRUE)

    if (!is.null(q_cat) && q_cat %in% category_choices &&
        !identical(isolate(input$category), q_cat)) {
      pending_identifier(q_id)
      updateSelectizeInput(session, "category", selected = q_cat)
    } else if (!is.null(q_id)) {
      load_items(isolate(input$category), q_id)
    }
  })

  leaderboard_data <- reactive({
    req(input$category, input$identifier)
    fetch_leaderboard(namespace = input$category, key = input$identifier,
                      limit = DISPLAY_LIMIT)
  })

  stat_label <- reactive({
    req(input$category, input$identifier)
    cat_label <- names(category_choices)[match(input$category, category_choices)]
    paste0(cat_label, " / ", format_identifier(input$identifier))
  })

  output$plot <- renderPlotly({
    req(nzchar(input$identifier %||% ""))
    df <- leaderboard_data()
    req(df)
    build_plotly(df, stat_label())
  })

  # Buttons only render once there's data, so you can't trigger an empty export.
  output$actions <- renderUI({
    if (!nzchar(input$identifier %||% "")) return(NULL)
    if (is.null(leaderboard_data())) return(NULL)
    ns <- session$ns
    div(
      class = "flex gap-2",
      downloadButton(ns("download_csv"), "CSV", class = paste(
        "!inline-flex !items-center !justify-center !gap-2 !rounded-lg !px-3 !py-2 !flex-1",
        "!text-xs sm:!text-sm !font-semibold !text-slate-700 !bg-white !border",
        "!border-slate-300 hover:!bg-slate-50 !shadow-none !cursor-pointer")),
      tags$button(
        type = "button", onclick = "coucouShare(this)",
        class = paste(
          "inline-flex items-center justify-center gap-2 rounded-lg px-3 py-2 flex-1",
          "text-xs sm:text-sm font-semibold text-white bg-slate-800",
          "hover:bg-slate-900 cursor-pointer"),
        HTML(paste0(
          '<svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" ',
          'viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" ',
          'stroke-linecap="round" stroke-linejoin="round">',
          '<circle cx="18" cy="5" r="3"/><circle cx="6" cy="12" r="3"/>',
          '<circle cx="18" cy="19" r="3"/>',
          '<line x1="8.59" y1="13.51" x2="15.42" y2="17.49"/>',
          '<line x1="15.41" y1="6.51" x2="8.59" y2="10.49"/></svg>')),
        "Share"
      )
    )
  })

  output$download_csv <- downloadHandler(
    filename = function() {
      sprintf("leaderboard-%s-%s.csv",
              gsub("[^a-z0-9]+", "_", input$identifier %||% "stat"), Sys.Date())
    },
    content = function(file) {
      df <- if (isTRUE(nzchar(input$identifier)))
        fetch_leaderboard(input$category, input$identifier, limit = CSV_LIMIT) else NULL
      out <- if (is.null(df)) {
        data.frame(rank = integer(), name = character(),
                   value = numeric(), formatted = character())
      } else {
        data.frame(rank = seq_len(nrow(df)), name = df$name,
                   value = df$value, formatted = df$formattedValue)
      }
      write.csv(out, file, row.names = FALSE)
    }
  )
}

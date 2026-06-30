source("api/gerente.R")
library(plotly)

DISPLAY_LIMIT <- 40L       # players shown in the chart
PLOT_LIMIT    <- 25L       # bars in the downloadable PNG
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

# Horizontal plotly bar chart of the top players. Each bar shows the player's
# head + username at its start and the value at its end (no hover needed).
build_plotly <- function(df, label) {
  df <- utils::head(df, DISPLAY_LIMIT)
  df <- df[order(df$value), ]                      # largest ends up on top
  uuids <- as.character(df$uuid)
  usernames <- as.character(df$name)
  df$name <- factor(df$name, levels = df$name)     # keep order on the y axis
  n <- nrow(df)

  heads <- lapply(seq_len(n), function(i) list(
    source = player_head_url(uuids[i]),
    xref = "paper", yref = "y", x = 0.004, y = i - 1,
    sizex = 0.05, sizey = 0.86, xanchor = "left", yanchor = "middle",
    sizing = "contain", layer = "above"
  ))
  names_ann <- lapply(seq_len(n), function(i) list(
    xref = "paper", yref = "y", x = 0.058, y = i - 1,
    text = usernames[i], showarrow = FALSE, xanchor = "left", yanchor = "middle",
    font = list(family = "Minecraftia, monospace", size = 12, color = "#0f172a")
  ))

  plot_ly(df, x = ~value, y = ~name, type = "bar", orientation = "h",
          height = max(420, n * 28 + 130),
          marker = list(color = "#539b32"),
          text = ~formattedValue, textposition = "outside",
          textfont = list(size = 11, color = "#334155"),
          cliponaxis = FALSE, hoverinfo = "none") %>%
    layout(
      title = list(text = label, x = 0, xanchor = "left", font = list(size = 16)),
      font = list(family = "Minecraftia, monospace", size = 12, color = "#0f172a"),
      margin = list(l = 12, r = 64, t = 56, b = 24),
      xaxis = list(title = "", zeroline = FALSE, showgrid = FALSE,
                   showticklabels = FALSE, fixedrange = TRUE),
      yaxis = list(title = "", showticklabels = FALSE, fixedrange = TRUE),
      images = heads, annotations = names_ann, bargap = 0.3,
      hovermode = FALSE, paper_bgcolor = "white", plot_bgcolor = "white"
    ) %>%
    config(displayModeBar = FALSE)
}

# Plain bar chart for the downloadable PNG (base graphics, no extra deps).
build_plot <- function(df, label) {
  df <- utils::head(df, PLOT_LIMIT)
  df <- df[order(df$value), ]
  op <- par(mar = c(4, 9, 3, 4), font.main = 1, cex.main = 1.2)
  on.exit(par(op))
  bp <- barplot(df$value, names.arg = df$name, horiz = TRUE, las = 1,
                col = "#539b32", border = NA, main = label,
                cex.names = 0.85, xlim = c(0, max(df$value) * 1.13))
  text(df$value, bp, labels = df$formattedValue, pos = 4,
       cex = 0.8, col = "#334155", xpd = TRUE)
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
      downloadButton(ns("download_png"), "PNG", class = paste(
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

  output$download_png <- downloadHandler(
    filename = function() {
      sprintf("leaderboard-%s-%s.png",
              gsub("[^a-z0-9]+", "_", input$identifier %||% "stat"), Sys.Date())
    },
    content = function(file) {
      df <- leaderboard_data()
      req(df)
      png(file, width = 1000, height = 700, res = 120)
      on.exit(dev.off())
      build_plot(df, isolate(stat_label()))
    }
  )
}

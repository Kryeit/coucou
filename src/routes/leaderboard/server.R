source("api/gerente.R")

DISPLAY_LIMIT <- 20L       # bars shown in the chart
CSV_LIMIT     <- 100000L   # rows pulled for a CSV export

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0 || !nzchar(a)) b else a

# "minecraft:diamond_ore" -> "Diamond Ore"
format_identifier <- function(item) {
  name <- sub("^[^:]*:", "", item)
  name <- gsub("[._]", " ", name)
  gsub("(^|[[:space:]])([[:alpha:]])", "\\1\\U\\2", name, perl = TRUE)
}

# Named choices for the item dropdown: label is the item id alone, but keeps the
# "namespace:" prefix when the same item id appears under more than one namespace
# (e.g. minecraft:stone vs create:stone). Order is left untouched; values stay
# the full keys.
label_choices <- function(keys) {
  if (length(keys) == 0) return(character(0))
  items <- sub("^[^:]*:", "", keys)
  conflicted <- items %in% items[duplicated(items)]
  stats::setNames(keys, ifelse(conflicted, keys, items))
}

# Horizontal bar chart of the top players for a stat. Base graphics, no deps.
build_plot <- function(df, label) {
  df <- utils::head(df, DISPLAY_LIMIT)
  df <- df[order(df$value), ]                       # largest ends up on top
  op <- par(mar = c(4, 9, 3, 3), font.main = 1, cex.main = 1.2)
  on.exit(par(op))
  bp <- barplot(df$value, names.arg = df$name, horiz = TRUE, las = 1,
                col = "#539b32", border = NA, main = label,
                cex.names = 0.85, xlim = c(0, max(df$value) * 1.13))
  text(df$value, bp, labels = df$formattedValue, pos = 4,
       cex = 0.8, col = "#334155", xpd = TRUE)
  invisible(bp)
}

leaderboard_server <- function(input, output, session) {
  # Holds a link-restored item to select once its namespace's items load.
  pending_identifier <- reactiveVal(NULL)

  # Fetch a namespace's keys into the item dropdown. Pass select = NULL to
  # leave nothing pre-selected (empty string clears the selectize).
  load_items <- function(cat, select = NULL) {
    if (is.null(cat) || !nzchar(cat)) return(invisible())
    keys <- fetch_keys(cat)
    sel <- if (!is.null(select) && select %in% keys) select else ""
    updateSelectizeInput(session, "identifier",
                         choices = label_choices(keys), selected = sel)
  }

  # Repopulate items whenever the namespace changes (no pre-selection).
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

  output$plot <- renderPlot({
    req(nzchar(input$identifier %||% ""))
    df <- leaderboard_data()
    req(df)
    build_plot(df, stat_label())
  })

  # Buttons only render once there's data, so you can't trigger an empty export.
  output$actions <- renderUI({
    if (!nzchar(input$identifier %||% "")) return(NULL)
    if (is.null(leaderboard_data())) return(NULL)
    ns <- session$ns
    outline <- paste(
      "!inline-flex !items-center !justify-center !rounded-lg !px-3 !py-2 !flex-1",
      "!text-xs sm:!text-sm !font-semibold !text-slate-700 !bg-white !border",
      "!border-slate-300 hover:!bg-slate-50 !shadow-none !cursor-pointer"
    )
    div(
      class = "flex gap-2",
      downloadButton(ns("download_csv"), "CSV", class = outline),
      downloadButton(ns("download_png"), "PNG", class = outline),
      tags$button(
        "Copy link", type = "button", onclick = "coucouCopyLink(this)",
        class = paste(
          "inline-flex items-center justify-center rounded-lg px-3 py-2 flex-1",
          "text-xs sm:text-sm font-semibold text-white bg-slate-800",
          "hover:bg-slate-900 cursor-pointer"
        )
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

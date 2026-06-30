source("api/gerente.R")

DISPLAY_LIMIT <- 100L      # rows shown in the UI
CSV_LIMIT     <- 100000L   # rows pulled for a CSV export

# ---- small presentation helpers ----------------------------------------- #

fmt_num <- function(x) formatC(x, format = "f", big.mark = ",", digits = 0)

# "minecraft:diamond_ore" -> "Diamond Ore"
format_identifier <- function(item) {
  name <- sub("^[^:]*:", "", item)
  name <- gsub("[._]", " ", name)
  gsub("(^|[[:space:]])([[:alpha:]])", "\\1\\U\\2", name, perl = TRUE)
}

# Prefer the backend's formatted value when it carries a unit (e.g. "123 h",
# "4.2 km"); otherwise show the raw number with thousands separators.
display_value <- function(value, formatted) {
  if (length(formatted) && !is.na(formatted) && grepl("[A-Za-z]", formatted)) formatted
  else fmt_num(value)
}

rank_class <- function(rank) {
  if (rank == 1) "text-amber-500"
  else if (rank == 2) "text-slate-400"
  else if (rank == 3) "text-amber-700"
  else "text-slate-400"
}

bar_class <- function(rank) {
  if (rank == 1) "bg-amber-400"
  else if (rank == 2) "bg-slate-300"
  else if (rank == 3) "bg-amber-600"
  else "bg-grass-400"
}

lb_placeholder <- function(msg) {
  div(
    class = "flex items-center justify-center text-center py-16 px-6",
    p(class = "text-slate-500", msg)
  )
}

lb_row <- function(rank, username, uuid, value, display, max_count) {
  pct <- if (max_count > 0) max(2, value / max_count * 100) else 2
  div(
    class = "flex items-center gap-3 px-2 sm:px-3 py-2 rounded-xl hover:bg-slate-50 transition-colors",
    div(class = paste("w-7 shrink-0 text-center font-mc text-sm", rank_class(rank)), rank),
    img(
      class = "player-head w-9 h-9 rounded-md ring-1 ring-slate-200 bg-slate-100 shrink-0",
      src = player_head_url(uuid), loading = "lazy", alt = username
    ),
    div(
      class = "flex-1 min-w-0",
      div(
        class = "flex items-baseline justify-between gap-3",
        span(class = "font-medium text-slate-800 truncate", username),
        span(class = "font-mc text-sm text-slate-900 tabular-nums shrink-0", display)
      ),
      div(
        class = "mt-1.5 h-1.5 w-full rounded-full bg-slate-100 overflow-hidden",
        div(class = paste("h-full rounded-full", bar_class(rank)),
            style = sprintf("width:%.1f%%;", pct))
      )
    )
  )
}

# ---- module server ------------------------------------------------------- #

leaderboard_server <- function(input, output, session) {
  # Holds a link-restored item to select once its namespace's items load.
  pending_identifier <- reactiveVal(NULL)

  # Fetch a namespace's keys into the item dropdown, optionally preselecting one.
  load_items <- function(cat, select = NULL) {
    if (is.null(cat) || !nzchar(cat)) return(invisible())
    choices <- fetch_keys(cat)
    sel <- if (!is.null(select) && select %in% choices) select else NULL
    updateSelectizeInput(session, "identifier",
                         choices = choices, selected = sel, server = TRUE)
  }

  # Repopulate items whenever the namespace changes, applying any pending item.
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
      # Namespace will change; its observer loads items and applies this id.
      pending_identifier(q_id)
      updateSelectizeInput(session, "category", selected = q_cat)
    } else if (!is.null(q_id)) {
      # Namespace already correct (e.g. the default) -> load + select now.
      load_items(isolate(input$category), q_id)
    }
  })

  # Ranked result for the current selection (top DISPLAY_LIMIT).
  leaderboard_data <- reactive({
    req(input$category, input$identifier)
    fetch_leaderboard(
      namespace = input$category,
      key       = input$identifier,
      limit     = DISPLAY_LIMIT
    )
  })

  output$leaderboard <- renderUI({
    if (is.null(input$identifier) || !nzchar(input$identifier)) {
      return(NULL)
    }
    df <- leaderboard_data()
    if (is.null(df)) {
      return(lb_placeholder("No players have recorded this stat yet."))
    }

    n <- nrow(df)
    max_count <- max(df$value, na.rm = TRUE)

    cat_label  <- names(category_choices)[match(input$category, category_choices)]
    stat_label <- paste0(cat_label, " / ", format_identifier(input$identifier))

    rows <- lapply(seq_len(n), function(i) {
      lb_row(
        rank = i,
        username = df$name[i],
        uuid = df$uuid[i],
        value = df$value[i],
        display = display_value(df$value[i], df$formattedValue[i]),
        max_count = max_count
      )
    })

    tagList(
      div(
        class = "flex items-center justify-between gap-3 px-2 sm:px-3 pb-3",
        div(class = "text-sm font-semibold text-slate-700 truncate", stat_label),
        div(class = "text-xs text-slate-400 shrink-0",
            if (n >= DISPLAY_LIMIT) sprintf("top %d", DISPLAY_LIMIT)
            else sprintf("%s players", fmt_num(n)))
      ),
      div(class = "space-y-0.5", rows)
    )
  })

  # Action buttons render only once there's data, so you can't trigger an empty
  # CSV / PNG / share link (which previously returned an error page).
  output$actions <- renderUI({
    if (!nzchar(input$identifier %||% "")) return(NULL)
    if (is.null(leaderboard_data())) return(NULL)
    ns <- session$ns
    outline <- paste(
      "!inline-flex !items-center !justify-center !rounded-lg !px-3 !py-2 !flex-1",
      "!text-sm !font-semibold !text-slate-700 !bg-white !border !border-slate-300",
      "hover:!bg-slate-50 !shadow-none !cursor-pointer"
    )
    div(
      class = "flex gap-2",
      downloadButton(ns("download_csv"), "CSV", class = outline),
      tags$button("PNG", type = "button", onclick = "coucouDownloadPng()", class = outline),
      actionButton(
        ns("copy_link"), "Copy",
        class = paste(
          "!inline-flex !items-center !justify-center !rounded-lg !px-3 !py-2 !flex-1",
          "!text-sm !font-semibold !text-white !bg-slate-800 hover:!bg-slate-900",
          "!border-0 !shadow-none"
        )
      )
    )
  })

  output$download_csv <- downloadHandler(
    filename = function() {
      sprintf("leaderboard-%s-%s.csv",
              gsub("[^a-z0-9]+", "_", input$identifier %||% "stat"),
              Sys.Date())
    },
    content = function(file) {
      df <- if (isTRUE(nzchar(input$identifier)))
        fetch_leaderboard(input$category, input$identifier, limit = CSV_LIMIT) else NULL
      out <- if (is.null(df)) {
        data.frame(rank = integer(), name = character(), uuid = character(),
                   value = numeric(), formatted = character())
      } else {
        data.frame(rank = seq_len(nrow(df)), name = df$name, uuid = df$uuid,
                   value = df$value, formatted = df$formattedValue)
      }
      write.csv(out, file, row.names = FALSE)
    }
  )

  observeEvent(input$copy_link, {
    req(input$category, input$identifier)
    q <- sprintf(
      "category=%s&identifier=%s",
      utils::URLencode(input$category, reserved = TRUE),
      utils::URLencode(input$identifier, reserved = TRUE)
    )
    session$sendCustomMessage("copy_share_link", q)
    showNotification("Link copied to clipboard", duration = 2, type = "message")
  })
}

`%||%` <- function(a, b) if (is.null(a) || length(a) == 0 || !nzchar(a)) b else a

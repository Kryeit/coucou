header_ui <- function() {
  tags$header(
    class = paste(
      "sticky top-0 z-30 w-full bg-white/90 backdrop-blur",
      "border-b border-slate-200 shadow-sm"
    ),
    div(
      class = "w-full max-w-5xl mx-auto px-4 sm:px-6 flex items-center gap-4 h-20",
      a(
        href = route_link("/"),
        class = "shrink-0 flex items-center gap-3",
        img(
          src = "assets/icon.png",
          class = "h-10 w-10 pixelated",
          alt = "Coucou"
        ),
        span(class = "font-mc text-2xl text-slate-900", "COUCOU")
      ),
      tags$nav(
        class = "ml-auto flex items-center gap-1 sm:gap-2",
        uiOutput("main_nav", inline = TRUE),
        a(
          href = "https://ko-fi.com/kryeit",
          target = "_blank", rel = "noopener",
          class = paste(
            "ml-1 sm:ml-2 inline-flex items-center rounded-lg px-3 py-2",
            "text-sm font-semibold text-white bg-grass-500 hover:bg-grass-600",
            "transition-colors"
          ),
          "Donate"
        )
      )
    )
  )
}

header_server <- function(input, output, session) {
  nav_items <- list(
    list(route = "/",           label = "Home"),
    list(route = "leaderboard", label = "Leaderboard")
  )

  output$main_nav <- renderUI({
    current <- get_page()
    if (current == "") current <- "/"

    links <- lapply(nav_items, function(item) {
      active <- current == item$route
      a(
        href = route_link(item$route),
        class = paste(
          "inline-flex items-center rounded-lg px-3 py-2 text-sm font-medium transition-colors",
          if (active) "bg-grass-50 text-grass-700" else "text-slate-600 hover:bg-slate-100 hover:text-slate-900"
        ),
        item$label
      )
    })
    div(class = "flex items-center gap-1 sm:gap-2", links)
  })
}

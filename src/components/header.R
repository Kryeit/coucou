header_ui <- function() {
  fluidPage(
    a(
      href = route_link("/"),
      img(src = "assets/banner.png", alt = "Kryeit Banner", style = "height: 100px; image-rendering: pixelated;")
    ),
    tabsetPanel(
      type = "tabs",
      navbarMenu("Graphs",
        tabPanel(a(href = route_link("/onlines"), "Onlines"), value = "onlines"),
        tabPanel(a(href = route_link("/leaderboard"), "Leaderboard"), value = "leaderboard")
      ),
      tabPanel(
        type = "hidden",
        a(href = route_link("/onlines"), "Onlines", class = "h-full")
      )
    ),
    div(class = "mb-8")
  )
}

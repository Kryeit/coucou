header_ui <- function() {
  fluidPage(
    # Clickable image that routes to home
    a(href = route_link("/"),
      img(src = "assets/banner.png", alt = "Kryeit Banner")
    ),
    
    # TabsetPanel at the bottom
    tabsetPanel(
      navbarMenu("Graphs",
                 tabPanel("1"),
                 tabPanel("2")
      )
    )
  )
}
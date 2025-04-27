home_ui <- function() {
  fluidPage(
    div(class = "banner-container",
        a(href = route_link("/"),
          img(src = "assets/banner.png", class = "banner-image", alt = "Kryeit Banner")
        )
    ),
    a(href = route_link("/leaderboard"), "Leaderboard", class = "link"),
    a(href = route_link("/onlines"), "Onlines", class = "link"),
  )
}

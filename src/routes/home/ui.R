home_ui <- function() {
  fluidPage(
    div(class = "banner-container",
        a(href = "#/",
          img(src = "assets/banner.png", class = "banner-image", alt = "Kryeit Banner")
        )
    ),
    a(href = "#/leaderboard", "Leaderboard", class = "link"),
    a(href = "#/onlines", "Onlines", class = "link"),
  )
}

home_ui <- function() {
  fluidPage(
    div(class = "banner-container",
        a(href = "https://coucou.kryeit.com",
          img(src = "assets/banner.png", class = "banner-image", alt = "Kryeit Banner")
        )
    ),
    a(href = "https://coucou.kryeit.com/#/leaderboard", "Leaderboard", class = "link"),
    a(href = "https://coucou.kryeit.com/#/onlines", "Onlines", class = "link"),
  )
}
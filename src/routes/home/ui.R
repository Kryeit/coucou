home_ui <- function() {
  div(
    class = "flex flex-col items-center text-center py-12 sm:py-20",
    img(
      src = "assets/icon.png",
      class = "h-20 w-20 pixelated mb-6",
      alt = "Kryeit"
    ),
    h1(
      class = "font-mc text-3xl sm:text-5xl text-slate-900 mb-4 leading-tight",
      "Kryeit Statistics"
    ),
    p(
      class = "max-w-xl text-base sm:text-lg text-slate-600 mb-2",
      "Live leaderboards built from every player's in-game stats."
    ),
    p(
      class = "max-w-xl text-sm text-slate-500 mb-8",
      "Pick a category and an item to see who's on top. ",
      "Want out? Reach out via email and we'll remove you."
    ),
    a(
      href = route_link("leaderboard"),
      class = paste(
        "inline-flex items-center gap-2 rounded-xl px-6 py-3",
        "bg-grass-500 hover:bg-grass-600 text-white font-semibold",
        "shadow-card transition-colors"
      ),
      "View the leaderboard",
      tags$span(class = "text-lg leading-none", HTML("&rarr;"))
    )
  )
}

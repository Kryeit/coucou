home_ui <- function() {
  div(
    class = "flex flex-col items-center text-center py-12 sm:py-20",
    img(
      src = "assets/icon.png",
      class = "h-20 w-20 pixelated mb-6",
      alt = "Kryeit"
    ),
    h1(
      class = "font-mc text-3xl sm:text-5xl text-slate-900 mb-8 leading-tight",
      "Kryeit Statistics"
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

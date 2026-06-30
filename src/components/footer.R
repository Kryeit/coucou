footer_ui <- function() {
  tags$footer(
    class = "w-full border-t border-slate-200 bg-white",
    div(
      class = paste(
        "w-full max-w-5xl mx-auto px-4 sm:px-6 py-6",
        "flex flex-col sm:flex-row items-center justify-between gap-2",
        "text-sm text-slate-500"
      ),
      span("Kryeit"),
      tags$nav(
        class = "flex items-center gap-4",
        a(href = "https://kryeit.com/about", target = "_blank", rel = "noopener",
          class = "hover:text-slate-900 transition-colors", "About us"),
        a(href = "https://ko-fi.com/kryeit", target = "_blank", rel = "noopener",
          class = "hover:text-grass-600 transition-colors", "Donate")
      )
    )
  )
}

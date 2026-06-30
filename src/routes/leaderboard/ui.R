category_choices <- c(
  "Custom"        = "minecraft:custom",
  "Items Used"    = "minecraft:used",
  "Items Broken"  = "minecraft:broken",
  "Items Crafted" = "minecraft:crafted",
  "Items Mined"   = "minecraft:mined",
  "Mob Kills"     = "minecraft:killed",
  "Deaths"        = "minecraft:killed_by"
)

leaderboard_ui <- function(id) {
  ns <- NS(id)

  div(
    # Small client-side clipboard helper for the "Copy link" button.
    tags$script(HTML(paste(
      "Shiny.addCustomMessageHandler('copy_share_link', function(q){",
      "  var base = window.location.origin + window.location.pathname;",
      "  var url = base + '#!/leaderboard?' + q;",
      "  if (navigator.clipboard) { navigator.clipboard.writeText(url); }",
      "});",
      sep = "\n"
    ))),

    div(
      class = "rounded-2xl bg-white shadow-card border border-slate-200 overflow-hidden",

      # Header
      div(
        class = "px-5 sm:px-6 pt-5 pb-4 border-b border-slate-100",
        h1(class = "font-mc text-2xl text-slate-900", "Leaderboard"),
        p(class = "mt-1 text-sm text-slate-500",
          "Rank every player by a single Minecraft statistic.")
      ),

      # Controls
      div(
        class = "px-5 sm:px-6 py-4 grid grid-cols-1 sm:grid-cols-12 gap-4 items-end bg-slate-50/60",
        div(
          class = "sm:col-span-4",
          selectInput(ns("category"), "Category", choices = category_choices, width = "100%")
        ),
        div(
          class = "sm:col-span-5",
          selectizeInput(
            ns("identifier"), "Item", choices = NULL, width = "100%",
            options = list(placeholder = "Select an item", maxOptions = 1000)
          )
        ),
        div(
          class = "sm:col-span-3 flex gap-2",
          downloadButton(
            ns("download_csv"), "CSV",
            class = paste(
              "!inline-flex !items-center !justify-center !gap-2 !rounded-lg !px-3 !py-2",
              "!text-sm !font-semibold !text-slate-700 !bg-white !border !border-slate-300",
              "hover:!bg-slate-50 !shadow-none !flex-1"
            )
          ),
          actionButton(
            ns("copy_link"), "Copy link",
            class = paste(
              "!inline-flex !items-center !justify-center !gap-2 !rounded-lg !px-3 !py-2",
              "!text-sm !font-semibold !text-white !bg-slate-800 hover:!bg-slate-900",
              "!border-0 !shadow-none !flex-1"
            )
          )
        )
      ),

      # Results
      div(
        class = "px-3 sm:px-4 py-4",
        uiOutput(ns("leaderboard"))
      )
    )
  )
}

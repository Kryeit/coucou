category_choices <- c(
  "Custom" = "minecraft:custom", 
  "Items Used" = "minecraft:used",
  "Items Broken" = "minecraft:broken",
  "Items Crafted" = "minecraft:crafted",
  "Items Mined" = "minecraft:mined",
  "Mob Kills" = "minecraft:killed",
  "Deaths" = "minecraft:killed_by"
)

leaderboard_ui <- function(id) {
  ns <- NS(id)
  
  fluidPage(
    h1("Minecraft stats JSON"),
    fluidRow(
      column(4,
             selectInput(ns("category"), "Category:", choices = category_choices)
      ),
      column(4,
             selectizeInput(ns("identifier"), "Identifier:", choices = NULL, 
                            options = list(placeholder = 'Select an item', maxOptions = 10000))
      ),
      column(2),
      column(2,
             div(
               downloadButton(ns("download_csv"), ""),
               actionButton(ns("copy_link"), "", icon = icon("share-alt"))
             )
      )
    ),
    plotOutput("plot")
  )
}

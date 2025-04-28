stat_type_choices <- c(
  "Custom" = "minecraft:custom", 
  "Items Used" = "minecraft:used",
  "Items Broken" = "minecraft:broken",
  "Items Crafted" = "minecraft:crafted",
  "Items Mined" = "minecraft:mined",
  "Mob Kills" = "minecraft:killed",
  "Deaths" = "minecraft:killed_by"
)

leaderboard_ui <- function() {
  ns <- NS("leaderboard_module")
  
  fluidPage(
    fluidRow(
      column(12,
             selectInput(ns("stat_type"), "Leaderboards:", choices = stat_type_choices),
             selectizeInput(ns("item_filter"), "Item:", choices = NULL, 
                            options = list(placeholder = 'Select an item', maxOptions = 10000)),
             downloadButton(ns("download_csv"), "Download CSV"),
             actionButton(ns("copy_share_link"), "Share", icon = icon("share-alt"))
      )
    ),
    fluidRow(
      column(12,
             DT::dataTableOutput(ns("leaderboard_table"))
      )
    )
  )
}

library(shiny)
library(DT)

leaderboard_ui <- function(id) {
  ns <- NS(id)
  
  fluidPage(
    tags$head(
      tags$style(HTML("
        .well { background-color: #f8f9fa; border: 1px solid #e9ecef; }
        .control-label { font-weight: 400; color: #495057; }
        h3 { margin-top: 30px; font-weight: 600; color: #212529; }
        .selectize-input { border: 1px solid #ced4da; }
        
        /* Chart container styling */
        .chart-container {
          margin-top: 20px;
          position: relative;
          overflow-y: auto;
          max-height: 500px;
          background: white;
          border-radius: 4px;
          box-shadow: 0 1px 3px rgba(0,0,0,0.1);
          padding: 10px;
        }
        
        /* Custom bar chart styling */
        .bar-container {
          display: flex;
          align-items: center;
          margin-bottom: 8px;
          position: relative;
        }
        
        .player-head {
          width: 24px;
          height: 24px;
          margin-right: 10px;
          border-radius: 3px;
          box-shadow: 0 1px 2px rgba(0,0,0,0.2);
        }
        
        .bar {
          background-color: #2196F3;
          height: 26px;
          border-radius: 3px;
          transition: width 0.5s ease;
          position: relative;
          min-width: 50px; /* Ensure minimum width for the label */
          display: flex;
          align-items: center;
          justify-content: flex-end;
        }
        
        .bar-label {
          padding-right: 8px;
          color: white;
          font-weight: bold;
          text-shadow: 0px 0px 2px rgba(0,0,0,0.5);
          white-space: nowrap;
        }
        
        .chart-header {
          font-size: 18px;
          font-weight: bold;
          color: #444;
          margin-bottom: 20px;
          text-align: center;
        }
        
        /* Player head styling for data table */
        .dt-player-head {
          width: 16px;
          height: 16px;
          margin-right: 5px;
          vertical-align: middle;
          border-radius: 2px;
        }
      "))
    ),
    
    titlePanel("Leaderboards portal"),
    
    fluidRow(
      column(3,
             wellPanel(
               # Stat type selection
               selectInput(ns("stat_type"), "Leaderboards:", 
                           choices = c(
                             "Items Used" = "minecraft:used",
                             "Items Broken" = "minecraft:broken",
                             "Items Crafted" = "minecraft:crafted",
                             "Items Mined" = "minecraft:mined",
                             "Mob Kills" = "minecraft:killed",
                             "Deaths" = "minecraft:killed_by",
                             "Custom" = "minecraft:custom"
                           )),
               
               # Item selection (required)
               selectInput(ns("item_filter"), "Item:", 
                           choices = NULL),
               
               # Player limit
               sliderInput(ns("limit"), "Players to Show:", 
                           min = 5, max = 30, value = 10, step = 5),
               
               # Min value filter to clean up data
               sliderInput(ns("min_value"), "Minimum Value:", 
                           min = 1, max = 100, value = 1)
             )
      ),
      
      column(9,
             # Custom chart container
             div(class = "chart-container",
                 div(id = ns("chart_header"), class = "chart-header"),
                 div(id = ns("custom_chart"))
             ),
             
             br(),
             h3("Leaderboard"),
             DT::dataTableOutput(ns("leaderboard_table"))
      )
    )
  )
}
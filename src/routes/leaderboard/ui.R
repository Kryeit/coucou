library(shiny)
library(DT)

leaderboard_ui <- function(id) {
  ns <- NS(id)
  
  fluidPage(
    tags$head(
      tags$style(HTML("
.well { background-color: #f8f9fa; border: 1px solid #e9ecef; }
.control-label { font-weight: 400; color: #495057; }
.selectize-input { border: 1px solid #ced4da; }

.leaderboard-selectors {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-top: 15px;
  margin-bottom: 15px;
  width: 100%;
}

.selector-container {
  flex: 1;
  max-width: 250px;
}

.selector-container .control-label {
  display: none;
}

.spacer {
  flex-grow: 1;
}

.download-btn {
  margin-top: -15px;
  padding: 8px 10px;
  border-radius: 4px;
  cursor: pointer;
}

.chart-container {
  margin-top: 20px;
  position: relative;
  background: white;
  border-radius: 4px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
  padding: 10px;
  overflow: visible !important;
  height: auto !important;
  max-height: none !important;
}
              
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
  min-width: 50px;
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
              
.dt-player-head {
  width: 16px;
  height: 16px;
  margin-right: 5px;
  vertical-align: middle;
  border-radius: 2px;
}
              
.entries-count {
  font-size: 14px;
  font-weight: normal;
  color: #6c757d;
}

.arrow {
  display: inline-block;
  margin-right: 10px;
  transition: transform 0.3s ease;
}

.rotated {
  transform: rotate(90deg);
}

.collapsible-header {
  background-color: #f8f9fa;
  cursor: pointer;
  padding: 10px 15px;
  width: 100%;
  text-align: left;
  font-size: 16px;
  font-weight: bold;
  border-radius: 4px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
  margin-top: 20px;
  margin-bottom: 10px;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.collapsible-header:hover {
  background-color: #e9ecef;
}

.collapsible-content {
  padding: 0;
  max-height: 0;
  overflow: hidden;
  transition: max-height 0.3s ease-out;
}
      "))
    ),
    
    tags$script(HTML("
$(document).ready(function() {
  $(document).on('click', '.collapsible-header', function() {
    var content = $(this).next('.collapsible-content');
    var arrow = $(this).find('.arrow');
    
    if (content.css('max-height') === '0px') {
      content.css('max-height', '2000px');
      arrow.addClass('rotated');
    } else {
      content.css('max-height', '0px');
      arrow.removeClass('rotated');
    }
  });
});
")),
    
    fluidRow(
      column(12,
             div(
               class = "leaderboard-selectors",
               div(
                 class = "selector-container",
                 selectInput(ns("stat_type"), "Leaderboards:", 
                             choices = c(
                               "Items Used" = "minecraft:used",
                               "Items Broken" = "minecraft:broken",
                               "Items Crafted" = "minecraft:crafted",
                               "Items Mined" = "minecraft:mined",
                               "Mob Kills" = "minecraft:killed",
                               "Deaths" = "minecraft:killed_by",
                               "Custom" = "minecraft:custom"
                             ))
               ),
               
               div(
                 class = "selector-container",
                 selectizeInput(ns("item_filter"), "Item:", 
                                choices = NULL,
                                options = list(
                                  placeholder = 'Select an item',
                                  onInitialize = I('function() { this.setValue(""); }'),
                                  closeAfterSelect = TRUE,
                                  selectOnTab = TRUE,
                                  maxOptions = 10000,
                                  render = I('{
                                   option: function(item, escape) {
                                     return "<div>" + escape(item.label) + "</div>";
                                   }
                                 }')
                                ))
               ),
               
               div(class = "spacer"),
               
               downloadButton(ns("download_csv"), "Download CSV", class = "download-btn")
             )
      )
    ),
    fluidRow(
      column(12,
             div(class = "chart-container",
                 div(id = ns("custom_chart"))
             ),
             
             div(class = "collapsible-header", id = ns("leaderboard_toggle"),
                 div(
                   tags$span(class = "arrow", ">"),
                   "Leaderboard"
                 ),
                 div(id = ns("entries_count"), class = "entries-count")
             ),
             div(class = "collapsible-content", id = ns("leaderboard_content"),
                 DT::dataTableOutput(ns("leaderboard_table"))
             )
      )
    )
  )
}
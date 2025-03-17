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
              
.chart-header {
  font-size: 18px;
  font-weight: bold;
  color: #444;
  margin-bottom: 20px;
  text-align: center;
}
              
.dt-player-head {
  width: 16px;
  height: 16px;
  margin-right: 5px;
  vertical-align: middle;
  border-radius: 2px;
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

.entries-count {
  font-size: 14px;
  font-weight: normal;
  color: #6c757d;
}
              "))
    ),
    
    tags$script(HTML("
$(document).ready(function() {
  $(document).on('click', '.collapsible-header', function() {
    var content = $(this).next('.collapsible-content');
    var arrow = $(this).find('.arrow');
    
    if (content.css('max-height') === '0px' || content.css('max-height') === 'none') {
      content.css('max-height', '2000px');
      arrow.addClass('rotated');
    } else {
      content.css('max-height', '0px');
      arrow.removeClass('rotated');
    }
  });
});
")),
    
    titlePanel("Leaderboards portal"),
    
    fluidRow(
      column(3,
             wellPanel(
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
             )
      ),
      
      column(9,
             div(class = "chart-container",
                 div(id = ns("chart_header"), class = "chart-header"),
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
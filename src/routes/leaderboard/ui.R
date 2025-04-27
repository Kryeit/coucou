library(shiny)
library(DT)

leaderboard_ui <- function() {
  ns <- NS("leaderboard_module")
  
  fluidPage(
    tags$style(HTML("
.well { background-color: #f8f9fa; border: 1px solid #e9ecef; }
.control-label { font-weight: 400; color: #495057; }
.selectize-input { border: 1px solid #ced4da; }


")),
    
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
  
  // Register message handler for updating URL
  Shiny.addCustomMessageHandler('updateUrl', function(message) {
    if (window.updateLeaderboardUrl) {
      window.updateLeaderboardUrl(message.stat_type, message.item_filter);
    }
  });
  
  // Share button click handler
  $(document).on('click', '#leaderboard_module-copy_share_link', function() {
    var currentUrl = window.location.origin + window.location.pathname + window.location.hash;
    navigator.clipboard.writeText(currentUrl).then(function() {
      $('#leaderboard_module-copy_share_link').html('<i class=\"fa fa-check\"></i>');
      setTimeout(function() {
        $('#leaderboard_module-copy_share_link').html('<i class=\"fa fa-share-alt\"></i>');
      }, 2000);
    });
  });
}); 
")),
    
    div(class = "banner-container",
        a(href = "https://coucou.kryeit.com",
          img(src = "assets/banner.png", class = "banner-image", alt = "Kryeit Banner")
        )
    ),
    
    fluidRow(
      column(12,
             div(
               class = "leaderboard-selectors",
               div(
                 class = "selector-container",
                 selectInput(ns("stat_type"), "Leaderboards:", 
                             choices = c(
                               "Custom" = "minecraft:custom", 
                               "Items Used" = "minecraft:used",
                               "Items Broken" = "minecraft:broken",
                               "Items Crafted" = "minecraft:crafted",
                               "Items Mined" = "minecraft:mined",
                               "Mob Kills" = "minecraft:killed",
                               "Deaths" = "minecraft:killed_by"
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
               
               div(class = "actions-group",
                   a(href = "https://ko-fi.com/kryeit", "Donation Link", class = "link", target = "_blank", style="margin-top: -3px;"),
                   
                   downloadButton(ns("download_csv"), "Download CSV", class = "download-btn"),
                   
                   actionButton(
                     ns("copy_share_link"), 
                     "",
                     icon = icon("share-alt"),
                     class = "share-btn"
                   )
               )
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
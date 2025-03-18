library(plotly)
library(dplyr)

# Improved helper function for formatting item names to handle any mod
format_item_name <- function(item) {
  # Extract part after the colon (mod name)
  parts <- strsplit(item, ":")[[1]]
  if (length(parts) > 1) {
    name <- parts[2]  # Take everything after the first colon
  } else {
    name <- item  # No colon found, use as is
  }
  
  # Format name: replace underscores with spaces and capitalize first letter of each word
  name <- gsub("_", " ", name)
  name <- gsub("(^|[[:space:]])([[:alpha:]])", "\\1\\U\\2", name, perl = TRUE)
  return(name)
}

# Create a bar chart with player heads
create_bar_chart <- function(data, stat_type, item) {
  formatted_name <- format_item_name(item)
  stat_name <- switch(stat_type,
                      "minecraft:used" = "Items Used",
                      "minecraft:broken" = "Items Broken", 
                      "minecraft:crafted" = "Items Crafted",
                      "minecraft:mined" = "Items Mined",
                      "minecraft:killed" = "Mob Kills",
                      "minecraft:killed_by" = "Deaths By",
                      "minecraft:custom" = "Custom Stats",
                      "Unknown")
  
  # Sort data by count (descending)
  data <- data %>% arrange(desc(count))
  
  # Calculate statistics
  avg_value <- mean(data$count)
  
  # Calculate total plot height 
  n_players <- nrow(data)
  
  # Create plot with data values
  p <- plot_ly(
    data = data,
    x = ~count,
    y = ~seq_len(n_players),
    type = 'bar',
    orientation = 'h',
    marker = list(
      color = '#2196F3',
      line = list(color = 'rgba(0,0,0,0.1)', width = 1)
    ),
    text = ~paste(username),  # Only for hover text, not displayed on bars
    textposition = "none",    # Do not show text on bars
    hovertemplate = paste(
      "<b>%{text}</b><br>",
      "Count: %{x}<br>",
      "Average: ", round(avg_value, 1),
      "<extra></extra>"
    ),
    showlegend = FALSE
  ) %>% layout(
    title = "",  # Remove title
    height = n_players * 40 + 100,  # Dynamic height calculation
    yaxis = list(
      title = "",
      tickmode = "array",
      tickvals = seq_len(n_players),
      ticktext = rep("", n_players),  # Empty tick labels
      showgrid = FALSE,
      range = c(0.5, n_players + 0.5),
      fixedrange = TRUE
    ),
    xaxis = list(
      title = "Count",
      showgrid = TRUE,
      gridcolor = 'rgba(0,0,0,0.1)',
      zeroline = TRUE,
      zerolinecolor = 'rgba(0,0,0,0.1)',
      fixedrange = TRUE
    ),
    plot_bgcolor = '#FFFFFF',
    paper_bgcolor = '#FFFFFF',
    margin = list(l = 80, r = 30, b = 50, t = 30, pad = 4),
    dragmode = FALSE
  )
  
  # Add player head images as axis labels on the left
  for (i in 1:n_players) {
    username <- data$username[i]
    img_url <- paste0("https://kryeit.com/api/players/", username, "/head")
    
    p <- p %>% add_annotations(
      x = 0,
      y = i,
      xref = "x",
      yref = "y",
      xanchor = "right",
      yanchor = "middle",
      xshift = -35,
      text = "<b> </b>",  # Empty text but with bold to ensure visibility
      showarrow = FALSE,
      font = list(size = 12, color = "rgba(0,0,0,0)"),
      bgcolor = paste0("url(", img_url, ")"),  # Use background image
      borderwidth = 0,
      borderpad = 0,
      width = 24,
      height = 24,
      opacity = 1,
      hovertext = username
    )
  }
  
  # Remove all config options related to scrolling
  p <- p %>% layout(
    config = list(
      displayModeBar = FALSE,
      staticPlot = TRUE  # Ensures no interaction and full visibility
    )
  )
  
  return(p)
}

# Use the same function for all visualization tabs
create_distribution_plot <- function(data, stat_type, item) {
  return(create_bar_chart(data, stat_type, item))
}

create_histogram <- function(data, stat_type, item) {
  return(create_bar_chart(data, stat_type, item))
}

create_pretty_visualization <- function(data, stat_type, item) {
  return(create_bar_chart(data, stat_type, item))
}
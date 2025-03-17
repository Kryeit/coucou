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
  
  # Set fixed height per bar
  bar_height <- 0.7
  bar_spacing <- 1.0
  
  # Calculate total plot height needed
  n_players <- nrow(data)
  plot_height <- min(n_players * 40 + 150, 500)
  
  # Create a blank placeholder first to establish axes
  p <- plot_ly(height = plot_height) %>%
    # Add invisible scatter points for setting the axes properly
    add_trace(
      x = c(0, max(data$count) * 1.1),
      y = c(0.5, n_players + 0.5),
      type = "scatter",
      mode = "markers",
      marker = list(color = "rgba(0,0,0,0)"),
      hoverinfo = "none",
      showlegend = FALSE
    )
  
  # Add bars without text (just showing values)
  p <- p %>% add_trace(
    data = data,
    y = ~seq_len(n_players),
    x = ~count,
    type = 'bar',
    orientation = 'h',
    width = bar_height,
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
  )
  
  # Set layout properties
  p <- p %>% layout(
    title = list(
      text = paste(stat_name, "-", formatted_name),
      font = list(family = "Open Sans", size = 18, color = '#444')
    ),
    yaxis = list(
      title = "",
      showticklabels = FALSE,
      showgrid = FALSE,
      range = c(0.5, min(n_players + 0.5, 10.5)),
      fixedrange = TRUE    # Prevent y-axis panning
    ),
    xaxis = list(
      title = "Count",
      showgrid = TRUE,
      gridcolor = 'rgba(0,0,0,0.1)',
      zeroline = TRUE,
      zerolinecolor = 'rgba(0,0,0,0.1)',
      fixedrange = TRUE    # Prevent x-axis panning
    ),
    plot_bgcolor = '#FFFFFF',
    paper_bgcolor = '#FFFFFF',
    margin = list(l = 80, r = 30, b = 50, t = 80, pad = 4),
    dragmode = FALSE       # Disable all panning/zooming
  )
  
  # Add player head images as axis labels on the left
  for (i in 1:n_players) {
    username <- data$username[i]
    img_url <- paste0("https://kryeit.com/api/players/", username, "/head")
    
    # Use a text annotation with a visible box to make the player name show
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
  
  # Make plot scrollable if more than 10 players while keeping axes fixed
  if (n_players > 10) {
    p <- p %>% layout(
      yaxis = list(
        title = "",
        showticklabels = FALSE,
        showgrid = FALSE,
        range = c(0.5, 10.5),
        fixedrange = TRUE,  # Keep this fixed to prevent unintended scrolling
        scaleanchor = "x"
      ),
      # Add custom scroll behavior using config
      config = list(
        scrollZoom = TRUE,
        displayModeBar = FALSE  # Hide the mode bar entirely
      )
    )
  } else {
    p <- p %>% layout(
      config = list(
        displayModeBar = FALSE  # Hide the mode bar entirely
      )
    )
  }
  
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
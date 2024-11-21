library(ggplot2)
library(plotly)

# Function to create the "Online players per hour" graph with ggplot2 and plotly
onlines_graph <- function(data) {
    # Check if data is not empty and has the expected columns
    if (nrow(data) == 0 || !all(c("hour", "count") %in% colnames(data))) {
        stop("Data is empty or does not contain required columns.")
    }
    
    # Add a formatted_hour column for the tooltip
    data$formatted_hour <- sprintf("%02d:00", data$hour)
    data$tooltip <- sprintf("Hour: %s<br>Players: %d", data$formatted_hour, data$count)
    
    # Create the ggplot object
    p <- ggplot(data, aes(x = hour, y = count)) +
        geom_line(color = "blue", size = 1.5) +  # Line connecting points
        geom_point(color = "red", size = 3) +    # Points
        labs(
            title = "Online Players per Hour",
            x = "Hour of Day",
            y = "Number of Players Online"
        ) +
        scale_x_continuous(breaks = 0:23) +  # Ensure X-axis shows each hour
        theme(
            plot.title = element_text(hjust = 0.5),  # Center the title
            axis.title.x = element_text(size = 14),
            axis.title.y = element_text(size = 14)
        )
    
    # Convert ggplot to a plotly interactive plot and add custom tooltips
    ggplotly(p, tooltip = "text") %>%
        layout(hoverlabel = list(align = "left")) %>%
        add_markers(data = data, x = ~hour, y = ~count, text = ~tooltip, hoverinfo = "text", marker = list(color = 'red'))
}

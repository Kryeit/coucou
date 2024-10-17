library(ggplot2)
library(plotly)

# Function to create the "Online players per day" graph with ggplot2 and plotly
onlines_graph <- function(data) {
    # Check if data is not empty and has the expected columns
    if (nrow(data) == 0 || !all(c("hour", "count") %in% colnames(data))) {
        stop("Data is empty or does not contain required columns.")
    }
    
    # Create the ggplot object
    p <- ggplot(data, aes(x = hour, y = count)) +
        geom_line(color = "blue", size = 1.5) +  # Line connecting points
        geom_point(color = "red", size = 3) +    # Points for each hour
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

    # Convert ggplot to a plotly interactive plot
    ggplotly(p)
}

library(shiny)
library(ggplot2)
library(plotly)
library(dplyr)
library(gganimate)
library(scales)
library(gifski)

options(shiny.port = 6968)

# UI's and server instances
source("ui/onlines.R")
source("server/onlines.R")

# Create UI and Server
ui <- onlines_ui()
server <- onlines_server

# Run the application 
shinyApp(ui = ui, server = server)
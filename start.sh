#!/bin/bash

# Configuration
APP_DIR="/var/www/html/coucou"  # Directory containing app.R
LOG_FILE="app.log"  # Log file for app output
REQUIRED_PACKAGES=("shiny", "shinyjs", "ggplot2", "plotly", "DBI", "RClickhouse", "RPostgres", "htmltools", "DT", "jsonlite")  # List of required R packages

echo "Installing system dependencies..."
sudo apt update
sudo apt install -y libcurl4-openssl-dev libssl-dev libpq-dev

# Navigate to the app directory
cd "$APP_DIR" || { echo "Failed to navigate to $APP_DIR"; exit 1; }

# Function to install R packages if they are not already installed
install_r_packages() {
  for pkg in "${REQUIRED_PACKAGES[@]}"; do
    echo "Installing or checking R package: $pkg"
    R -e "if (!requireNamespace('$pkg', quietly = TRUE)) install.packages('$pkg', repos = 'https://cloud.r-project.org/')"
  done
}

# Install required R packages
echo "Checking and installing required R packages..."
install_r_packages

# Check if the app is already running
PID=$(pgrep -f "R -e shiny::runApp()")
if [ -n "$PID" ]; then
  echo "The app is already running (PID: $PID)."
  exit 1
fi

# Start the app in the background
echo "Starting Shiny app..."
nohup R -e "shiny::runApp()" > "$LOG_FILE" 2>&1 &

# Get the PID of the app
APP_PID=$!

# Wait for the app to start
sleep 5

# Check if the app is still running
if ps -p "$APP_PID" > /dev/null; then
  echo "Shiny app started successfully!"
  echo "App PID: $APP_PID"
  echo "Log file: $LOG_FILE"
  echo "Access the app at: http://127.0.0.1:6968/"
  echo "To stop the app, run: kill $APP_PID"
else
  echo "Failed to start the Shiny app. Check the log file for details: $LOG_FILE"
  exit 1
fi
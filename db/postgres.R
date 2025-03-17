library(DBI)
library(RPostgres)
library(pool)

# Global variable to store the connection pool
pg_pool <- NULL

# Initialize the connection pool once at app startup
init_postgres_pool <- function() {
  if (is.null(pg_pool)) {
    message("Initializing PostgreSQL connection pool...")
    
    host <- Sys.getenv("POSTGRES_HOST")
    port <- as.numeric(Sys.getenv("POSTGRES_PORT"))
    dbname <- Sys.getenv("POSTGRES_DBNAME")
    user <- Sys.getenv("POSTGRES_USER")
    password <- Sys.getenv("POSTGRES_PASSWORD")
    
    tryCatch({
      # Create a connection pool
      pg_pool <<- pool::dbPool(
        drv = RPostgres::Postgres(),
        host = host,
        port = port,
        dbname = dbname,
        user = user,
        password = password,
        minSize = 1,
        maxSize = 5,
        idleTimeout = 60 * 60 * 1000  # 1 hour in milliseconds
      )
      
      # Register an onStop handler to close all connections when the app stops
      shiny::onStop(function() {
        if (!is.null(pg_pool)) {
          message("Closing PostgreSQL connection pool...")
          pool::poolClose(pg_pool)
          pg_pool <<- NULL
        }
      })
      
      message("PostgreSQL connection pool successfully initialized.")
    }, error = function(e) {
      message("Failed to initialize PostgreSQL connection pool.")
      message("Error details: ", e$message)
      stop("Failed to initialize PostgreSQL connection pool: ", e$message)
    })
  }
}

# Function to get a connection from the pool
connect_to_postgres <- function() {
  if (is.null(pg_pool)) {
    init_postgres_pool()
  }
  return(pg_pool)
}

# Simplified function to execute a query
execute_postgres_query <- function(query, ...) {
  conn <- connect_to_postgres()
  tryCatch({
    result <- dbGetQuery(conn, query, ...)
    return(result)
  }, error = function(e) {
    message("Error executing query: ", e$message)
    return(NULL)
  })
}
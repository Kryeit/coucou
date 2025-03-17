library(DBI)
library(RPostgres)
library(pool)

pg_pool <- NULL

init_postgres_pool <- function() {
  if (is.null(pg_pool)) {
    message("Initializing PostgreSQL connection pool...")
    
    host <- Sys.getenv("POSTGRES_HOST")
    port <- as.numeric(Sys.getenv("POSTGRES_PORT"))
    dbname <- Sys.getenv("POSTGRES_DBNAME")
    user <- Sys.getenv("POSTGRES_USER")
    password <- Sys.getenv("POSTGRES_PASSWORD")
    
    tryCatch({
      pg_pool <<- pool::dbPool(
        drv = RPostgres::Postgres(),
        host = host,
        port = port,
        dbname = dbname,
        user = user,
        password = password,
        minSize = 1,
        maxSize = 5,
        idleTimeout = 60 * 60 * 1000
      )
      
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

get_pg_conn <- function() {
  if (is.null(pg_pool)) {
    init_postgres_pool()
  }
  return(pg_pool)
}

query <- function(sql, params = NULL) {
  conn <- get_pg_conn()
  tryCatch({
    if (is.null(params)) {
      result <- dbGetQuery(conn, sql)
    } else {
      result <- dbGetQuery(conn, sql, params)
    }
    return(result)
  }, error = function(e) {
    message("Error executing query: ", e$message)
    return(NULL)
  })
}

safe_query <- function(sql_template, ...) {
  params <- list(...)
  conn <- get_pg_conn()
  tryCatch({
    result <- dbGetQuery(conn, sql_template, params)
    return(result)
  }, error = function(e) {
    message("Error executing parameterized query: ", e$message)
    return(NULL)
  })
}
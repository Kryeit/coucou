library(DBI)
library(RClickhouse)

connect_to_clickhouse <- function() {
    con <- tryCatch(
        {
            message("Attempting to connect to ClickHouse...")

            host <- Sys.getenv("CLICKHOUSE_HOST")
            port <- as.numeric(Sys.getenv("CLICKHOUSE_PORT"))
            dbname <- Sys.getenv("CLICKHOUSE_DBNAME")
            user <- Sys.getenv("CLICKHOUSE_USER")
            password <- Sys.getenv("CLICKHOUSE_PASSWORD")

            dbConnect(
                RClickhouse::clickhouse(),
                host = host,
                port = port,
                dbname = dbname,
                user = user,
                password = password
            )
        },
        error = function(e) {
            message("Failed to connect to ClickHouse.")
            message("Error details: ", e$message)
            stop("Failed to connect to ClickHouse: ", e$message)
        }
    )
    
    message("Successfully connected to ClickHouse.")
    return(con)
}

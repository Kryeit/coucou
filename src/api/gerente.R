# Thin client for the Gerente backend (https://github.com/Kryeit/Gerente).
# We talk to its public HTTP API instead of connecting to Postgres directly.
#
# Base URL defaults to production; override with GERENTE_API_URL for local dev
# (e.g. http://localhost:8080).

library(jsonlite)

options(timeout = 20)  # don't let a slow/unreachable backend hang the app

api_base <- function() {
  sub("/+$", "", Sys.getenv("GERENTE_API_URL", "https://kryeit.com"))
}

# Build a full URL with an encoded query string from a named list.
api_url <- function(path, params = list()) {
  qs <- ""
  if (length(params)) {
    parts <- vapply(names(params), function(k) {
      paste0(utils::URLencode(k, reserved = TRUE), "=",
             utils::URLencode(as.character(params[[k]]), reserved = TRUE))
    }, character(1))
    qs <- paste0("?", paste(parts, collapse = "&"))
  }
  paste0(api_base(), path, qs)
}

# GET + parse JSON. Returns the parsed value, or NULL on any error.
gerente_get <- function(path, params = list()) {
  url <- api_url(path, params)
  tryCatch(
    jsonlite::fromJSON(url),
    error = function(e) {
      message("Gerente API request failed (", url, "): ", conditionMessage(e))
      NULL
    }
  )
}

# GET /api/leaderboard -> data.frame(name, uuid, value, formattedValue) or NULL.
fetch_leaderboard <- function(namespace, key, limit = 100, offset = 0, ascending = FALSE) {
  res <- gerente_get("/api/leaderboard", list(
    namespace = namespace,
    key       = key,
    limit     = limit,
    offset    = offset,
    ascending = if (isTRUE(ascending)) "true" else "false"
  ))
  if (is.null(res) || !is.data.frame(res) || nrow(res) == 0) return(NULL)
  res$value <- suppressWarnings(as.numeric(res$value))
  res
}

# GET /api/leaderboard/keys?namespace=... -> character vector of stat keys.
fetch_keys <- function(namespace) {
  res <- gerente_get("/api/leaderboard/keys", list(namespace = namespace))
  if (is.null(res)) return(character(0))
  as.character(res)
}

# GET /api/leaderboard/namespaces -> character vector of namespaces.
fetch_namespaces <- function() {
  res <- gerente_get("/api/leaderboard/namespaces")
  if (is.null(res)) return(character(0))
  as.character(res)
}

# Player head image, served by the backend by UUID.
player_head_url <- function(uuid) {
  paste0(api_base(), "/api/players/", utils::URLencode(uuid, reserved = TRUE), "/head-skin")
}

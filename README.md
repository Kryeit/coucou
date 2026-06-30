<img src="https://github.com/Kryeit/coucou/blob/main/src/assets/example.png" alt=""/>

# [Coucou](https://coucou.kryeit.com) Statistics portal

[R 4.4+](https://cran.r-project.org) + [Shiny](https://shiny.posit.co)

Player leaderboards built from each player's Minecraft stats, fetched from the
[Gerente](https://github.com/Kryeit/Gerente) backend's public HTTP API
(`/api/leaderboard`). No direct database connection.

R libraries:
- [shiny](https://shiny.posit.co)
- [shiny.router](https://appsilon.github.io/shiny.router/)
- [shiny.tailwind](https://kylebutts.github.io/shiny.tailwind/)
- [jsonlite](https://jeroen.r-universe.dev/jsonlite)

*Recommended editor: [RStudio](https://posit.co/download/rstudio-desktop/)*

## Running

Install the dependencies once:
```r
source("install_dependencies.R")
```

The app calls the Gerente API at `https://kryeit.com` by default. To point it at
a local backend, set `GERENTE_API_URL` in a `.Renviron` in `src/`:
```yaml
GERENTE_API_URL=http://localhost:8080
```

Then, from the `src/` directory:
```r
shiny::runApp()
```
Or without a proper workspace:
```bash
chmod +x start.sh
./start.sh
```

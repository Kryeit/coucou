# [Coucou](https://coucou.kryeit.com) Statistics portal

[R 4.4.3](https://cran.r-project.org) + [Shiny](https://shiny.posit.co)
<img src="https://github.com/Kryeit/coucou/blob/main/src/assets/example.png" alt=""/>
And as always with R, the endless list of libraries:
- [ShinyJs](https://deanattali.com/shinyjs/)
- [GGPlot2](https://ggplot2.tidyverse.org)
- [Plotly](https://plotly.com/r/)
- [DBI](https://dbi.r-dbi.org)
- [RPostgres](https://cran.r-project.org/web/packages/RPostgres/index.html)
- Etc

*Recommended editor: [RStudio](https://posit.co/download/rstudio-desktop/)*
## Running

Create a `.Renviron`:
```yaml
CLICKHOUSE_HOST=example.com
CLICKHOUSE_PORT=YOUR_PORT
CLICKHOUSE_DBNAME=YOUR_DB_NAME
CLICKHOUSE_USER=default
CLICKHOUSE_PASSWORD=YOUR_PASSWORD
POSTGRES_HOST=example.com
POSTGRES_PORT=YOUR_PORT
POSTGRES_DBNAME=YOUR_DB_NAME
POSTGRES_USER=postgres
POSTGRES_PASSWORD=YOUR_PASSWORD
```

```bash
shiny::runApp()
```
Or without a proper workspace:
```bash
chmod +x start.sh
./start.sh
```


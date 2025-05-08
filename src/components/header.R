header_ui <- function() {
  div(
    class = "w-full",
    tags$header(
      class = "flex items-center border-b-gray-100",
      a(
        class = "no-underline hover:no-underline focus:no-underline",
        href = route_link("/"),
        img(
          src = "assets/banner.png", 
          class = "h-[100px] object-contain",
          alt = "Kryeit Banner"
        ),
        a(
          class = "text-blue-500 font-medium ml-auto mr-4",
          href = "https://ko-fi.com/kryeit", 
          "Donate"
        )
    )
    ),
    div(
      id = "dropdown-container",
      class = "relative inline-block mt-4",
      actionLink(
        "graphs_toggle",
        label = div(
          class = "inline-flex items-center px-4 py-2 bg-gray-100 hover:bg-gray-200 rounded-md cursor-pointer transition-colors duration-200",
          span(class = "font-medium text-gray-800", "Graphs"),
          tags$span(class = "ml-1 text-gray-600", "▼")
        )
      ),
      uiOutput("graphs_menu")
    ),
    div(class = "mb-8")
  )
}

header_server <- function(input, output, session, current_route) {
  show_menu <- reactiveVal(FALSE)
  
  observeEvent(input$graphs_toggle, {
    show_menu(!show_menu())
  })
  
  create_menu_button <- function(route) {
    selected <- current_route == route
    a(
      class = paste(
        "block px-4 py-2 w-full text-left ",
        "hover:bg-gray-100",
        if (selected) "bg-gray-100" else ""
      ),
      draggable = "false",
      href = route_link(route),
      capitalize(route)
    )
  }
  
  create_menu <- function() {
    routes <- c("onlines", "leaderboard")
    lapply(routes, create_menu_button)
  }
  
  output$graphs_menu <- renderUI({
    if (show_menu()) {
      div(
        class = "absolute left-0 mt-1 w-52 bg-white rounded-md shadow-lg",
        style = "z-index: 1000;",
        div(
          class = "py-1 rounded-md ring-1 ring-black ring-opacity-5",
          create_menu()
        )
      )
    }
  })
}

capitalize <- function(x) {
  if (nchar(x) == 0) return(x)
  paste0(toupper(substr(x, 1, 1)), tolower(substr(x, 2, nchar(x))))
}
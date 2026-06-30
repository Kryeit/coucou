category_choices <- c(
  "Custom"        = "minecraft:custom",
  "Items Used"    = "minecraft:used",
  "Items Broken"  = "minecraft:broken",
  "Items Crafted" = "minecraft:crafted",
  "Items Mined"   = "minecraft:mined",
  "Mob Kills"     = "minecraft:killed",
  "Deaths"        = "minecraft:killed_by"
)

leaderboard_ui <- function(id) {
  ns <- NS(id)

  div(
    # html2canvas: used to snapshot the leaderboard to a PNG.
    tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js"),
    # Clipboard helper (with execCommand fallback) + PNG download.
    tags$script(HTML(paste(
      "Shiny.addCustomMessageHandler('copy_share_link', function(q){",
      "  var url = window.location.origin + window.location.pathname + '#!/leaderboard?' + q;",
      "  if (navigator.clipboard && navigator.clipboard.writeText) {",
      "    navigator.clipboard.writeText(url).catch(function(){ coucouCopyFallback(url); });",
      "  } else { coucouCopyFallback(url); }",
      "});",
      "function coucouCopyFallback(text){",
      "  var ta = document.createElement('textarea');",
      "  ta.value = text; ta.style.position = 'fixed'; ta.style.top = '-1000px';",
      "  document.body.appendChild(ta); ta.focus(); ta.select();",
      "  try { document.execCommand('copy'); } catch (e) {}",
      "  document.body.removeChild(ta);",
      "}",
      "function coucouDownloadPng(){",
      "  var el = document.getElementById('leaderboard-leaderboard');",
      "  if (!el || typeof html2canvas === 'undefined') return;",
      "  html2canvas(el, {backgroundColor: '#ffffff', useCORS: true, scale: 2}).then(function(canvas){",
      "    var a = document.createElement('a');",
      "    a.download = 'leaderboard.png';",
      "    a.href = canvas.toDataURL('image/png');",
      "    a.click();",
      "  });",
      "}",
      sep = "\n"
    ))),

    div(
      class = "rounded-2xl bg-white shadow-card border border-slate-200 overflow-hidden",

      # Header
      div(
        class = "px-5 sm:px-6 pt-5 pb-4 border-b border-slate-100",
        h1(class = "font-mc text-2xl text-slate-900", "Leaderboard"),
        p(class = "mt-1 text-sm text-slate-500",
          "Rank every player by a single Minecraft statistic.")
      ),

      # Controls
      div(
        class = "px-5 sm:px-6 py-4 grid grid-cols-1 sm:grid-cols-12 gap-4 items-end bg-slate-50/60",
        div(
          class = "sm:col-span-4",
          selectizeInput(
            ns("category"), "Category", choices = category_choices,
            selected = "minecraft:custom", width = "100%",
            options = list(dropdownParent = "body")
          )
        ),
        div(
          class = "sm:col-span-4",
          selectizeInput(
            ns("identifier"), "Item", choices = NULL, width = "100%",
            options = list(placeholder = "Select an item", maxOptions = 1000)
          )
        ),
        div(
          class = "sm:col-span-4",
          # Buttons only render when there's data to act on (see server).
          uiOutput(ns("actions"))
        )
      ),

      # Results
      div(
        class = "px-3 sm:px-4 py-4",
        uiOutput(ns("leaderboard"))
      )
    )
  )
}

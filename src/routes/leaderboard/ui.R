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
    # Share the current selection: native share sheet on mobile, copy on desktop.
    tags$script(HTML(paste(
      "function coucouFallbackCopy(text){",
      "  var ta = document.createElement('textarea');",
      "  ta.value = text; ta.style.position = 'fixed'; ta.style.top = '-1000px';",
      "  document.body.appendChild(ta); ta.focus(); ta.select();",
      "  try { document.execCommand('copy'); } catch (e) {}",
      "  document.body.removeChild(ta);",
      "}",
      "function coucouFlash(btn){",
      "  var html = btn.innerHTML; btn.innerHTML = 'Copied!';",
      "  setTimeout(function(){ btn.innerHTML = html; }, 1000);",
      "}",
      "function coucouShare(btn){",
      "  var cat = (document.getElementById('leaderboard-category')   || {}).value || '';",
      "  var id  = (document.getElementById('leaderboard-identifier') || {}).value || '';",
      "  if (!id) return;",
      "  var url = window.location.origin + window.location.pathname +",
      "            '#!/leaderboard?category=' + encodeURIComponent(cat) +",
      "            '&identifier=' + encodeURIComponent(id);",
      "  if (navigator.share) {",
      "    navigator.share({ title: 'Kryeit stats', url: url }).catch(function(){});",
      "  } else if (navigator.clipboard && navigator.clipboard.writeText) {",
      "    navigator.clipboard.writeText(url).then(function(){ coucouFlash(btn); })",
      "      .catch(function(){ coucouFallbackCopy(url); coucouFlash(btn); });",
      "  } else { coucouFallbackCopy(url); coucouFlash(btn); }",
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
            options = list(placeholder = "Select an item", maxOptions = 2000,
                           dropdownParent = "body")
          )
        ),
        div(
          class = "sm:col-span-4",
          uiOutput(ns("actions"))
        )
      ),

      # Leaderboard (only shown once an item is picked)
      conditionalPanel(
        condition = sprintf("input['%s']", ns("identifier")),
        div(
          class = "px-2 sm:px-4 py-4",
          uiOutput(ns("leaderboard"))
        )
      )
    )
  )
}

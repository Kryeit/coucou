// Theme for the Tailwind Play CDN (loaded by shiny.tailwind::use_tailwind).
// Keep this small: a readable sans for data, Minecraftia as a heading accent,
// and a Minecraft-ish palette.
tailwind.config = {
  theme: {
    extend: {
      fontFamily: {
        mc: ['Minecraftia', 'ui-monospace', 'monospace'],
        sans: ['Minecraftia', 'ui-monospace', 'monospace']
      },
      colors: {
        grass: {
          50:  '#f1f9ec', 100: '#dcf0cf', 200: '#bbe1a4',
          300: '#92cd72', 400: '#6fb84b', 500: '#539b32',
          600: '#3f7b25', 700: '#326020', 800: '#2b4d1e', 900: '#264019'
        }
      },
      boxShadow: {
        card: '0 1px 2px rgba(16,24,40,.06), 0 1px 3px rgba(16,24,40,.10)'
      }
    }
  }
}

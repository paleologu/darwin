import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sunIcon", "moonIcon", "systemIcon"]
  static values = {
    storageKey: { type: String, default: "ui-theme" }
  }

  connect() {
    // Listen for system theme changes
    this.mediaQuery = window.matchMedia("(prefers-color-scheme: dark)")
    this.handleSystemChange = this.handleSystemChange.bind(this)
    this.mediaQuery.addEventListener("change", this.handleSystemChange)

    // Update icons based on current stored theme
    this.updateIcons()
  }

  disconnect() {
    if (this.mediaQuery) {
      this.mediaQuery.removeEventListener("change", this.handleSystemChange)
    }
  }

  toggle() {
    const themes = ["light", "dark", "system"]
    const currentIndex = themes.indexOf(this.currentTheme)
    const nextIndex = (currentIndex + 1) % themes.length
    const nextTheme = themes[nextIndex]

    this.setTheme(nextTheme)
  }

  setTheme(theme) {
    localStorage.setItem(this.storageKeyValue, theme)
    this.applyTheme(theme)
    this.updateIcons()
  }

  applyTheme(theme) {
    const root = document.documentElement

    root.classList.remove("light", "dark")

    if (theme === "system") {
      const systemTheme = this.mediaQuery.matches ? "dark" : "light"
      root.classList.add(systemTheme)
    } else {
      root.classList.add(theme)
    }
  }

  updateIcons() {
    const theme = this.currentTheme

    // Hide all icons first
    if (this.hasSunIconTarget) this.sunIconTarget.classList.add("hidden")
    if (this.hasMoonIconTarget) this.moonIconTarget.classList.add("hidden")
    if (this.hasSystemIconTarget) this.systemIconTarget.classList.add("hidden")

    // Show the appropriate icon based on stored theme preference
    if (theme === "light" && this.hasSunIconTarget) {
      this.sunIconTarget.classList.remove("hidden")
    } else if (theme === "dark" && this.hasMoonIconTarget) {
      this.moonIconTarget.classList.remove("hidden")
    } else if (theme === "system" && this.hasSystemIconTarget) {
      this.systemIconTarget.classList.remove("hidden")
    }
  }

  handleSystemChange() {
    if (this.currentTheme === "system") {
      this.applyTheme("system")
    }
  }

  get currentTheme() {
    return localStorage.getItem(this.storageKeyValue) || "system"
  }
}

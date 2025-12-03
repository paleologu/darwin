import "@hotwired/turbo-rails"
import "darwin-editor-controllers"

document.addEventListener("turbo:before-fetch-request", (event) => {
  const { fetchOptions } = event.detail
  fetchOptions.headers["X-Darwin-Editor"] = "true"
})

console.log("Darwin editor bundle loaded")

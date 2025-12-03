import "@hotwired/turbo-rails"
import "darwin-client-controllers"

document.addEventListener("turbo:load", () => {
  document.body.dataset.darwinClient = "ready"
})

console.log("Darwin client bundle loaded")

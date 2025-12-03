import { Application } from "@hotwired/stimulus"

const application = Application.start()

application.debug = false
window.DarwinClient = application

export { application }

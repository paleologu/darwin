import { application } from "darwin-editor-controllers/application"

import PanelController from "darwin-editor-controllers/panel_controller"
import RichtextController from "darwin-editor-controllers/richtext_controller"
import BannerController from "darwin-editor-controllers/banner_controller"
import BlockFormController from "darwin-editor-controllers/block_form_controller"
import NestedFormController from "darwin-editor-controllers/nested_form_controller"
import ThemeController from "darwin-editor-controllers/theme_controller"
import EditorRedirectController from "darwin-editor-controllers/editor_redirect_controller"
import ColumnsController from "darwin-editor-controllers/columns_controller"
import { registerControllers } from "ui"

application.register("editor-panel", PanelController)
application.register("editor-richtext", RichtextController)
application.register("editor-banner", BannerController)
application.register("block-form", BlockFormController)
application.register("nested-form", NestedFormController)
application.register("theme", ThemeController)
application.register("editor-redirect", EditorRedirectController)
application.register("columns", ColumnsController)

registerControllers(application)

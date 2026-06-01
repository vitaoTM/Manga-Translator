// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
// import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
// eagerLoadControllersFrom("controllers", application)

import DropzoneController      from "controllers/dropzone_controller"
import ModelSelectorController from "controllers/model_selector_controller"
import BatchPollerController   from "controllers/batch_poller_controller"

application.register("dropzone",       DropzoneController)
application.register("model-selector", ModelSelectorController)
application.register("batch-poller",   BatchPollerController)

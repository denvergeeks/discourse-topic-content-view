import Controller from "@ember/controller";
import { action } from "@ember/object";
import { set } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class AdminPluginsTopicContentViewController extends Controller {
  @action
  async saveScss(mode) {
    set(mode, "saving", true);
    set(mode, "saved", false);

    try {
      await ajax("/admin/plugins/topic-content-view", {
        type: "PUT",
        data: {
          mode_value: mode.value,
          scss: mode.scss || "",
        },
      });
      set(mode, "saved", true);
      // Clear the saved indicator after 2 seconds
      setTimeout(() => set(mode, "saved", false), 2000);
    } catch (e) {
      popupAjaxError(e);
    } finally {
      set(mode, "saving", false);
    }
  }
}

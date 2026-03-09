import DiscourseRoute from "discourse/routes/discourse";
import { ajax } from "discourse/lib/ajax";

export default class TopicContentShowRoute extends DiscourseRoute {
  model(params) {
    // params may have { slug, id } or just { id } depending on the matched path.
    // Always use the numeric id when present, falling back to slug.
    const id = params.id || params.slug;
    // Append .json so Rails serves the JSON API (not the HTML catch-all)
    return ajax(`/t/${id}/content.json`);
  }

  titleToken() {
    const model = this.modelFor(this.routeName);
    return model?.title;
  }
}

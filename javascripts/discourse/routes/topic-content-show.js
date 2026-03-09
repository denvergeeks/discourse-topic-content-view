import DiscourseRoute from "discourse/routes/discourse";
import { ajax } from "discourse/lib/ajax";

export default class TopicContentShowRoute extends DiscourseRoute {
  model(params) {
    // params.id is the numeric topic id (from /tc/:slug/:id or /tc/:id)
    // Fetch .json so Rails routes it to TopicContentViewController#show
    const id = params.id;
    return ajax(`/tc/${id}.json`);
  }

  titleToken() {
    const model = this.modelFor(this.routeName);
    return model?.title;
  }
}

import DiscourseRoute from "discourse/routes/discourse";
import { ajax } from "discourse/lib/ajax";

export default class TopicContentShowRoute extends DiscourseRoute {
  model(params) {
    const id = params.id || params.slug;
    return ajax(`/t/${id}/content.json`);
  }

  titleToken() {
    const model = this.modelFor(this.routeName);
    return model?.title;
  }
}

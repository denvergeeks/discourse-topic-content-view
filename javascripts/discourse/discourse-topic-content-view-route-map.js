export default {
  resource: "root",
  path: "/",
  map() {
    this.route("topic-content-show", { path: "/tc/:slug/:id" });
    this.route("topic-content-show", { path: "/tc/:id" });
  },
};

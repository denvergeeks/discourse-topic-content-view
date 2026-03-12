# frozen_string_literal: true

# name: discourse-topic-content-view
# about: Adds configurable CSS classes to body via ?tcv=MODE query param, enabling mode-specific topic presentation (hide chrome, show only cooked content, etc.)
# version: 2.0.0
# authors: @denvergeeks
# url: https://github.com/denvergeeks/discourse-topic-content-view

enabled_site_setting :topic_content_view_enabled

register_asset "stylesheets/topic-content-view.scss", :desktop

# Register the plugin admin page link in Discourse admin panel
add_admin_route "topic_content_view.admin.title", "topic-content-view"

after_initialize do
  module ::TopicContentView
    PLUGIN_NAME = "discourse-topic-content-view"
  end

  require_relative "app/controllers/topic_content_view/admin_controller"

  TopicContentView::AdminController.class_eval do
    requires_plugin TopicContentView::PLUGIN_NAME
  end

  Discourse::Application.routes.prepend do
    namespace :topic_content_view, path: "/topic-content-view" do
      get "admin" => "topic_content_view/admin#index", constraints: StaffConstraint.new
      put "admin" => "topic_content_view/admin#update", constraints: StaffConstraint.new
    end
  end
end

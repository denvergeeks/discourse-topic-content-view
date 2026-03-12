# name: discourse-topic-content-view
# about: Renders configurable topic content views via ?tcv=MODE query param
# version: 2.0.0
# authors: @denvergeeks
# url: https://github.com/denvergeeks/discourse-topic-content-view

enabled_site_setting :topic_content_view_enabled

register_asset "stylesheets/topic-content-view.scss", :desktop

# Register plugin admin page
add_admin_route 'topic_content_view.admin.title', 'topic-content-view'

after_initialize do
  # Expose mode settings to the client-side JS
  # topic_content_view_modes and topic_content_view_custom_modes
  # are already available via Discourse.SiteSettings because they
  # have client: true in settings.yml.

  # Admin controller for the plugin settings UI
  module ::TopicContentView
    PLUGIN_NAME = 'discourse-topic-content-view'.freeze

    class Engine < ::Rails::Engine
      engine_name TopicContentView::PLUGIN_NAME
      isolate_namespace TopicContentView
    end
  end

  class TopicContentView::AdminController < ::Admin::AdminController
    requires_plugin TopicContentView::PLUGIN_NAME

    def index
      render_json_dump(
        modes: parse_modes(SiteSetting.topic_content_view_modes),
        custom_modes: parse_modes(SiteSetting.topic_content_view_custom_modes)
      )
    end

    def update
      type  = params.require(:type)  # 'modes' or 'custom_modes'
      value = params.require(:value) # pipe-separated list entries, newline-joined

      setting_name = "topic_content_view_#{type}"
      raise Discourse::InvalidParameters unless %w[modes custom_modes].include?(type)

      SiteSetting.set(setting_name, value)
      render json: success_json
    end

    private

    def parse_modes(raw)
      return [] if raw.blank?
      raw.split("\n").filter_map do |line|
        line = line.strip
        next if line.blank?
        parts = line.split('|', 2)
        next unless parts.length == 2
        { value: parts[0].strip, classes: parts[1].strip }
      end
    end
  end

  TopicContentView::Engine.routes.draw do
    get  '/'  => 'admin#index'
    put  '/'  => 'admin#update'
  end

  Discourse::Application.routes.prepend do
    mount ::TopicContentView::Engine, at: '/admin/plugins/topic-content-view'
  end
end

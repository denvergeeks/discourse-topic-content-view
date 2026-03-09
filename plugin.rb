# name: discourse-topic-content-view
# about: Minimal view rendering only a topic's first-post cooked content
# version: 0.9.0
# authors: @denvergeeks
# url: https://github.com/denvergeeks/discourse-topic-content-view

enabled_site_setting :topic_content_view_enabled

after_initialize do
  ApplicationController.prepend_view_path(File.join(File.dirname(__FILE__), "app/views"))

  class ::TopicContentViewController < ::ApplicationController
    requires_plugin 'discourse-topic-content-view'
    skip_before_action :check_xhr, :preload_json, :verify_authenticity_token
    layout 'topic_content'

    def show
      @topic = find_topic(params[:id])
      raise Discourse::NotFound unless @topic
      guardian.ensure_can_see!(@topic)
      @post = @topic.first_post
      raise Discourse::NotFound unless @post
      render 'discourse_topic_content_view/topic_content/show', formats: [:html]
    end

    private

    def find_topic(id_or_slug)
      if id_or_slug =~ /\A\d+\z/
        Topic.find_by(id: id_or_slug.to_i)
      else
        Topic.find_by(slug: id_or_slug)
      end
    end
  end

  Discourse::Application.routes.prepend do
    get '/t/:slug/:id/content' => 'topic_content_view#show',
        constraints: { id: /\d+/, slug: /[^\/]+/ }
    get '/t/:id/content' => 'topic_content_view#show',
        constraints: { id: /[^.]+/ }
  end
end

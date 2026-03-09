# name: discourse-topic-content-view
# about: Renders a topic's first-post cooked content via a JSON API + Ember route
# version: 1.0.0
# authors: @denvergeeks
# url: https://github.com/denvergeeks/discourse-topic-content-view

enabled_site_setting :topic_content_view_enabled

register_asset "stylesheets/topic-content-view.scss", :desktop

after_initialize do
  # JSON API only — served at /tc/:slug/:id and /tc/:id (with .json format)
  # HTML requests (no .json) fall through to Discourse's catch-all → Ember SPA boots
  # We use /tc/ prefix to avoid collision with Discourse's own /t/ topic routes
  class ::TopicContentViewController < ::ApplicationController
    requires_plugin 'discourse-topic-content-view'
    skip_before_action :verify_authenticity_token

    def show
      topic_id = params[:id] || params[:slug]
      topic_view = TopicView.new(topic_id, current_user)
      topic = topic_view.topic

      raise Discourse::NotFound unless topic
      guardian.ensure_can_see!(topic)

      post = topic.ordered_posts.first
      raise Discourse::NotFound unless post

      render json: {
        id: topic.id,
        title: topic.title,
        slug: topic.slug,
        category_id: topic.category_id,
        category_name: topic.category&.name,
        tags: topic.tags.map(&:name),
        cooked: post.cooked,
        created_at: post.created_at,
        updated_at: post.updated_at
      }
    rescue Discourse::InvalidAccess
      raise Discourse::NotFound
    end
  end

  Discourse::Application.routes.prepend do
    # /tc/ prefix avoids Discourse's greedy /t/:slug/:id topic route consuming our path
    get '/tc/:slug/:id' => 'topic_content_view#show',
        constraints: { id: /\d+/, slug: /[^\/]+/, format: /json/ }
    get '/tc/:id' => 'topic_content_view#show',
        constraints: { id: /[^.\/]+/, format: /json/ }
  end
end

# name: discourse-topic-content-view
# about: Display topic content in a clean view with just cooked content
# version: 0.1.0
# authors: @denvergeeks
# url: https://github.com/denvergeeks/discourse-topic-content-view

enabled_site_setting :topic_content_view_enabled

after_initialize do
  module ::DiscourseTopicContentView
    class Engine < ::Rails::Engine
      engine_name "discourse_topic_content_view"
      isolate_namespace DiscourseTopicContentView
    end
  end

  class DiscourseTopicContentView::TopicContentController < ::ApplicationController
    requires_plugin 'discourse-topic-content-view'
    
    skip_before_action :check_xhr, :preload_json, :verify_authenticity_token
    
    def show
      # Get topic by ID or slug
      topic = find_topic(params[:id])
      
      raise Discourse::NotFound unless topic
      
      # Check permissions
      guardian.ensure_can_see!(topic)
      
      # Get the first post (topic content)
      @post = topic.first_post
      raise Discourse::NotFound unless @post
      
      # Render with minimal layout
      render :show, layout: 'topic_content'
    end
    
    private
    
    def find_topic(id_or_slug)
      # Try to find by ID first
      if id_or_slug.to_i.to_s == id_or_slug
        Topic.find_by(id: id_or_slug.to_i)
      else
        # Find by slug
        Topic.find_by(slug: id_or_slug)
      end
    end
  end
  
  Discourse::Application.routes.append do
    get '/topic-content/:id' => 'discourse_topic_content_view/topic_content#show', constraints: { id: /[^\/]+/ }
  end
end

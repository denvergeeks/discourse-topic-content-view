# name: discourse-topic-content-view
# about: Display topic cooked content at /topic-content/:id with full theme JS
# version: 0.4.0
# authors: @denvergeeks
# url: https://github.com/denvergeeks/discourse-topic-content-view

enabled_site_setting :topic_content_view_enabled

after_initialize do
  class ::TopicContentViewController < ::ApplicationController
    requires_plugin 'discourse-topic-content-view'
    skip_before_action :check_xhr, :preload_json, :verify_authenticity_token
    layout false

    def show
      topic = find_topic(params[:id])
      raise Discourse::NotFound unless topic
      guardian.ensure_can_see!(topic)

      post = topic.first_post
      raise Discourse::NotFound unless post

      title      = ERB::Util.html_escape(topic.title)
      site_title = ERB::Util.html_escape(SiteSetting.title)
      cooked     = post.cooked
      nonce      = SecureRandom.hex(16)

      # Resolve the hashed publish asset path the same way Discourse does
      publish_js_path = begin
        ActionController::Base.helpers.asset_path('publish.js')
      rescue
        # Fallback: scan the assets directory for the hashed filename
        publish_file = Dir.glob(Rails.root.join('public', 'assets', 'publish-*.js')).first
        publish_file ? "/assets/#{File.basename(publish_file)}" : nil
      end

      # Build stylesheet link tags the same way published pages do
      css_tags = ""
      begin
        manager = Stylesheet::Manager.new(theme_id: theme_id)

        manager.stylesheet_details(:color_definitions, 'all').each do |s|
          css_tags += "  <link href=\"#{s[:new_href]}\" media=\"all\" rel=\"stylesheet\">\n"
        end rescue nil

        manager.stylesheet_details(:publish, 'all').each do |s|
          css_tags += "  <link href=\"#{s[:new_href]}\" media=\"all\" rel=\"stylesheet\">\n"
        end rescue nil

        manager.stylesheet_details(:common_theme, 'all').each do |s|
          css_tags += "  <link href=\"#{s[:new_href]}\" media=\"all\" rel=\"stylesheet\" data-theme-id=\"#{s[:theme_id]}\">\n"
        end rescue nil

        manager.stylesheet_details(:desktop_theme, 'all').each do |s|
          css_tags += "  <link href=\"#{s[:new_href]}\" media=\"all\" rel=\"stylesheet\" data-theme-id=\"#{s[:theme_id]}\">\n"
        end rescue nil

        Discourse.find_plugin_css_assets(
          include_disabled: false,
          mobile_view: false,
          desktop_view: true
        ).each do |asset|
          css_tags += "  <link href=\"/stylesheets/#{asset}.css\" media=\"all\" rel=\"stylesheet\">\n"
        end rescue nil
      rescue => e
        Rails.logger.error "TopicContentView CSS error: #{e.message}"
      end

      # Build JS tag using the resolved hashed path
      js_tag = publish_js_path ?
        "  <script defer src=\"#{publish_js_path}\" data-discourse-entrypoint=\"publish\" nonce=\"#{nonce}\"></script>\n" : ""

      html = <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <title>#{title} - #{site_title}</title>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, minimum-scale=1.0, viewport-fit=cover">
        #{css_tags}
          <style>
            body {
              max-width: 900px;
              margin: 0 auto;
              padding: 2em 2em 4em;
              font-family: var(--font-family);
              background: var(--secondary);
              color: var(--primary);
            }
            .topic-content-title {
              font-size: 1.7em;
              font-weight: bold;
              margin-bottom: 1em;
              padding-bottom: 0.5em;
              border-bottom: 1px solid var(--primary-low);
            }
            .cooked img { max-width: 100%; height: auto; }
            .cooked pre {
              background: var(--primary-very-low);
              padding: 1em;
              border-radius: 4px;
              overflow-x: auto;
            }
            .cooked code {
              background: var(--primary-very-low);
              padding: 0.15em 0.4em;
              border-radius: 3px;
            }
            .cooked blockquote {
              border-left: 4px solid var(--primary-low-mid);
              padding-left: 1em;
              margin-left: 0;
            }
          </style>
        </head>
        <body class="topic-content-view">
          <div class="topic-content-container">
            <h1 class="topic-content-title">#{title}</h1>
            <div class="topic-content-body cooked">
              #{cooked}
            </div>
          </div>
        #{js_tag}
        </body>
        </html>
      HTML

      render html: html.html_safe
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

  Discourse::Application.routes.append do
    get '/topic-content/:id' => 'topic_content_view#show', constraints: { id: /[^\/]+/ }
  end
end

# frozen_string_literal: true

module TopicContentView
  class AdminController < ::Admin::AdminController
    # GET /admin/plugins/topic-content-view
    def index
      render_json_dump(modes: load_modes)
    end

    # PUT /admin/plugins/topic-content-view
    def update
      modes = params.require(:modes)
      sanitised =
        Array(modes).filter_map do |m|
          next unless m.is_a?(ActionController::Parameters) || m.is_a?(Hash)
          m = m.to_unsafe_h.with_indifferent_access
          next if m[:value].blank?
          {
            value: m[:value].to_s.strip.downcase.gsub(/[^a-z0-9_-]/, ""),
            label: m[:label].to_s.strip,
            classes: m[:classes].to_s.strip,
            css: m[:css].to_s,
            preset: m[:preset].present? ? true : false,
            enabled: m[:enabled] == false || m[:enabled] == "false" ? false : true,
          }
        end

      SiteSetting.set(:topic_content_view_modes, sanitised.to_json)
      render json: success_json
    end

    private

    def load_modes
      raw = SiteSetting.topic_content_view_modes
      return default_modes if raw.blank?
      parsed = JSON.parse(raw)
      parsed.is_a?(Array) ? parsed : default_modes
    rescue JSON::ParserError
      default_modes
    end

    def default_modes
      [
        {
          "value" => "content",
          "label" => "Content Only",
          "classes" => "tcv-mode",
          "css" => "",
          "preset" => true,
          "enabled" => true,
        },
        {
          "value" => "minimal",
          "label" => "Minimal",
          "classes" => "tcv-mode tcv-minimal",
          "css" => "",
          "preset" => true,
          "enabled" => true,
        },
        {
          "value" => "full",
          "label" => "Full",
          "classes" => "tcv-mode tcv-full",
          "css" => "",
          "preset" => true,
          "enabled" => true,
        },
      ]
    end
  end
end

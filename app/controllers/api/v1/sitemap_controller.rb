# frozen_string_literal: true

module Api
  module V1
    class SitemapController < PublicController
      STATIC_PATHS = %w[
        /
        /pricing
        /about
        /help
        /contact
        /privacy
        /blog
      ].freeze

      def show
        render xml: build_xml, content_type: "application/xml"
      end

      private

      def build_xml
        urls = STATIC_PATHS.map { |path| url_entry("#{site_base_url}#{path}") }
        BlogPost.published.order(published_at: :desc).pluck(:slug).each do |slug|
          urls << url_entry("#{site_base_url}/blog/#{slug}")
        end

        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
          #{urls.join("\n")}
          </urlset>
        XML
      end

      def url_entry(loc)
        "  <url><loc>#{ERB::Util.html_escape(loc)}</loc></url>"
      end

      def site_base_url
        base = ENV["SITE_URL"].presence || ENV["FRONTEND_ORIGIN"].presence || "http://localhost:5173"
        base.chomp("/")
      end
    end
  end
end

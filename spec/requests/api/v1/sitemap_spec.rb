# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Sitemap", type: :request do
  let!(:admin) { create_admin! }

  around do |example|
    original_site_url = ENV["SITE_URL"]
    original_frontend_origin = ENV["FRONTEND_ORIGIN"]
    ENV["SITE_URL"] = "https://www.cursorhelp.com"
    ENV.delete("FRONTEND_ORIGIN")
    example.run
  ensure
    if original_site_url
      ENV["SITE_URL"] = original_site_url
    else
      ENV.delete("SITE_URL")
    end
    if original_frontend_origin
      ENV["FRONTEND_ORIGIN"] = original_frontend_origin
    else
      ENV.delete("FRONTEND_ORIGIN")
    end
  end

  it "returns XML with static marketing paths and published blog slugs" do
    BlogPost.create!(
      title: "Sitemap Post",
      slug: "sitemap-post",
      author: admin,
      status: :published,
      published_at: 1.hour.ago
    )
    BlogPost.create!(
      title: "Draft Post",
      slug: "draft-post",
      author: admin,
      status: :draft
    )

    get "/api/v1/sitemap.xml"

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/xml")
    xml = response.body

    expect(xml).to include('<?xml version="1.0" encoding="UTF-8"?>')
    expect(xml).to include("<loc>https://www.cursorhelp.com/</loc>")
    expect(xml).to include("<loc>https://www.cursorhelp.com/pricing</loc>")
    expect(xml).to include("<loc>https://www.cursorhelp.com/blog</loc>")
    expect(xml).to include("<loc>https://www.cursorhelp.com/blog/sitemap-post</loc>")
    expect(xml).not_to include("draft-post")
  end

  it "falls back to FRONTEND_ORIGIN when SITE_URL is unset" do
    ENV.delete("SITE_URL")
    ENV["FRONTEND_ORIGIN"] = "http://localhost:5173"

    get "/api/v1/sitemap.xml"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("<loc>http://localhost:5173/pricing</loc>")
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::BlogPosts", type: :request do
  let!(:admin) { create_admin! }

  def create_post!(attrs = {})
    BlogPost.create!(
      {
        title: "Public Post",
        author: admin,
        status: :published,
        published_at: 1.hour.ago
      }.merge(attrs)
    )
  end

  describe "GET /api/v1/blog_posts" do
    it "returns published posts without body" do
      published = create_post!(title: "Visible Post", body: "<p>Secret HTML</p>")
      create_post!(title: "Draft Post", status: :draft, published_at: nil)
      create_post!(
        title: "Future Post",
        slug: "future-post",
        published_at: 1.day.from_now
      )

      get "/api/v1/blog_posts"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.length).to eq(1)
      expect(body.first["title"]).to eq("Visible Post")
      expect(body.first).not_to have_key("body")
      expect(body.first).to include("slug", "excerpt", "published_at", "author")
    end
  end

  describe "GET /api/v1/blog_posts/:slug" do
    it "returns a published post with body" do
      post = create_post!(slug: "my-slug", body: "<p>Full content</p>")

      get "/api/v1/blog_posts/my-slug"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["title"]).to eq("Public Post")
      expect(body["body"]).to eq("<p>Full content</p>")
    end

    it "returns not found for draft posts" do
      create_post!(slug: "draft-only", status: :draft, published_at: nil)

      get "/api/v1/blog_posts/draft-only"

      expect(response).to have_http_status(:not_found)
    end

    it "returns not found for missing slug" do
      get "/api/v1/blog_posts/does-not-exist"

      expect(response).to have_http_status(:not_found)
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Admin::BlogPosts", type: :request do
  let!(:admin) { create_admin! }
  let!(:user) { create_user_with_team.first }

  def create_post!(attrs = {})
    BlogPost.create!(
      {
        title: "Hello World",
        author: admin,
        status: :draft
      }.merge(attrs)
    )
  end

  describe "GET /api/v1/admin/blog_posts" do
    it "lists all blog posts" do
      post = create_post!(title: "Listed Post")

      get "/api/v1/admin/blog_posts", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.length).to eq(1)
      expect(body.first["title"]).to eq("Listed Post")
      expect(body.first).to include("body", "author", "cover_image_url")
    end

    it "returns forbidden for non-admin" do
      get "/api/v1/admin/blog_posts", headers: auth_headers(user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/v1/admin/blog_posts/:id" do
    it "shows a blog post" do
      post = create_post!(body: "<p>Full body</p>")

      get "/api/v1/admin/blog_posts/#{post.id}", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["slug"]).to eq("hello-world")
      expect(body["body"]).to eq("<p>Full body</p>")
      expect(body["author"]).to eq("name" => admin.name, "email" => admin.email)
    end
  end

  describe "POST /api/v1/admin/blog_posts" do
    it "creates a blog post with the current admin as author" do
      post "/api/v1/admin/blog_posts",
        params: {
          title: "New Post",
          excerpt: "Teaser",
          body: "<p>Content</p>",
          status: "draft"
        },
        headers: auth_headers(admin),
        as: :json

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["title"]).to eq("New Post")
      expect(body["slug"]).to eq("new-post")
      expect(body["author"]["email"]).to eq(admin.email)

      created = BlogPost.find(body["id"])
      expect(created.author).to eq(admin)
    end

    it "sanitizes HTML body on create" do
      post "/api/v1/admin/blog_posts",
        params: {
          title: "Sanitized Post",
          body: "<script>alert(1)</script><p>Safe</p><strong>Bold</strong>"
        },
        headers: auth_headers(admin),
        as: :json

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["body"]).to include("<p>Safe</p>", "<strong>Bold</strong>")
      expect(body["body"]).not_to include("<script", "script>")
    end

    it "attaches a cover image from signed_id" do
      file = fixture_file_upload(Rails.root.join("spec/fixtures/files/test.png"), "image/png")
      post "/api/v1/uploads",
        params: { file: file },
        headers: auth_headers(admin).except("Content-Type")
      signed_id = JSON.parse(response.body)["signed_id"]

      post "/api/v1/admin/blog_posts",
        params: {
          title: "With Cover",
          cover_image_signed_id: signed_id
        },
        headers: auth_headers(admin),
        as: :json

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["cover_image_url"]).to be_present
    end
  end

  describe "PATCH /api/v1/admin/blog_posts/:id" do
    it "updates a blog post and sets published_at when publishing" do
      post = create_post!

      patch "/api/v1/admin/blog_posts/#{post.id}",
        params: { status: "published", title: "Published Title" },
        headers: auth_headers(admin),
        as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["status"]).to eq("published")
      expect(body["published_at"]).to be_present
      expect(body["title"]).to eq("Published Title")
    end

    it "sanitizes HTML body on update" do
      post = create_post!

      patch "/api/v1/admin/blog_posts/#{post.id}",
        params: { body: "<img src=x onerror=alert(1)><p>Updated</p>" },
        headers: auth_headers(admin),
        as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["body"]).to eq("<img src=\"x\"><p>Updated</p>")
      expect(body["body"]).not_to include("onerror")
    end
  end

  describe "DELETE /api/v1/admin/blog_posts/:id" do
    it "destroys a blog post" do
      post = create_post!

      delete "/api/v1/admin/blog_posts/#{post.id}", headers: auth_headers(admin)

      expect(response).to have_http_status(:no_content)
      expect(BlogPost.exists?(post.id)).to be(false)
    end
  end
end

# frozen_string_literal: true

module Api
  module V1
    class BlogPostsController < PublicController
      def index
        posts = BlogPost.published.includes(:author).order(published_at: :desc).limit(50)
        render json: posts.map { |post| blog_post_json(post, include_body: false) }
      end

      def show
        post = BlogPost.published.includes(:author).find_by!(slug: params[:slug])
        render json: blog_post_json(post, include_body: true)
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Not found" }, status: :not_found
      end

      private

      def blog_post_json(post, include_body:)
        data = {
          id: post.id,
          title: post.title,
          slug: post.slug,
          excerpt: post.excerpt,
          status: post.status,
          published_at: post.published_at&.iso8601,
          created_at: post.created_at.iso8601,
          updated_at: post.updated_at.iso8601,
          meta_title: post.meta_title,
          meta_description: post.meta_description,
          cover_image_url: BlobUrl.for(post.cover_image),
          author: {
            name: post.author.name,
            email: post.author.email
          }
        }
        data[:body] = post.body if include_body
        data
      end
    end
  end
end

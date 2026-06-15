# frozen_string_literal: true

module Api
  module V1
    module Admin
      class BlogPostsController < BaseController
        def index
          posts = BlogPost.includes(:author).order(updated_at: :desc).limit(200)
          render json: posts.map { |post| blog_post_json(post) }
        end

        def show
          post = BlogPost.includes(:author).find(params[:id])
          render json: blog_post_json(post)
        end

        def create
          post = BlogPost.new(blog_post_params)
          post.author = current_user
          attach_blob!(post.cover_image, params[:cover_image_signed_id])

          if post.save
            render json: blog_post_json(post.reload), status: :created
          else
            render json: { error: post.errors.full_messages.first || "Could not create blog post" },
              status: :unprocessable_entity
          end
        rescue ActiveRecord::RecordInvalid => e
          render json: { error: e.message }, status: :unprocessable_entity
        end

        def update
          post = BlogPost.find(params[:id])
          post.assign_attributes(blog_post_params)
          attach_blob!(post.cover_image, params[:cover_image_signed_id])

          if post.save
            render json: blog_post_json(post.reload)
          else
            render json: { error: post.errors.full_messages.first || "Could not update blog post" },
              status: :unprocessable_entity
          end
        rescue ActiveRecord::RecordInvalid => e
          render json: { error: e.message }, status: :unprocessable_entity
        end

        def destroy
          post = BlogPost.find(params[:id])
          post.destroy!
          head :no_content
        end

        private

        def blog_post_params
          params.permit(:title, :slug, :excerpt, :body, :status, :meta_title, :meta_description)
        end

        def blog_post_json(post)
          {
            id: post.id,
            title: post.title,
            slug: post.slug,
            excerpt: post.excerpt,
            body: post.body,
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
        end
      end
    end
  end
end

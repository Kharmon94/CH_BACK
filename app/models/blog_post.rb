# frozen_string_literal: true

class BlogPost < ApplicationRecord
  ALLOWED_HTML_TAGS = %w[
    h1 h2 h3 h4 h5 h6 p ul ol li a img blockquote pre code strong em u br hr
  ].freeze
  ALLOWED_HTML_ATTRIBUTES = %w[href src alt title class target rel].freeze

  belongs_to :author, class_name: "User"

  has_one_attached :cover_image

  enum :status, { draft: 0, published: 1 }, validate: true

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :meta_description, length: { maximum: 160 }, allow_blank: true

  before_validation :assign_slug, on: :create
  before_save :sanitize_body_html
  before_save :stamp_published_at

  scope :published, -> {
    where(status: :published)
      .where.not(published_at: nil)
      .where("published_at <= ?", Time.current)
  }

  private

  def assign_slug
    return if slug.present?

    base = title.to_s.parameterize.presence || "post"
    candidate = base
    n = 2
    while BlogPost.where(slug: candidate).where.not(id: id).exists?
      candidate = "#{base}-#{n}"
      n += 1
    end
    self.slug = candidate
  end

  def sanitize_body_html
    return if body.blank?

    self.body = ActionController::Base.helpers.sanitize(
      body,
      tags: ALLOWED_HTML_TAGS,
      attributes: ALLOWED_HTML_ATTRIBUTES
    )
  end

  def stamp_published_at
    return unless published? && published_at.blank?

    self.published_at = Time.current
  end
end

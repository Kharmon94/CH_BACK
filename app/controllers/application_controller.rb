# frozen_string_literal: true

class ApplicationController < ActionController::API
  include CanCan::ControllerAdditions
  include ActiveStorageAttachable

  rescue_from CanCan::AccessDenied do |e|
    render json: { error: "Access denied", message: e.message }, status: :forbidden
  end

  def current_user
    @current_user
  end

  def current_ability
    @current_ability ||= Ability.new(current_user)
  end

  private

  def authenticate_user!
    token = bearer_token
    if token.blank?
      render json: { error: "Unauthorized" }, status: :unauthorized
      return
    end
    payload = JwtService.decode(token)
    if payload.blank?
      render json: { error: "Unauthorized" }, status: :unauthorized
      return
    end
    @current_user = User.find_by(id: payload[:sub])
    if @current_user.blank?
      render json: { error: "Unauthorized" }, status: :unauthorized
      nil
    end
  end

  def bearer_token
    h = request.headers["Authorization"].to_s
    return nil if h.blank?

    h.sub(/^Bearer\s+/i, "").strip.presence
  end
end

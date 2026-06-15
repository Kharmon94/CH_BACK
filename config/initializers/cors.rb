Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins [
      *FrontendOrigin.origins_from_env,
      ENV["FRONTEND_URL"],
      "http://localhost:5173",
      "http://127.0.0.1:5173",
      "https://www.cursorhelp.com",
      "https://cursorhelp.com"
    ].compact_blank.uniq

    resource "/api/*",
      headers: :any,
      methods: [ :get, :post, :patch, :delete, :options ]
  end
end

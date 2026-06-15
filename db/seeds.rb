# frozen_string_literal: true

# Idempotent demo accounts for local dev and explicit staging opt-in (SEED_DEMO_USERS=true).
unless Rails.env.development? || Rails.env.desktop? || ENV["SEED_DEMO_USERS"] == "true"
  puts "Skipping demo user seeds (development only, or set SEED_DEMO_USERS=true)"
else
  password = ENV["SEED_DEMO_PASSWORD"].presence
  password ||= "password123" if Rails.env.development?

  if password.blank?
    warn "Skipping demo user seeds: set SEED_DEMO_PASSWORD (no default outside development)"
  else
    seed_demo_user = lambda do |email:, role:, name:, provision_team: false, license_tier: nil|
      user = User.find_or_initialize_by(email: email)
      user.assign_attributes(
        password: password,
        password_confirmation: password,
        role: role,
        name: name
      )
      user.save!

      if provision_team
        team = user.teams.first || TeamProvisioner.call(user)
        license = team.license || team.create_license!(tier: "free")
        license.update!(tier: license_tier, status: license_tier == "pro" ? "active" : license.status)
      end

      user
    end

    seed_demo_user.call(
      email: "admin@cursorhelp.com",
      role: :admin,
      name: "Admin Demo"
    )

    seed_demo_user.call(
      email: "free@cursorhelp.com",
      role: :user,
      name: "Free Demo",
      provision_team: true,
      license_tier: "free"
    )

    seed_demo_user.call(
      email: "pro@cursorhelp.com",
      role: :user,
      name: "Pro Demo",
      provision_team: true,
      license_tier: "pro"
    )

    password_hint =
      if Rails.env.development? && ENV["SEED_DEMO_PASSWORD"].blank?
        "password123 (development default)"
      else
        "value of SEED_DEMO_PASSWORD"
      end

    puts "Demo accounts seeded (password: #{password_hint}):"
    puts "  admin@cursorhelp.com — admin (no team)"
    puts "  free@cursorhelp.com — user, free tier"
    puts "  pro@cursorhelp.com — user, pro tier (active)"
  end
end

module Cursor
  class WorkspaceInferrer
    ABSOLUTE_PATH = %r{/home/vgxd/Projects/Production Projects/[^/\s"']+}

    PROJECT_HINTS = {
      /future_scope_labs|FutureScope/i => "FutureScope",
      /sour_api|sour_frontend|SourAudio/i => "SourAudio"
    }.freeze

    def self.infer(turns)
      new(turns).infer
    end

    def initialize(turns)
      @turns = turns
    end

    def infer
      corpus = @turns.map { |_, text| text }.join("\n")
      roots = corpus.scan(ABSOLUTE_PATH).uniq

      PROJECT_HINTS.each do |pattern, folder|
        roots << "/home/vgxd/Projects/Production Projects/#{folder}" if corpus.match?(pattern)
      end

      roots = roots.uniq.sort
      primary = roots.find { |r| r.include?("SourAudio") } || roots.first
      { primary: primary, all: roots }
    end

    def self.describe_workspace(path)
      return nil unless path

      hints = []
      hints << "- API: `sour_api/` (Rails)" if path.include?("SourAudio")
      hints << "- Frontend: `sour_frontend/` (React + Vite)" if path.include?("SourAudio")
      hints << "- Deployed on **Railway** with Stripe keys in env" if path.include?("SourAudio")
      hints
    end
  end
end

module AgentClone
  class Template
    COMPLETION_MARKERS = [
      "Here's what was",
      "Members can now",
      "was added",
      "Here's what I",
      "All backend and frontend tests pass",
      "Manual pass"
    ].freeze

    INCOMPLETE_STARTS = [
      "Tracing",
      "Exploring",
      "Investigating",
      "Searching",
      "Checking",
      "Fixing the",
      "Implementing the full",
      "Implementing member"
    ].freeze

    def initialize(group:, composers:, bubbles:, filename:)
      @group = group
      @composers = composers
      @bubbles = bubbles
      @filename = filename
      @ordered = composers.sort_by { |_, p| p["createdAt"].to_i }
      @primary_id = group.primary_composer_id
      @primary_payload = composers[@primary_id]
      @primary_turns = collapse_assistant_turns(extract_turns(@primary_id, @primary_payload))
    end

    def render
      lines = []
      lines << "## Start here"
      lines << ""
      lines << "```"
      lines << paste_prompt
      lines << "```"
      lines << ""
      lines.concat(instructions_section)
      lines.concat(pick_up_section)
      lines.concat(active_workspace_section)
      lines.concat(decisions_section)
      lines.concat(completed_section)
      lines.concat(other_workspaces_section)
      lines.concat(sessions_table_section)
      lines.concat(session_sections)
      lines.join("\n")
    end

    private

    def paste_prompt
      "Restore and continue the agent session in #{@filename}. You are the same agent — read the full document, honor all decisions, do not redo completed work, and finish the task in \"Pick up here\" unless I say otherwise. Implement directly; do not only plan."
    end

    def instructions_section
      [
        "## Instructions for you (the new agent)",
        "",
        "You are **continuing an existing agent session**, not starting fresh.",
        "",
        "- Treat everything below as **memory and established context**.",
        "- **Do not** re-ask questions already answered in the conversation.",
        "- **Do not** re-implement work described as done unless you verify it is missing.",
        "- **Verify repo state first** — the previous agent hit tool failures at the end; changes may not have been saved.",
        "- **Default behavior:** same tone, same standards, execute tasks end-to-end, run tests/builds, fix what you break.",
        "- If the user says **retry**, resume the interrupted task immediately.",
        ""
      ]
    end

    def pick_up_section
      last_user = ""
      last_assistant = ""
      @primary_turns.each do |role, text|
        last_user = text if role == "user"
        last_assistant = text if role == "assistant"
      end

      out = [ "## Pick up here (unfinished — prioritize this)", "" ]
      if last_user.present?
        out << "**Last user message:**"
        out << ""
        out << last_user
        out << ""
      end
      if last_assistant.present?
        out << "**Last agent state (when session broke):**"
        out << ""
        out << last_assistant
        out << ""
      end
      out
    end

    def active_workspace_section
      all_turns = @primary_turns.dup
      @ordered.each do |composer_id, payload|
        next if composer_id == @primary_id

        all_turns.concat(extract_turns(composer_id, payload))
      end
      workspace = Cursor::WorkspaceInferrer.infer(all_turns)
      primary = workspace[:primary] || "/home/vgxd/Projects/Production Projects/SourAudio"

      out = [ "## Active workspace (open this in Cursor)", "", "`#{primary}`", "" ]
      Cursor::WorkspaceInferrer.describe_workspace(primary)&.each { |line| out << line }
      out << ""
      out
    end

    def decisions_section
      decisions = collect_decisions(@primary_turns)
      return [] if decisions.empty?

      out = [ "## Decisions already made (do not re-debate)", "" ]
      decisions.each { |d| out << "- #{d}" }
      out << ""
      out
    end

    def completed_section
      completed = summarize_completed_work(@primary_turns)
      return [] if completed.empty?

      out = [ "## Completed in the primary session (verify before redoing)", "" ]
      completed.each do |request, outcome|
        out << "- **Request:** #{request}"
        out << "  **Outcome:** #{outcome}"
      end
      out << ""
      out
    end

    def other_workspaces_section
      all_turns = []
      @ordered.each { |cid, payload| all_turns.concat(extract_turns(cid, payload)) }
      roots = Cursor::WorkspaceInferrer.infer(all_turns)[:all]
      primary = Cursor::WorkspaceInferrer.infer(@primary_turns)[:primary]
      other = roots.reject { |r| primary && r == primary }

      out = [ "## Other workspaces referenced", "" ]
      if other.any?
        other.each { |root| out << "- `#{root}` _(earlier session context)_" }
      else
        out << "- _(none beyond primary workspace)_"
      end
      out << ""
      out
    end

    def sessions_table_section
      out = [
        "## Sessions in this handoff",
        "",
        "| # | Mode | Status | Messages | Updated | Role |",
        "|---|------|--------|----------|---------|------|"
      ]
      @ordered.each_with_index do |(composer_id, payload), index|
        mode = payload["unifiedMode"] || payload["forceMode"] || "unknown"
        status = payload["status"] || "unknown"
        headers = payload["fullConversationHeadersOnly"] || []
        updated = format_timestamp(payload["lastUpdatedAt"])
        role = composer_id == @primary_id ? "**PRIMARY**" : "context"
        out << "| #{index + 1} | #{mode} | #{status} | #{headers.length} | #{updated} | #{role} |"
      end
      out << ""
      out
    end

    def session_sections
      out = []
      @ordered.each_with_index do |(composer_id, payload), index|
        turns = extract_turns(composer_id, payload)
        name = payload["name"] || composer_id

        if turns.empty?
          out << "## Session #{index + 1} — #{name} (no recoverable messages)"
          out << ""
          out << "> Bubble data was pruned from the database for this aborted session."
          out << ""
          next
        end

        turns = collapse_assistant_turns(turns)
        mode = payload["unifiedMode"] || payload["forceMode"] || "unknown"
        status = payload["status"] || "unknown"
        updated = format_timestamp(payload["lastUpdatedAt"])
        label = composer_id == @primary_id ? " (PRIMARY — resume here)" : ""

        out << "## Session #{index + 1}#{label}: #{name}"
        out << ""
        out << "- Mode: #{mode} | Status: #{status} | Updated: #{updated}"
        out << "- Composer ID: `#{composer_id}`"
        out << ""
        out << "### Conversation"
        out << ""

        todos = payload["todos"]
        if todos.is_a?(Array) && todos.any?
          out << "### Tasks"
          out << ""
          todos.each do |todo|
            next unless todo.is_a?(Hash)

            content = todo["content"].to_s.strip
            next if content.blank?

            out << "- [#{todo['status'] || 'unknown'}] #{content}"
          end
          out << ""
        end

        turns.each do |role, text|
          heading = role == "user" ? "User" : "Assistant"
          out << "#### #{heading}"
          out << ""
          out << text
          out << ""
          out << "---"
          out << ""
        end
      end
      out
    end

    def extract_turns(composer_id, payload)
      turns = []
      (payload["fullConversationHeadersOnly"] || []).each do |header|
        next unless header.is_a?(Hash)

        bubble_id = header["bubbleId"]
        bubble_type = header["type"]
        next unless bubble_id

        bubble = @bubbles[[ composer_id, bubble_id ]]
        next unless bubble

        message = Cursor::MessageTextExtractor.extract(bubble, include_tools: false)
        next if message.blank?

        role = bubble_type == 1 ? "user" : "assistant"
        turns << [ role, message ]
      end
      turns
    end

    def collapse_assistant_turns(turns)
      collapsed = []
      turns.each do |role, text|
        if collapsed.any? && role == "assistant" && collapsed.last[0] == "assistant"
          prev_role, prev_text = collapsed.last
          collapsed[-1] = [ prev_role, "#{prev_text}\n\n#{text}" ]
        else
          collapsed << [ role, text ]
        end
      end
      collapsed
    end

    def collect_decisions(turns)
      corpus = turns.map { |_, t| t }.join("\n")
      decisions = []
      if corpus.include?("platform Stripe account for admin events")
        decisions << "Admin-created events (no organizer) must checkout on the **platform** Stripe account — not Stripe Connect."
      end
      if corpus.include?("Artist-organized") || corpus.include?('organizer_type = "Artist"')
        decisions << "Artist-created events keep the existing **Stripe Connect** destination-charge flow."
      end
      if corpus.include?("dollars and cents usd") || corpus.include?("USD field")
        decisions << "Event ticket prices are entered in **USD dollars** in the UI (e.g. $10.25); API still stores cents."
      end
      if corpus.include?("STRIPE_WEBHOOK_SECRET") || corpus.include?("checkout.session.completed")
        decisions << "Stripe webhook + Railway env vars are configured; verify flows after code changes."
      end
      if corpus.include?("display_name") && corpus.include?("username")
        decisions << "Members can set **display name** and **username** in Settings (already implemented)."
      end
      decisions
    end

    def summarize_completed_work(turns)
      items = []
      pending_user = nil
      turns.each do |role, text|
        if role == "user"
          pending_user = user_request_line(text)
        elsif role == "assistant" && pending_user
          if COMPLETION_MARKERS.any? { |m| text.include?(m) }
            headline = text.strip.lines.first.to_s.strip
            unless INCOMPLETE_STARTS.any? { |s| headline.start_with?(s) }
              headline = headline[0, 120] + "..." if headline.length > 120
              items << [ pending_user, headline ]
            end
          end
          pending_user = nil
        end
      end
      items
    end

    def user_request_line(text)
      line = text.strip.lines.first.to_s.strip
      return nil if line.start_with?("2026-") || line.include?("[inf]") || line.include?("[err]")
      return nil if line.length < 4

      line = line[0, 160] + "..." if line.length > 160
      line
    end

    def format_timestamp(ms)
      return "" unless ms.is_a?(Numeric) && ms.positive?

      Time.at(ms / 1000.0).utc.strftime("%Y-%m-%d %H:%M UTC")
    rescue StandardError
      ""
    end
  end
end

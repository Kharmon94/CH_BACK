module Cursor
  class MessageTextExtractor
    BUBBLE_TYPE_LABEL = { 1 => "User", 2 => "Assistant" }.freeze

    def self.extract(payload, include_tools: false)
      new(payload, include_tools: include_tools).extract
    end

    def self.role_label(bubble_type)
      BUBBLE_TYPE_LABEL[bubble_type] || "Type #{bubble_type}"
    end

    def initialize(payload, include_tools: false)
      @payload = payload
      @include_tools = include_tools
    end

    def extract
      return "" unless @payload.is_a?(Hash)

      text = @payload["text"]
      return text.strip if text.is_a?(String) && text.strip.present?

      rich_text = @payload["richText"]
      if rich_text.is_a?(String) && rich_text.strip.present?
        lexical = extract_lexical_text(rich_text)
        return lexical.join("\n") if lexical.any?
      end

      return format_tool_bubble(@payload) if @include_tools

      ""
    end

    private

    def extract_lexical_text(rich_text)
      tree = JSON.parse(rich_text)
      texts = []
      walk(tree) { |node| texts << node["text"].strip if node.is_a?(Hash) && node["type"] == "text" && node["text"].is_a?(String) && node["text"].strip.present? }
      texts
    rescue JSON::ParserError
      []
    end

    def walk(node, &block)
      case node
      when Hash
        yield node
        node.each_value { |child| walk(child, &block) }
      when Array
        node.each { |child| walk(child, &block) }
      end
    end

    def format_tool_bubble(payload)
      tool_data = payload["toolFormerData"]
      return "" unless tool_data

      tool_data = JSON.parse(tool_data) if tool_data.is_a?(String)
      return "" unless tool_data.is_a?(Hash)

      name = tool_data["name"] || "tool"
      status = tool_data["status"] || "unknown"
      raw_args = tool_data["rawArgs"] || tool_data["params"] || ""
      raw_args = JSON.pretty_generate(raw_args) if raw_args.is_a?(Hash)

      lines = [ "**Tool:** `#{name}` (#{status})" ]
      if raw_args.present?
        lines << ""
        lines << "```json"
        lines << raw_args.to_s.strip[0, 4000]
        lines << "```"
      end
      lines.join("\n")
    rescue JSON::ParserError
      ""
    end
  end
end

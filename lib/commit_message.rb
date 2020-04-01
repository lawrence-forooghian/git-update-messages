class CommitMessage
  attr_reader :original_message

  MIN_PREFIX_LENGTH = 7

  def initialize(original_message)
    @original_message = original_message
  end

  def updated_message(old_sha, new_sha)
    updated_message = original_message.dup

    old_sha.length.downto(MIN_PREFIX_LENGTH) do |prefix_length|
      break if updated_message.gsub!(old_sha[0...prefix_length], new_sha[0...prefix_length])
    end

    updated_message
  end

  def message_needs_update?(old_sha, new_sha)
    updated_message(old_sha, new_sha) != original_message
  end
end

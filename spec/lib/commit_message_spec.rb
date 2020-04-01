require "spec_helper"
require File.join(__FILE__, "..", "..", "..", "lib", "commit_message")
require "digest"

RSpec.describe CommitMessage do
  describe "#updated_message" do
    def message_referring_to(reference)
      <<~MESSAGE
        Do a thing

        This is a thing that I first did in #{reference}, but when I did it in #{reference}
        I did it wrong. But the general idea of #{reference} was good.
      MESSAGE
    end

    let(:original_sha) { Digest::SHA1.hexdigest(Kernel.rand.to_s) }
    let(:new_sha) { Digest::SHA1.hexdigest(Kernel.rand.to_s) }

    it "returns an updated message when the message contains a 7-character prefix of the old SHA" do
      original_message = message_referring_to(original_sha[0...7])

      updated_message = CommitMessage.new(original_message).updated_message(original_sha, new_sha)

      expect(updated_message).to eq(message_referring_to(new_sha[0...7]))
    end

    it "returns the original message when the message contains a 7-character suffix of the old SHA" do
      original_message = message_referring_to(original_sha[-7..-1])

      updated_message = CommitMessage.new(original_message).updated_message(original_sha, new_sha)

      expect(updated_message).to eq(original_message)
    end

    it "returns the original message when the message contains a prefix shorter than 7 characters of the old SHA" do
      original_message = message_referring_to(original_sha[0..5])

      updated_message = CommitMessage.new(original_message).updated_message(original_sha, new_sha)

      expect(updated_message).to eq(original_message)
    end

    # TODO Test multiple references to the same commit, with different prefix lengths
    # TODO Test references to multiple commits
  end
end

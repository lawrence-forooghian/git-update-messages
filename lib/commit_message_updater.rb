require File.join(__FILE__, "..", "commit_message")
require "rugged"

class CommitMessageUpdater
  attr_reader :repo_path, :mapped_shas

  def initialize(repo_path, mapped_shas)
    @repo_path = repo_path
    @mapped_shas = mapped_shas
  end

  def update
    repo = Rugged::Repository.new(repo_path)

    # We rebase onto the earliest commit that was rewritten in the
    # original rebase.
    onto_sha = mapped_shas.first[1]
    rebase = Rugged::Rebase.new(repo, repo.head, onto_sha, inmemory: true)

    # Apply the first patch.
    current_patch = rebase.next

    last_committed_sha = nil

    while current_patch
      cherry_picked = repo.lookup(current_patch[:id])

      # Now we can get the commit message and amend it if necessary.
      new_message = cherry_picked.message
      if message_needs_update?(cherry_picked)
        new_message = updated_message(cherry_picked)
      end

      # Commit the patch we just applied, preserving the committer information.
      last_committed_sha = rebase.commit(committer: cherry_picked.committer, message: new_message)

      # Update the mapped_shas to include the new SHA for the commit
      # that we just cherry picked.
      update_mapped_shas(cherry_picked.oid, last_committed_sha)

      # Apply the next patch.
      current_patch = rebase.next
    end

    finish(repo, rebase)

    # In-memory rebase doesn’t move HEAD, so we need to
    repo.reset(last_committed_sha, :soft)
  end

  def messages_need_updating?
    repo = Rugged::Repository.new(repo_path)

    walker = Rugged::Walker.new(repo)
    walker.push(mapped_shas.last[1])

    walker.any? do |commit|
      message_needs_update?(commit)
    end
  end

  private

  def message_needs_update?(commit)
    mapped_shas.any? do |(old, new)|
      CommitMessage.new(commit.message).message_needs_update?(old, new)
    end
  end

  def updated_message(commit)
    mapped_shas.reduce(commit.message) do |message, (old, new)|
      CommitMessage.new(message).updated_message(old, new)
    end
  end

  def update_mapped_shas(old, new)
    original_mapping = mapped_shas.find { |(_, original_new)|
      original_new == old
    }

    original_mapping[1] = new
  end

  def finish(repo, rebase)
    # Rugged::Rebase#finish needs a committer. It’s used by libgit2’s
    # git_rebase_finish to rewrite commit notes.
    #
    # The argument is optional in libgit2 but required in Rugged. I asked about
    # this in https://libgit2.slack.com/archives/C1BS8MML7/p1582450830005300.
    # In libgit2, in the absence of a committer it derives it using
    # git_signature_default, and if that fails then it falls back to “unknown”.
    # So I’m just copying that behaviour.
    signature = repo.default_signature || {name: "unknown", email: "unknown", time: Time.now}
    rebase.finish(signature)
  end
end

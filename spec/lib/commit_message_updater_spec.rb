require "spec_helper"
require "rugged"
require "digest"
require File.join(__FILE__, "..", "..", "..", "lib", "commit_message_updater")
require File.join(__FILE__, "..", "..", "support", "example_repo")

RSpec.describe CommitMessageUpdater do
  describe "#update" do
    context "given a rebased Git repository with a sequence of commits whose messages each contain the first seven characters of the SHA of the parent of the pre-rebase commit" do
      let!(:example_repo) { ExampleRepo.new(rebased: true, commit_count: 5, suffix_lengths: [7, 13, 30, 40]) }

      context "when called with a list of old and new SHAs, as given by the post-rewrite Git hook, with no repeated new SHAs" do
        it "updates the commit messages of all the commits to refer to the new SHAs" do
          CommitMessageUpdater.new(example_repo.repo_path, example_repo.mapped_shas).update

          repo = Rugged::Repository.new(example_repo.repo_path)
          walker = Rugged::Walker.new(repo)
          walker.push(repo.head.target.oid)

          commits = walker.to_a.reverse
          expect(commits[4].message).to eq("Commit 4, referring to parent #{commits[3].oid[0...40]}")
          expect(commits[3].message).to eq("Commit 3, referring to parent #{commits[2].oid[0...30]}")
          expect(commits[2].message).to eq("Commit 2, referring to parent #{commits[1].oid[0...13]}")
          expect(commits[1].message).to eq("Commit 1, referring to parent #{commits[0].oid[0...7]}")
          expect(commits[0].message).to eq("Commit 0")

          commits.each { |commit| expect(commit.committer).to include(name: "Test Committer", email: "test-committer@example.com") }
        end
      end
    end
  end

  # TODO Update the tests to reflect that git rebase actually gives you even
  # the root commit, and commits that it didn’t change. i.e. make it more
  # representative of the actual output

  # TODO Test referring to ancestors further than parents

  describe "#messages_need_updating?" do
    context "given a rebased Git repository with a sequence of commits whose messages each contain the first seven characters of the SHA of the parent of the pre-rebase commit" do
      let!(:example_repo) { ExampleRepo.new(rebased: true, commit_count: 5, suffix_lengths: [7, 13, 30, 40]) }

      it "returns true" do
        updater = CommitMessageUpdater.new(example_repo.repo_path, example_repo.mapped_shas)
        expect(updater.messages_need_updating?).to eq(true)
      end
    end

    context "given a rebased Git repository with a sequence of commits whose messages don’t refer to their ancestors" do
      let!(:example_repo) { ExampleRepo.new(rebased: true, commit_count: 5, suffix_lengths: Array.new(4, 0)) }

      it "returns false" do
        updater = CommitMessageUpdater.new(example_repo.repo_path, example_repo.mapped_shas)
        expect(updater.messages_need_updating?).to eq(false)
      end
    end
  end
end

require "spec_helper"
require "rugged"
require "digest"
require File.join(__FILE__, "..", "..", "support", "example_repo")

RSpec.describe "Performing a rebase with the post-rewrite hook installed" do
  context "given a Git repository with a sequence of commits whose messages each contain the first seven characters of the SHA of their parent" do
    let!(:example_repo) { ExampleRepo.new(rebased: false, commit_count: 5, suffix_lengths: [7, 13, 30, 40]) }

    context "when we do an interactive rebase when the post-rewrite hook is installed" do
      # TODO I’ve just realised that we could have just tested a
      # non-interactive rebase, although I suppose it's good to know that the
      # interactive one works too. Write a test case for the example given in
      # the README
      it "rewrites the commit messages of all the commits to refer to the new SHAs" do
        example_repo.install_hook

        env = {
          # The first command is for editing the rebase-todo, second is for editing the commit message
          # pick 9039de3 Commit 0
          # pick bc2f4df Commit 1, referring to parent 9039de3
          # pick b90969f Commit 2, referring to parent bc2f4df779d4d
          # pick ed1e3f9 Commit 3, referring to parent b90969fccc9ce80dfc412388549059
          # pick a284403 Commit 4, referring to parent ed1e3f9f6f3ea9a626aacba523c7a365a9dde2f2
          "EDITOR" => 'sed -i -e \'s/\(pick\)\( [a-z0-9]\{1,\} Commit 0\)/reword\2/;s/^Commit 0$/Commit 0, reworded/\'',

          "GIT_COMMITTER_NAME" => "Test Rebaser",
          "GIT_COMMITTER_EMAIL" => "test-rebaser@example.com",

          "GIT_AUTHOR_NAME" => "Test User",
          "GIT_AUTHOR_EMAIL" => "test-user@example.com",

          # See documentation of GIT_CONFIG_NOSYSTEM in git(1) for suggestion
          # of how to create a predictable environment
          "HOME" => "",
          "XDG_CONFIG_HOME" => "",
          "GIT_CONFIG_NOSYSTEM" => "1",
        }

        Dir.chdir(example_repo.repo_path) do
          system(env, "git", "rebase", "-i", "--root", exception: true)
        end

        repo = Rugged::Repository.new(example_repo.repo_path)
        walker = Rugged::Walker.new(repo)
        walker.push(repo.head.target.oid)

        commits = walker.to_a.reverse
        expect(commits[4].message).to eq("Commit 4, referring to parent #{commits[3].oid[0...40]}")
        expect(commits[3].message).to eq("Commit 3, referring to parent #{commits[2].oid[0...30]}")
        expect(commits[2].message).to eq("Commit 2, referring to parent #{commits[1].oid[0...13]}")
        expect(commits[1].message).to eq("Commit 1, referring to parent #{commits[0].oid[0...7]}")
        expect(commits[0].message).to eq("Commit 0, reworded\n")

        commits.each { |commit| expect(commit.committer).to include(name: "Test Rebaser", email: "test-rebaser@example.com") }
      end
    end
  end
end

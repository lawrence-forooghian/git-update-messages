class ExampleRepo
  attr_reader :repo, :new_shas, :rebased, :commit_count, :suffix_lengths

  def initialize(rebased:, commit_count: 5, suffix_lengths:)
    @rebased = rebased
    @commit_count = commit_count
    @suffix_lengths = suffix_lengths
    @new_shas = []
    @repo = create_repo
  end

  def repo_path
    @repo_path ||= File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "example"))
  end

  def old_shas
    @old_shas ||= Array.new(commit_count - 1) { Digest::SHA1.hexdigest(Kernel.rand.to_s) }
  end

  def mapped_shas
    old_shas.zip(new_shas)
  end

  def install_hook
    old = Pathname.new(repo_path).join(".git", "hooks", "post-rewrite")
    new = Pathname.new(__FILE__) + ".." + ".." + ".." + "bin" + "hooks" + "post-rewrite"

    old.make_symlink(new)
  end

  private

  def create_repo
    FileUtils.rm_rf(repo_path) if File.exist?(repo_path)

    repo = Rugged::Repository.init_at(repo_path)

    commit_count.times do |i|
      oid = repo.write("This is blob #{i}.", :blob)
      index = repo.index
      index.add(path: "README.md", oid: oid, mode: 0o100644)

      options = {}
      options[:tree] = index.write_tree(repo)

      now = Time.now
      options[:author] = {email: "test-author@example.com", name: "Test Author", time: now}
      options[:committer] = {email: "test-committer@example.com", name: "Test Committer", time: now}
      suffix_length = suffix_lengths[i - 1]
      options[:message] = if rebased && i > 1
        "Commit #{i}, referring to parent #{old_shas[i - 2][0...suffix_length]}"
      elsif i > 0
        "Commit #{i}, referring to parent #{repo.head.target.oid[0...suffix_length]}"
      else
        "Commit #{i}"
      end
      options[:parents] = repo.empty? ? [] : [repo.head.target].compact
      options[:update_ref] = "HEAD"

      oid = Rugged::Commit.create(repo, options)

      new_shas << oid if i > 0
    end

    repo.checkout_head
  end
end

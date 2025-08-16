# What does it do?

After a Git rebase, it fixes commit messages which contain outdated references
to other commits.

# Give me an example.

## The background

Imagine that we’re doing a refactor to get our app ready to support many
languages. We start doing our work on a feature branch.

In our first two commits, we do all the refactoring for the classes related to
invoices. It’s a complicated refactor. We use our commit messages to explain
ourselves in detail. Our feature branch looks like this, oldest first:

```
01b7d68 Extract invoice view strings to locale file

        We do it like this because (long explanation of approach and tricky
        things about it)

7dc3e8f Pass invoice-related strings to the MagicAuth gem

        We have to do this because (long explanation of approach and tricky
        things about it)
```

Now we go on to refactor the rest of the app, following the same approach as
the first two commits.

We don’t want to repeat all that long explanation again, so in our commit
messages we just refer to the commits where we introduced the approach. So the
rest of our feature branch looks like this:

```
fa0404c Extract supplier view strings to locales file

        This follows the same approach as 01b7d68.

3b29442 Pass supplier-related strings to the MagicAuth gem

        This follows the same approach as 7dc3e8f.

…and so on, for other parts of the app.
```

## The problem

Somebody has introduced some changes into the upstream branch `origin/master`.
We want to pull these changes into our feature branch. So we do `git rebase
origin/master`. After the rebase is finished, our branch looks like this:

```
3e870d4 Extract invoice view strings to locale file

        We do it like this because (long explanation of approach and tricky
        things about it)

7b33c97 Pass invoice-related strings to the MagicAuth gem

        We have to do this because (long explanation of approach and tricky
        things about it)

63c2d81 Extract supplier view strings to locales file

        This follows the same approach as 01b7d68.

fbfe0ed Pass supplier-related strings to the MagicAuth gem

        This follows the same approach as 7dc3e8f.

…and so on.
```

Now we have a problem - the commit messages for `63c2d81` and `fbfe0ed` refer
to commits that no longer exist on our branch.

## The solution

With `git-update-messages` installed, when the rebase finishes you‘ll see a message:

```
update-messages: Updated commit messages.
```

…and it will have automatically fixed your commit messages:

```
3e870d4 Extract invoice view strings to locale file

        We do it like this because (long explanation of approach and tricky
        things about it)

7b33c97 Pass invoice-related strings to the MagicAuth gem

        We have to do this because (long explanation of approach and tricky
        things about it)

63c2d81 Extract supplier view strings to locales file

        This follows the same approach as 3e870d4.

fbfe0ed Pass supplier-related strings to the MagicAuth gem

        This follows the same approach as 7b33c97.

…and so on.
```

# How do I install it?

## Requirements

- Ruby - the installation steps assume that you are using [rbenv](https://github.com/rbenv/rbenv) or [asdf](https://github.com/asdf-vm/asdf) to manage your Ruby installation

## Steps

### rbenv

1. Clone the repository and `cd` into it.
2. Run `rbenv install && bundle install`.
   - If you get an error when installing the Rugged gem, you may need to install `cmake` (`brew install cmake` on a Mac).
3. Copy `bin/rbenv/hooks/post-rewrite` to your Git hooks path.
   - This might be `.git/hooks` in a specific repository, or a path that you've
     configured globally as `core.hooksPath`. It depends on how you like to use
     Git.
4. Edit the file that you just created, setting `TOOL_PATH` to the path of this
   repository on your computer.

### asdf

1. Clone the repository and `cd` into it.
2. Run `asdf install && bundle install`.
   - If you get an error when installing the Rugged gem, you may need to install `cmake` (`brew install cmake` on a Mac).
3. Copy `bin/asdf/hooks/post-rewrite` to your Git hooks path.
   - This might be `.git/hooks` in a specific repository, or a path that you've
     configured globally as `core.hooksPath`. It depends on how you like to use
     Git.
4. Edit the file that you just created, setting `TOOL_PATH` to the path of this
   repository on your computer.

# Notes

- It will only modify abbreviated commit SHAs that are at least 7 characters long.

# Possible future improvements

- installation experience
   - package as a gem?
   - Rake task to generate a repo to test the installation

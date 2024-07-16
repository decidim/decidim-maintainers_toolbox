# frozen_string_literal: true

require_relative "changelog_generator"
require_relative "releaser_utils"
require_relative "github_manager/poster"

module Decidim
  module MaintainersToolbox
    # Creates a release candidate version for this branch
    #
    # If we are in develop (i.e. v0.30.0.dev) it will create the rc1 (i.e. v0.30.0.rc1)
    # If we are in the stable release with an rc (i.e. v0.30.0.rc1) it will create the next rc (i.e. v0.30.0.rc2)
    # If we are in the stable release with a patch (i.e. v0.30.0) it will bail out
    class ReleaseCandidateVersion
      include Decidim::MaintainersToolbox::ReleaserUtils

      # @param token [String] token for GitHub authentication
      # @param working_dir [String] current working directory. Useful for testing purposes
      def initialize(token:, working_dir: Dir.pwd)
        @token = token
        @working_dir = working_dir
        @old_version_number = old_version_number
      end

      def call
        check_branch_and_version_sanity

        prepare_next_development_version
        prepare_next_release_candidate_version
      end

      # The version number for the release that we are preparing
      #
      # @return [String] the version number
      def version_number
        @version_number ||= next_version_number_for_release_candidate(@old_version_number)
      end

      private

      # Returns the next branch that needs to be created for the RC.
      #
      # @return [String]
      def release_branch
        @release_branch ||= begin
          major, minor, _patch = parsed_version_number(version_number)

          "release/#{major}.#{minor}-stable"
        end
      end

      def check_branch_and_version_sanity
        return if develop_branch? && dev_version_number?
        return if release_branch? && rc_version_number?

        error_message = <<-EOERROR
        Check if the branch is valid for a release candidate. It should be: 
        - develop with a dev version (i.e. develop branch with 0.30.0.dev decidim version)
        - stable branch with a release candidate version (i.e. release/0.30-stable branch with 0.30.rc1 decidim version)
        EOERROR
        exit_with_errors(error_message)
      end

      def develop_branch?
        branch == "develop"
      end

      def dev_version_number?
        @old_version_number.match? /dev$/
      end

      def release_branch?
        branch.start_with?("release/")
      end

      def rc_version_number?
        @old_version_number.match? /rc.$/
      end

      def prepare_next_development_version
        return unless develop_branch? || dev_version_number?

        run("git pull origin develop")

        run("git checkout -b #{release_branch}")
        run("git push origin #{release_branch}")

        puts "*" * 80
        puts "Create the stable branch in Crowdin and exit this shell to continue the release process"
        puts "https://docs.decidim.org/en/develop/develop/maintainers/releases.html#_create_the_stable_branch_in_crowdin"
        puts "*" * 80
        system ENV.fetch("SHELL")

        run("git checkout develop")

        next_dev_version = next_version_number_for_dev(@old_version_number)
        prepare_branch = "chore/prepare/#{next_dev_version}"
        run("git checkout -b #{prepare_branch}")

        bump_decidim_version(next_version_number_for_dev(@old_version_number))

        run("bin/rake update_versions")
        run("bin/rake patch_generators")
        run("bin/rake bundle")
        run("npm install")
        run("bin/rake webpack") if Dir.exist?("decidim_app-design")

        generate_empty_changelog
        generate_empty_release_notes

        run("git add .") 
        run("git commit -m 'Bump develop to next release version'")
        run("git push origin #{prepare_branch}")

        create_develop_pull_request(prepare_branch, next_dev_version)
      end

      def prepare_next_release_candidate_version
        run("git checkout #{release_branch}")
        run("git checkout -b chore/prepare/#{version_number}")

        bump_decidim_version(version_number)

        run("bin/rake update_versions")
        run("bin/rake patch_generators")
        run("bin/rake bundle")

        run("npm install")
        run("bin/rake webpack") if Dir.exist?("decidim_app-design")

        check_tests

        generate_changelog

        run("git add .") 
        run("git commit -m 'Bump to #{version_number} version'")
        run("git push origin chore/prepare/#{version_number}")

        create_pull_request

        finish_message = <<~EOMESSAGE
        Finished the release process
        Next steps:

        1. Wait for the tests to finish and check that everything is passing before releasing the version.
        NOTE: When you bump the version, the generator tests will fail because the gems and NPM packages
        have not been actually published yet (as in sent to rubygems/npm). You may see errors such as
        No matching version found for @decidim/browserslist-config@~0.xx.y in the CI logs. This should
        be fine as long as you have ensured that the generators tests passed in the previous commit.
        2. Review and merge this PR
        3. Once that PR is merged, run the following commands to create the tags and push the gems to RubyGems and the packages to NPM:
        > git pull
        > bin/rake release_all
        4. Usually, at this point, the release branch is deployed to Metadecidim during, at least, one week to validate the stability of the version.
        EOMESSAGE

        puts "*" * 80
        puts finish_message
      end

      # Given a version number, returns the next release candidate
      #
      # If the current version number is `dev`, then we return the `rc1` version
      # If the current version number is `rc`, then we return the next `rc` version
      # Else, it means is a `minor` or `patch` version. On those cases we raise an Exception, as releases candidates should
      # be only done from a `dev` or a `rc` version.
      #
      # @raise [InvalidVersionTypeError]
      #
      # @param current_version_number [String] - The version number of the current version
      #
      # @return [String] - the new version number
      def next_version_number_for_release_candidate(current_version_number)
        if current_version_number.include? "dev"
          major, minor, patch = parsed_version_number(current_version_number)
          new_version_number = "#{major}.#{minor}.#{patch}.rc1"
        elsif current_version_number.include? "rc"
          new_rc_number = current_version_number.match(/rc(\d)/)[1].to_i + 1
          new_version_number = current_version_number.gsub(/rc\d/, "rc#{new_rc_number}")
        else
          error_message = <<-EOMESSAGE
          Trying to do a release candidate version from patch release. Bailing out.
          You need to do a release candidate from a `dev` or from another `rc` version
          EOMESSAGE
          raise InvalidVersionTypeError, error_message
        end

        new_version_number
      end

      def next_version_number_for_dev(current_version_number)
        major, minor, patch = parsed_version_number(current_version_number)

        "#{major}.#{minor.to_i + 1}.#{patch}.dev"
      end

      def generate_empty_changelog
        major, minor, patch = parsed_version_number(@old_version_number)

        changelog_contents = <<-EOCHANGELOG
# Changelog

## [Unreleased](https://github.com/decidim/decidim/tree/HEAD)

Nothing.

...

## Previous versions

Please check [#{major}.#{minor}-stable](https://github.com/decidim/decidim/blob/release/#{major}.#{minor}-stable/CHANGELOG.md) for previous changes.
EOCHANGELOG

        File.write("CHANGELOG.md", changelog_contents)
      end

      def generate_empty_release_notes
        release_notes_contents = <<-EORELEASE
# Release Notes

## 1. Upgrade notes

As usual, we recommend that you have a full backup, of the database, application code and static files.

To update, follow these steps:

### 1.1. Update your Gemfile

```ruby
gem "decidim", github: "decidim/decidim"
gem "decidim-dev", github: "decidim/decidim"
```

### 1.2. Run these commands

```console
bundle update decidim
bin/rails decidim:upgrade
bin/rails db:migrate
```

### 1.3. Follow the steps and commands detailed in these notes

## 2. General notes

## 3. One time actions

These are one time actions that need to be done after the code is updated in the production database.

### 3.1. [[TITLE OF THE ACTION]]

You can read more about this change on PR [#XXXX](https://github.com/decidim/decidim/pull/XXXX).

## 4. Scheduled tasks

Implementers need to configure these changes it in your scheduler task system in the production server. We give the examples
with `crontab`, although alternatively you could use `whenever` gem or the scheduled jobs of your hosting provider.

### 4.1. [[TITLE OF THE TASK]]

```bash
4 0 * * * cd /home/user/decidim_application && RAILS_ENV=production bundle exec rails decidim:TASK
```

You can read more about this change on PR [#XXXX](https://github.com/decidim/decidim/pull/XXXX).

## 5. Changes in APIs

### 5.1. [[TITLE OF THE CHANGE]]

In order to [[REASONING (e.g. improve the maintenance of the code base)]] we have changed...

If you have used code as such:

```ruby
# Explain the usage of the API as it was in the previous version
result = 1 + 1 if before
```

You need to change it to:

```ruby
# Explain the usage of the API as it is in the new version
result = 1 + 1 if after
        ```
EORELEASE

        File.write("RELEASE_NOTES.md", release_notes_contents)
      end

      # Creates the pull request for bumping the develop version
      #
      # @param head_branch [String] the branch that we want to merge to develop
      # @param next_dev_version [String] the name of the next dev version (for instance 0.99.0.dev)
      #
      # @return [void]
      def create_develop_pull_request(head_branch, next_dev_version)
        base_branch = "develop"

        params = {
          title: "Bump develop to next release version (#{next_dev_version})",
          body: "#### :tophat: What? Why?

This PR prepares the next develop version.

#### Testing

All the tests should pass

:hearts: Thank you!
          ",
          labels: ["type: internal"],
          head: head_branch,
          base: base_branch
        }
        Decidim::MaintainersToolbox::GithubManager::Poster.new(token: @token, params: params).call
      end
    end
  end
end

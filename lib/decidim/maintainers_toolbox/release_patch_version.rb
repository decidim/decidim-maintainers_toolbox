# frozen_string_literal: true

require "open3"
require_relative "github_manager/poster"
require_relative "github_manager/querier/by_query"
require_relative "changelog_generator"
require_relative "releaser_utils"

module Decidim
  module MaintainersToolbox
    class ReleasePatchVersion
      include Decidim::MaintainersToolbox::ReleaserUtils

      # @param token [String] token for GitHub authentication
      # @param working_dir [String] current working directory. Useful for testing purposes
      def initialize(token:, working_dir: Dir.pwd)
        @token = token
        @working_dir = working_dir
      end

      def call
        run("git checkout #{release_branch}")
        run("git pull origin #{release_branch}")

        bump_decidim_version
        run("bin/rake update_versions")

        run("bin/rake patch_generators")

        run("bin/rake bundle")
        run("npm install")
        run("bin/rake webpack") if Dir.exist?("decidim_app-design")

        check_tests

        generate_changelog

        run("git checkout -b chore/prepare/#{version_number}")
        run("git commit -a -m 'Prepare #{version_number} release'")
        run("git push origin chore/prepare/#{version_number}")

        create_pull_request
      end

      # The version number for the release that we are preparing
      #
      # @return [String] the version number
      def version_number
        next_version_number_for_patch_release(old_version_number)
      end

      private

      # The git branch
      #
      # @return [String]
      def branch
        @branch ||= capture("git rev-parse --abbrev-ref HEAD")[0].strip
      end

      # Raise an error if the branch does not start with the preffix "release/"
      # or returns the branch name
      #
      # @raise [InvalidBranchError]
      #
      # @return [String]
      def release_branch
        raise InvalidBranchError, "This is not a release branch, aborting" unless branch.start_with?("release/")

        branch
      end

      # Changes the decidim version in the file
      #
      # @return [void]
      def bump_decidim_version
        File.write(DECIDIM_VERSION_FILE, version_number)
      end

      # Run the tests and if fails restore the changes using git and exit with an error
      #
      # @return [void]
      def check_tests
        puts "Running specs"
        output, status = capture("bin/rspec", { "ENFORCED_LOCALES" => "en,ca,es", "SKIP_NORMALIZATION" => "true" })

        unless status.success?
          run("git restore .")
          puts output
          exit_with_errors("Tests execution failed. Fix the errors and run again.")
        end
      end

      # Given a version number, returns the next patch release
      #
      # If the current version number is `dev`, then we raise an Exception, as you need to first do a release candidate.
      # If the current version number is `rc`, then we return the `0` patch version
      # Else, it means is a `patch` version, so we return the next patch version
      #
      # @raise [InvalidVersionTypeError]
      #
      # @param current_version_number [String] - The version number of the current version
      #
      # @return [String] - the new version number
      def next_version_number_for_patch_release(current_version_number)
        major, minor, patch = parsed_version_number(current_version_number)

        if current_version_number.include? "dev"
          error_message = <<-EOMESSAGE
          Trying to do a patch version from dev release. Bailing out.
          You need to do first a release candidate.
          EOMESSAGE
          raise InvalidVersionTypeError, error_message
        elsif current_version_number.include? "rc"
          new_version_number = "#{major}.#{minor}.0"
        else
          new_version_number = "#{major}.#{minor}.#{patch.to_i + 1}"
        end

        new_version_number
      end
    end
  end
end

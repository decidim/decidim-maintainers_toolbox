# frozen_string_literal: true

require "open3"
require_relative "changelog_generator"
require_relative "github_manager/poster"

module Decidim
  module MaintainersToolbox
    module ReleaserUtils
      class InvalidVersionTypeError < StandardError; end

      DECIDIM_VERSION_FILE = ".decidim-version".freeze

      # Exit the script execution with a message
      #
      # @return [void]
      def exit_with_errors(message)
        puts message
        exit 1
      end

      # Captures to output of a command
      #
      # @return [Array<String, Process::Status>] The stdout and stderr of the command and its status (aka error code)
      def capture(cmd, env: {})
        Open3.capture2e(env, cmd)
      end

      # Runs a command
      #
      # @return [void]
      def run(cmd, out: $stdout)
        system(cmd, out: out)
      end

      # The git branch
      #
      # @return [String]
      def branch
        @branch ||= capture("git rev-parse --abbrev-ref HEAD")[0].strip
      end

      # The version number from the file
      #
      # @return [String] the version number
      def old_version_number
        File.read(DECIDIM_VERSION_FILE).strip
      end

      def parsed_version_number(version_number)
        /(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)/ =~ version_number

        [major.to_i, minor.to_i, patch.to_i]
      end

      # Run the tests and if fails restore the changes using git and exit with an error
      #
      # @return [void]
      def check_tests
        puts "Running specs"
        output, status = capture("bin/rspec", env: { "ENFORCED_LOCALES" => "en,ca,es", "SKIP_NORMALIZATION" => "true" })

        unless status.success?
          run("git restore .")
          puts output
          exit_with_errors("Tests execution failed. Fix the errors and run again.")
        end
      end

      # Generates the changelog taking into account the last time the version changed
      #
      # @return [void]
      def generate_changelog
        sha_version = capture("git log -n 1 --pretty=format:%h -- .decidim-version")[0]
        ChangeLogGenerator.new(token: @token, since_sha: sha_version).call
        temporary_changelog = File.read("./temporary_changelog.md")
        legacy_changelog = File.read("./CHANGELOG.md")
        version_changelog = "## [#{version_number}](https://github.com/decidim/decidim/tree/#{version_number})\n\n#{temporary_changelog}\n"
        changelog = legacy_changelog.gsub("# Changelog\n\n", "# Changelog\n\n#{version_changelog}")
        File.write("./CHANGELOG.md", changelog)
      end

      # Creates the pull request for bumping the version
      #
      # @return [void]
      def create_pull_request
        base_branch = release_branch
        head_branch = "chore/prepare/#{version_number}"

        params = {
          title: "Bump to v#{version_number} version",
          body: "#### :tophat: What? Why?

This PR prepares version of the #{release_branch} branch, so we can publish the release once this is approved and merged.

#### Testing

All the tests should pass, except for some generators tests, that will fail because the gems and NPM packages have not
been actually published yet (as in sent to rubygems/npm).
You will see errors such as `No matching version found for @decidim/browserslist-config@~0.xx.y` in the CI logs.

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


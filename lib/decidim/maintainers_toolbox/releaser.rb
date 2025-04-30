# frozen_string_literal: true

require_relative "github_manager/querier/by_query"

require_relative "releaser_utils"
require_relative "release_candidate_version"
require_relative "release_patch_version"

module Decidim
  module MaintainersToolbox
    class Releaser
      class InvalidMetadataError < StandardError; end

      include Decidim::MaintainersToolbox::ReleaserUtils

      # @param token [String] token for GitHub authentication
      # @param version_type [String] The kind of release that you want to prepare. Supported values: rc, minor, patch
      # @param working_dir [String] current working directory. Useful for testing purposes
      # @param exit_with_unstaged_changes [Boolean] wheter we should exit cowardly if there is any unstaged change
      def initialize(token:, version_type:, working_dir: Dir.pwd, exit_with_unstaged_changes: false)
        @token = token
        @version_type = version_type
        @working_dir = working_dir
        @exit_with_unstaged_changes = exit_with_unstaged_changes
      end

      def call
        Dir.chdir(@working_dir) do
          exit_if_unstaged_changes if @exit_with_unstaged_changes
          exit_if_pending_crowdin_pull_request

          case @version_type
          when "rc"
            release = ReleaseCandidateVersion.new(token: @token, working_dir: @working_dir)
          # Minor release process is the same as the Patch release process
          when "minor"
            release = ReleasePatchVersion.new(token: @token, working_dir: @working_dir)
          when "patch"
            release = ReleasePatchVersion.new(token: @token, working_dir: @working_dir)
          else
            raise InvalidVersionTypeError, "This is not a valid version type"
          end

          puts "Starting the release process for #{release.version_number} in 10 seconds"
          sleep 10

          release.call
        end
      end

      private

      # Check if there is any open pull request from Crowdin in GitHub
      #
      # @return [Boolean] - true if there is any open PR
      def pending_crowdin_pull_requests?
        pull_requests = Decidim::MaintainersToolbox::GithubManager::Querier::ByQuery.new(
          token: @token,
          query: { title: "New Crowdin updates", creator: "decidim-bot" }
        ).call
        pull_requests.any?
      end

      # Exit the script execution if there are any pull request from Crowdin open
      #
      # @return [void]
      def exit_if_pending_crowdin_pull_request
        return unless pending_crowdin_pull_requests?

        error_message = <<-EOERROR
  There are open pull requests from Crowdin in GitHub
  Merge them and run again this script.
        EOERROR
        exit_with_errors(error_message)
      end

      # Exit the script execution with a message
      # Exit the script execution if there are any unstaged changes
      #
      # @return [void]
      def exit_if_unstaged_changes
        return if `git diff`.empty?

        error_message = <<-EOERROR
  There are changes not staged in your project.
  Please commit your changes or stash them.
        EOERROR
        exit_with_errors(error_message)
      end
    end
  end
end

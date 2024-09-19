# frozen_string_literal: true

module Decidim
  module MaintainersToolbox
    class ActionBackporter
      class InvalidMetadataError < StandardError; end

      # @param token [String] token for GitHub authentication
      # @param pull_request_id [String] the ID of the pull request that we want to backport
      # @param exit_with_unstaged_changes [Boolean] wheter we should exit cowardly if there is any unstaged change
      def initialize(token: , pull_request_id: ,exit_with_unstaged_changes: )
        @token = token
        @pull_request_id = pull_request_id
        @exit_with_unstaged_changes = exit_with_unstaged_changes
      end

      def call
        pp pull_request_metadata

        exit_with_errors("The requested PR #{pull_request_id} does not contain `type: fix`") unless pull_request_metadata[:labels].include?("type: fix")
        exit_with_errors("The requested PR #{pull_request_id} is not merged") unless pull_request_metadata[:is_merged]
        exit_with_errors("The requested PR #{pull_request_id} cannot be backported") if pull_request_metadata[:labels].include?("no-backport")

        #
        # extract_versions.each do |version|
        #   next if extract_backport_pull_request_for_version(related_issues, version)
        #   # `decidim-backporter --github_token=#{token} --pull_request_id=#{pull_request_id} --version_number=#{version} --exit_with_unstaged_changes=#{exit_with_unstaged_changes} --with-console=false`
        #   # create_backport_task(version) unless $CHILD_STATUS.exitstatus.zero?
        # end
      end

      private

      attr_reader :token, :pull_request_id, :exit_with_unstaged_changes

      def create_backport_task(version)
        pp pull_request_metadata
        some_params = {
          title: "Backport of \"#{pull_request_metadata[:title]}\" failed for version #{version}",
          body: "Backport of ##{pull_request_id} failed for version #{version}",
          assignee: "alecslupu",
          labels: pull_request_metadata[:labels]
        }

        uri = "https://api.github.com/repos/decidim/decidim/issues"
        Faraday.post(uri, some_params.to_json, { Authorization: "token #{token}" })
      end

      # same method exists in lib/decidim/maintainers_toolbox/backports_reporter/report.rb
      def extract_backport_pull_request_for_version(related_issues, version)
        related_issues = related_issues.select do |pull_request|
          pull_request[:title].start_with?("Backport") && pull_request[:title].include?(version)
        end
        return if related_issues.empty?

        related_issues.first
      end

      def extract_versions
        return [] unless pull_request_metadata[:labels]

        pull_request_metadata[:labels].map do |item|
          item.match(/release: v(\d+\.\d+)/) { |m| m[1] }
        end.compact
      end

      # Asks the metadata for a given issue or pull request on GitHub API
      #
      # @return [Faraday::Response] An instance that represents an HTTP response from making an HTTP request
      # Same method exists in lib/decidim/maintainers_toolbox/backporter.rb
      def pull_request_metadata
        @pull_request_metadata ||= Decidim::MaintainersToolbox::GithubManager::Querier::ByIssueId.new(
          token: token,
          issue_id: pull_request_id
        ).call
      end

      def related_issues
        @related_issues ||= Decidim::MaintainersToolbox::GithubManager::Querier::RelatedIssues.new(
          token: token,
          issue_id: pull_request_id
        ).call
      end

      # Exit the script execution with a message
      #
      # @return [void]
      def exit_with_errors(message)
        puts message
        exit 1
      end
    end
  end
end
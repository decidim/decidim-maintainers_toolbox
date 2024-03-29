# frozen_string_literal: true

require_relative "github_manager/querier"

require "json"
require "ruby-progressbar"

module Decidim
  module MaintainersToolbox
    class ChangeLogGenerator
      class InvalidMetadataError < StandardError; end

      TYPES = {
        "Added" => {
          label: "type: feature",
          skip_modules: false
        },
        "Changed" => {
          label: "type: change",
          skip_modules: false
        },
        "Fixed" => {
          label: "type: fix",
          skip_modules: false
        },
        "Removed" => {
          label: "type: removal",
          skip_modules: false
        },
        "Developer improvements" => {
          label: "target: developer-experience",
          skip_modules: true
        },
        "Internal" => {
          label: "type: internal",
          skip_modules: false
        }
      }.freeze

      def initialize(token:, since_sha:)
        @token = token
        @since_sha = since_sha
        @output_file = []
        @handled_ids = []

        @progress_bar = ProgressBar.create(title: "PRs", total: list_of_commits.count)
      end

      def call
        raise InvalidMetadataError if token.nil?

        TYPES.each do |type_title, type_data|
          type_prs = prs.select do |_commit_title, data|
            next unless data

            data[:type].include?(type_data[:label])
          end

          output "### #{type_title}"
          output ""

          if type_prs.any?
            type_prs.each do |_pr_title, data|
              process_single_pr(data, type_data)
            end
          else
            output "Nothing."
          end

          output ""
        end

        process_unsorted_prs
        write_data_file!
      end

      private

      def write_data_file!
        File.write("temporary_changelog.md", @output_file.join("\n"))
        puts "Written file: temporary_changelog.md"
      end

      def process_single_pr(data, type_data)
        modules_list = data[:modules].map { |l| "**decidim-#{l.delete_prefix("module: ")}**" }
        id = data[:id]
        title = data[:title]

        @handled_ids << id

        if type_data[:skip_modules] || modules_list.empty?
          output "- #{title} #{pr_link(id)}"
        else
          output "- #{modules_list.join(", ")}: #{title} #{pr_link(id)}"
        end
      end

      def process_unsorted_prs
        return unless unsorted_prs.any?

        output "### Unsorted"
        output ""

        unsorted_prs.map do |title, data|
          pr_data = data || {}
          output "- #{title} #{pr_link(pr_data[:id])} || #{data}"
        end
      end

      def unsorted_prs
        @unsorted_prs ||= prs.reject do |_commit_title, data|
          pr_data = data || {}

          @handled_ids.include?(pr_data[:id])
        end
      end

      attr_reader :token, :since_sha

      def prs
        @prs ||= list_of_commits.inject({}) do |acc, commit|
          next acc if crowdin?(commit)

          acc.update(commit => get_pr_data(commit))
        end
      end

      def list_of_commits
        @list_of_commits ||= `git log #{since_sha}..HEAD --oneline`.split("\n").reverse
      end

      def crowdin?(commit)
        !commit.match(/New Crowdin updates/).nil?
      end

      def get_pr_id(commit)
        id = commit.scan(/#\d+/).last
        return unless id

        id.delete_prefix("#")
      end

      def get_pr_data(commit)
        @progress_bar.increment

        id = get_pr_id(commit)
        return nil unless id

        Decidim::MaintainersToolbox::GithubManager::Querier::ByIssueId.new(
          token: token,
          issue_id: id
        ).call
      end

      def pr_link(id)
        # We need to do this so that it generates the expected Markdown format.
        # String interpolation messes with the format.
        "[#{"\\#" + id.to_s}](https://github.com/decidim/decidim/pull/#{id})" # rubocop:disable Style/StringConcatenation
      end

      def output(str)
        @output_file << str
      end
    end
  end
end

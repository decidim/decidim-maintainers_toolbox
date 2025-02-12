# frozen_string_literal: true

require_relative "base"

module Decidim
  module MaintainersToolbox
    module GithubManager
      module Querier
        # Makes a GET request for the metadata of an Issue or Pull Request in GitHub
        #
        # @see https://docs.github.com/en/rest/issues/issues#get-an-issue GitHub API documentation
        class ByIssueId < Decidim::MaintainersToolbox::GithubManager::Querier::Base
          def initialize(issue_id:, token:)
            @issue_id = issue_id
            @token = token
          end

          # Makes the GET request and parses the response of an Issue or Pull Request in GitHub
          #
          # @return [Hash]
          def call
            data = json_response("https://api.github.com/repos/decidim/decidim/issues/#{@issue_id}")
            return unless data["number"]

            parse(data)
          end

          private

          # Parses the response of an Issue or Pull Request in GitHub
          #
          # @return [Hash]
          def parse(metadata)
            labels = metadata["labels"].map { |l| l["name"] }.sort

            {
              id: metadata["number"],
              state: metadata["state"],
              is_pull_request: metadata["pull_request"].present?,
              is_merged: (metadata["pull_request"]["merged_at"].present? rescue false),
              title: metadata["title"],
              labels: labels,
              type: labels.select { |l| l.match(/^type: /) || l == "target: developer-experience" },
              modules: labels.select { |l| l.match(/^module: /) }
            }
          end
        end
      end
    end
  end
end

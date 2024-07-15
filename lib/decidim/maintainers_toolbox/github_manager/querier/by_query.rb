# frozen_string_literal: true

require_relative "base"

module Decidim
  module MaintainersToolbox
    module GithubManager
      module Querier
        # Makes a GET request for the list of Issues or Pull Requests in GitHub.
        #
        # @param token [String] token for GitHub authentication
        # @pparam query [Hash] the query to search
        #
        # @see https://docs.github.com/en/rest/issues/issues#list-repository-issues GitHub API documentation
        class ByQuery < Decidim::MaintainersToolbox::GithubManager::Querier::Base
          def initialize(token:, query: {})
            @token = token
            @query = query
          end

          # Makes the GET request and parses the response of an Issue or Pull Request in GitHub
          #
          # @return [Hash]
          def call
            data = json_response("https://api.github.com/repos/decidim/decidim/issues")

            parse(data)
          end

          private

          attr_reader :query

          def headers
            {
              per_page: 100
            }.merge(query)
          end

          # Parses the response of an Issue or Pull Request in GitHub
          #
          # @return [Hash]
          def parse(metadata)
            metadata.map do |item|
              {
                id: item["number"],
                title: item["title"]
              }
            end
          end
        end
      end
    end
  end
end

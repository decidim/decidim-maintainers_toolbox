# frozen_string_literal: true

module Decidim
  module MaintainersToolbox
    # Shared logic to identify the backport Pull Requests of a given Pull Request.
    #
    # A backport Pull Request is linked with its original Pull Request in two ways:
    # - By the body, as it always contains a line like "Backport #1234 to v0.32"
    # - By the title, that follows the pattern "Backport 'Title of the original' to v0.32"
    module BackportsHelper
      private

      # Checks if a related issue is a backport of the given Pull Request for the given version.
      #
      # @param related_issue [Hash] a cross-referenced issue or pull request, with the :title, :body and :state
      # @param base_pull_request [Hash] the Pull Request that we want to check, with the :id and :title
      # @param version [String] the version number that we want to check, with the "v" prefix (i.e. "v0.32")
      #
      # @return [Boolean]
      def backport_of_pull_request?(related_issue, base_pull_request, version)
        return false unless related_issue[:title].to_s.start_with?("Backport")
        return false unless backport_for_version?(related_issue, version)

        base_pull_request_id = base_pull_request[:id]
        return true if base_pull_request_id && related_issue[:body].to_s.match?(/\bBackport ##{base_pull_request_id}\b/)

        related_issue[:title].to_s.match?(
          /\ABackport ['"]?#{Regexp.escape(base_pull_request[:title].to_s)}['"]? to /
        )
      end

      # Checks if a related issue is a backport for the given version.
      #
      # @param related_issue [Hash] a cross-referenced issue or pull request, with the :title and :body
      # @param version [String] the version number that we want to check, with or without the "v" prefix (i.e. "v0.32" or "0.32")
      #
      # @return [Boolean]
      def backport_for_version?(related_issue, version)
        [related_issue[:title], related_issue[:body]].any? do |text|
          text.to_s.match?(/\bto v?#{Regexp.escape(version)}\b/)
        end
      end

      # The state priority, so we show merged Pull Requests before the opened or closed ones.
      #
      # @param state [String] the state of the Pull Request
      #
      # @return [Integer]
      def backport_state_priority(state)
        { "merged" => 0, "open" => 1, "closed" => 2 }.fetch(state.to_s, 3)
      end
    end
  end
end

# frozen_string_literal: true

require_relative "../backports_helper"

module Decidim
  module MaintainersToolbox
    module BackportsReporter
      # Abstract class for the different formats
      class Report
        include Decidim::MaintainersToolbox::BackportsHelper

        attr_reader :report, :last_version_number

        def initialize(report:, last_version_number:)
          @report = report
          @last_version_number = last_version_number
        end

        def call
          output_report
        end

        private

        def penultimate_version_number
          major, minor = last_version_number.split(".")

          "#{major}.#{minor.to_i - 1}"
        end

        def output_report
          output = output_head
          report.each do |line|
            next if backports_merged?(line)

            output += output_line(line)
          end
          output
        end

        def output_head
          raise "Called abstract method: output_head"
        end

        def output_line(_line)
          raise "Called abstract method: output_line"
        end

        def extract_backport_pull_request_for_version(line, version)
          line[:related_issues]
            .select { |related_issue| backport_of_pull_request?(related_issue, line, version) }
            .min_by { |pull_request| backport_state_priority(pull_request[:state]) }
        end

        def backports_merged?(line)
          return if line[:related_issues].empty?

          latest_pr = extract_backport_pull_request_for_version(line, "v#{last_version_number}")
          penultimate_pr = extract_backport_pull_request_for_version(line, "v#{penultimate_version_number}")

          return unless [latest_pr, penultimate_pr].all?

          latest_pr[:state] == "merged" && penultimate_pr[:state] == "merged"
        end
      end
    end
  end
end

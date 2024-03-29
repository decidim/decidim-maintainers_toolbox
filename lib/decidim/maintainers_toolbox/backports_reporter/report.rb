# frozen_string_literal: true

module Decidim
  module MaintainersToolbox
    module BackportsReporter
      # Abstract class for the different formats
      class Report
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
            next if backports_merged?(line[:related_issues])

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

        def extract_backport_pull_request_for_version(related_issues, version)
          related_issues = related_issues.select do |pull_request|
            pull_request[:title].start_with?("Backport") && pull_request[:title].include?(version)
          end
          return if related_issues.empty?

          related_issues.first
        end

        def backports_merged?(related_issues)
          return if related_issues.empty?

          latest_pr = extract_backport_pull_request_for_version(related_issues, "v#{last_version_number}")
          penultimate_pr = extract_backport_pull_request_for_version(related_issues, "v#{penultimate_version_number}")

          return unless [latest_pr, penultimate_pr].all?

          latest_pr[:state] == "merged" && penultimate_pr[:state] == "merged"
        end
      end
    end
  end
end

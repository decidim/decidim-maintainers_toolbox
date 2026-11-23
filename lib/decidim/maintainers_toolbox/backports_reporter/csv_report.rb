# frozen_string_literal: true

require_relative "report"

module Decidim
  module MaintainersToolbox
    module BackportsReporter
      class CSVReport < Decidim::MaintainersToolbox::BackportsReporter::Report
        private

        def output_head
          "ID;Title;Backport v#{last_version_number};Backport v#{penultimate_version_number}\n"
        end

        def output_line(line)
          output = "#{line[:id]};"
          output += "#{line[:title]};"
          output += "#{format_backport(line, "v#{last_version_number}")};"
          output += "#{format_backport(line, "v#{penultimate_version_number}")}\n"
          output
        end

        def format_backport(line, version)
          return if line[:related_issues].empty?

          pull_request = extract_backport_pull_request_for_version(line, version)
          return if pull_request.nil?

          "#{pull_request[:state]}|#{pull_request[:id]}"
        end
      end
    end
  end
end

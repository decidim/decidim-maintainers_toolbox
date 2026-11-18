# frozen_string_literal: true

require "decidim/maintainers_toolbox/backports_reporter/csv_report"

RSpec.describe Decidim::MaintainersToolbox::BackportsReporter::CSVReport do
  subject { described_class.new(report: report, last_version_number: last_version_number).call }

  let(:report) do
    [{ id: 1234, title: "Fix the world", related_issues: [] }]
  end
  let(:last_version_number) { "0.27" }

  describe ".call" do
    context "without related_issues" do
      it "returns a valid response" do
        expect(subject).to eq "ID;Title;Backport v0.27;Backport v0.26\n1234;Fix the world;;\n"
      end
    end

    context "with another version number" do
      let(:last_version_number) { "0.31" }

      it "returns a valid response" do
        expect(subject).to eq "ID;Title;Backport v0.31;Backport v0.30\n1234;Fix the world;;\n"
      end
    end

    context "with related_issues" do
      context "when it is not a backport" do
        let(:report) do
          [{ id: 1234, title: "Fix the world", related_issues: [id: 9876, title: "Whatever", state: "closed"] }]
        end

        it "returns a valid response" do
          expect(subject).to eq "ID;Title;Backport v0.27;Backport v0.26\n1234;Fix the world;;\n"
        end
      end

      context "when it is a backport" do
        let(:report) do
          [{ id: 1234, title: "Fix the world", related_issues: [id: 9876, title: 'Backport "Fix the world" to v0.26', state: "merged"] }]
        end

        it "returns a valid response" do
          expect(subject).to eq "ID;Title;Backport v0.27;Backport v0.26\n1234;Fix the world;;merged|9876\n"
        end
      end

      context "when there is a backport from another pull request" do
        let(:report) do
          [{ id: 1234, title: "Fix the world", related_issues: [
            { id: 9876, title: 'Backport "Another fix" to v0.27', body: "Backport #42 to v0.27", state: "merged" },
            { id: 9877, title: 'Backport "Fix the world" to v0.27', body: "Backport #1234 to v0.27", state: "open" },
            { id: 9878, title: 'Backport "Fix the world" to v0.26', body: "Backport #1234 to v0.26", state: "merged" }
          ] }]
        end

        it "only takes into account the backports of the pull request" do
          expect(subject).to eq "ID;Title;Backport v0.27;Backport v0.26\n1234;Fix the world;open|9877;merged|9878\n"
        end
      end

      context "when a backport from another pull request is open" do
        let(:report) do
          [{ id: 1234, title: "Fix the world", related_issues: [
            { id: 9876, title: 'Backport "Another fix" to v0.27', body: "Backport #42 to v0.27", state: "open" },
            { id: 9875, title: 'Backport "Fix the world" to v0.27', body: "Backport #1234 to v0.27", state: "merged" },
            { id: 9878, title: 'Backport "Fix the world" to v0.26', body: "Backport #1234 to v0.26", state: "merged" }
          ] }]
        end

        it "hides the row when the pull request is fully backported" do
          expect(subject).to eq "ID;Title;Backport v0.27;Backport v0.26\n"
        end
      end
    end
  end
end

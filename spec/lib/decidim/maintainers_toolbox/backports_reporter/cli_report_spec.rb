# frozen_string_literal: true

require "decidim/maintainers_toolbox/backports_reporter/cli_report"

RSpec.describe Decidim::MaintainersToolbox::BackportsReporter::CLIReport do
  subject { described_class.new(report: report, last_version_number: last_version_number).call }

  let(:report) do
    [{ id: id, title: title, related_issues: related_issues }]
  end
  let(:id) { 10_234 }
  let(:title) { "Fix the world" }
  let(:related_issues) { [] }
  let(:last_version_number) { "0.27" }

  describe ".call" do
    context "when the id is shorter" do
      let(:id) { 1_234 }

      it "returns a valid response" do
        response = <<~RESPONSE
          |   ID   |                                        Title                                        | Backport v0.27 | Backport v0.26 |
          |--------|-------------------------------------------------------------------------------------|----------------|----------------|
          | #1234  | Fix the world                                                                       |      None      |      None      |
        RESPONSE
        expect(subject).to eq response
      end
    end

    context "when the title is really long" do
      let(:last_version_number) { "0.31" }
      let(:title) { "The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog" }

      it "returns a valid response" do
        response = <<~RESPONSE
          |   ID   |                                        Title                                        | Backport v0.31 | Backport v0.30 |
          |--------|-------------------------------------------------------------------------------------|----------------|----------------|
          | #10234 | The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the ... |      None      |      None      |
        RESPONSE
        expect(subject).to eq response
      end
    end

    context "without related_issues" do
      it "returns a valid response" do
        response = <<~RESPONSE
          |   ID   |                                        Title                                        | Backport v0.27 | Backport v0.26 |
          |--------|-------------------------------------------------------------------------------------|----------------|----------------|
          | #10234 | Fix the world                                                                       |      None      |      None      |
        RESPONSE
        expect(subject).to eq response
      end

      context "with another version number" do
        let(:last_version_number) { "0.31" }

        it "returns a valid response" do
          response = <<~RESPONSE
            |   ID   |                                        Title                                        | Backport v0.31 | Backport v0.30 |
            |--------|-------------------------------------------------------------------------------------|----------------|----------------|
            | #10234 | Fix the world                                                                       |      None      |      None      |
          RESPONSE
          expect(subject).to eq response
        end
      end
    end

    context "with related_issues" do
      context "when there is not a backport" do
        let(:related_issues) { [{ id: 9876, title: "Whatever", state: "closed" }] }

        it "returns a valid response" do
          response = <<~RESPONSE
            |   ID   |                                        Title                                        | Backport v0.27 | Backport v0.26 |
            |--------|-------------------------------------------------------------------------------------|----------------|----------------|
            | #10234 | Fix the world                                                                       |      None      |      None      |
          RESPONSE
          expect(subject).to eq response
        end
      end

      context "when there is a backport" do
        let(:related_issues) { [{ id: 9876, title: 'Backport "Fix the world" to v0.26', state: "merged" }] }

        it "returns a valid response" do
          response = <<~RESPONSE
            |   ID   |                                        Title                                        | Backport v0.27 | Backport v0.26 |
            |--------|-------------------------------------------------------------------------------------|----------------|----------------|
            | #10234 | Fix the world                                                                       |      None      |      \e[34m#9876\e[0m     |
          RESPONSE
          expect(subject).to eq response
        end
      end

      context "when there are two backports" do
        let(:related_issues) do
          [
            { id: 9876, title: 'Backport "Fix the world" to v0.26', state: "merged" },
            { id: 9875, title: 'Backport "Fix the world" to v0.27', state: "merged" }
          ]
        end

        it "hides row when both PRs are merged" do
          response = <<~RESPONSE
            |   ID   |                                        Title                                        | Backport v0.27 | Backport v0.26 |
            |--------|-------------------------------------------------------------------------------------|----------------|----------------|
          RESPONSE
          expect(subject).to eq response
        end
      end

      context "when there is a backport from another pull request" do
        let(:related_issues) do
          [
            { id: 9876, title: 'Backport "Another fix" to v0.27', body: "Backport #42 to v0.27", state: "merged" },
            { id: 9877, title: 'Backport "Fix the world" to v0.27', body: "Backport #10234 to v0.27", state: "open" },
            { id: 9878, title: 'Backport "Fix the world" to v0.26', body: "Backport #10234 to v0.26", state: "merged" }
          ]
        end

        it "does not hide the row because of the other pull request backport" do
          response = <<~RESPONSE
            |   ID   |                                        Title                                        | Backport v0.27 | Backport v0.26 |
            |--------|-------------------------------------------------------------------------------------|----------------|----------------|
            | #10234 | Fix the world                                                                       |      \e[32m#9877\e[0m     |      \e[34m#9878\e[0m     |
          RESPONSE
          expect(subject).to eq response
        end
      end

      context "when a backport from another pull request is open" do
        let(:related_issues) do
          [
            { id: 9876, title: 'Backport "Another fix" to v0.27', body: "Backport #42 to v0.27", state: "open" },
            { id: 9875, title: 'Backport "Fix the world" to v0.27', body: "Backport #10234 to v0.27", state: "merged" },
            { id: 9878, title: 'Backport "Fix the world" to v0.26', body: "Backport #10234 to v0.26", state: "merged" }
          ]
        end

        it "hides the row when the pull request is fully backported" do
          response = <<~RESPONSE
            |   ID   |                                        Title                                        | Backport v0.27 | Backport v0.26 |
            |--------|-------------------------------------------------------------------------------------|----------------|----------------|
          RESPONSE
          expect(subject).to eq response
        end
      end

      context "when the backport is only identified by the body" do
        let(:related_issues) do
          [
            { id: 9876, title: "Backport of an old fix to v0.26", body: "Backport #10234 to v0.26", state: "merged" }
          ]
        end

        it "uses the body to relate the backport with the pull request" do
          response = <<~RESPONSE
            |   ID   |                                        Title                                        | Backport v0.27 | Backport v0.26 |
            |--------|-------------------------------------------------------------------------------------|----------------|----------------|
            | #10234 | Fix the world                                                                       |      None      |      \e[34m#9876\e[0m     |
          RESPONSE
          expect(subject).to eq response
        end
      end
    end
  end
end

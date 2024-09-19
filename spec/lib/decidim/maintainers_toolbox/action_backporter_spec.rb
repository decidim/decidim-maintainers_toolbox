# frozen_string_literal: true

require "decidim/maintainers_toolbox/action_backporter"
require "webmock/rspec"

describe Decidim::MaintainersToolbox::ActionBackporter do

  subject { described_class.new(token: token, pull_request_id: pull_request_id, exit_with_unstaged_changes: exit_with_unstaged_changes) }

  let(:token) { "1234" }
  let(:pull_request_id) { 123 }
  let(:exit_with_unstaged_changes) { true }

  before do
    stub_request(:get, "https://api.github.com/repos/decidim/decidim/issues/123").
      to_return(status: 200, body: '{"number": 12345, "pull_request": {"merged_at": "" }, "title": "Fix whatever", "labels": [{"name": "type: fix"}, {"name": "module: admin"}]}', headers: {})

    stub_request(:post, "https://api.github.com/repos/decidim/decidim/issues")
      .to_return(status: 200, body: "{}", headers: {})
  end

  describe ".exit_with_errors" do
    it "exit with a custom message" do
      expect { subject.send(:exit_with_errors, "Bye") }.to raise_error(SystemExit).and output(/Bye/).to_stdout
    end
  end

  describe ".call" do
    it "exists when the PR is not a fix" do
      allow(subject).to receive(:pull_request_metadata).and_return({labels: ["type: change"], is_merged: true })
      expect{ subject.call }.to raise_error(SystemExit).and output(/does not contain `type: fix`/).to_stdout
    end

    it "exists when the PR is not merged" do
      allow(subject).to receive(:pull_request_metadata).and_return({labels: ["type: fix"], is_merged: false })
      expect{ subject.call }.to raise_error(SystemExit).and output(/is not merged/).to_stdout
    end

    it "exists when the PR is not backportable" do
      allow(subject).to receive(:pull_request_metadata).and_return({labels: ["type: fix", "no-backport"], is_merged: true })
      expect{ subject.call }.to raise_error(SystemExit).and output(/cannot be backported/).to_stdout
    end

    it "calls extract versions" do
      allow(subject).to receive(:pull_request_metadata).and_return({ labels: ["type: fix", "release: v0.28", "release: v0.29"], is_merged: true })
      allow(subject).to receive(:extract_versions).and_return(["0.28", "0.29"])
      allow(subject).to receive(:related_issues).and_return([])
      allow(subject).to receive(:system).and_return(true)

      expect(subject).to receive(:extract_versions)

      subject.call
    end

    it "runs the system command" do
      allow(subject).to receive(:pull_request_metadata).and_return({ labels: ["type: fix", "release: v0.28", "release: v0.29"], is_merged: true })
      allow(subject).to receive(:extract_versions).and_return(["0.28", "0.29"])
      allow(subject).to receive(:related_issues).and_return([])

      expect(subject).to receive(:system).with("decidim-backporter --github_token=#{token} --pull_request_id=#{pull_request_id} --version_number=0.28 --exit_with_unstaged_changes=#{exit_with_unstaged_changes} --with-console=false", exception: true)
      expect(subject).to receive(:system).with("decidim-backporter --github_token=#{token} --pull_request_id=#{pull_request_id} --version_number=0.29 --exit_with_unstaged_changes=#{exit_with_unstaged_changes} --with-console=false", exception: true)

      subject.call
    end

    it "skips the creation" do
      allow(subject).to receive(:pull_request_metadata).and_return({ labels: ["type: fix", "release: v0.28", "release: v0.29"], is_merged: true })
      allow(subject).to receive(:extract_versions).and_return(["0.28", "0.29"])
      allow(subject).to receive(:related_issues).and_return([{title: "Backport 0.28"}, {title: "Backport 0.29"}])

      expect(subject).to receive(:extract_backport_pull_request_for_version).with(kind_of(Array), "0.28").and_return({})
      expect(subject).to receive(:extract_backport_pull_request_for_version).with(kind_of(Array), "0.29").and_return({})

      subject.call
    end

    it "creates the ticket" do
      allow(subject).to receive(:pull_request_metadata).and_return({ labels: ["type: fix", "release: v0.28", "release: v0.29"], is_merged: true })
      allow(subject).to receive(:extract_versions).and_return(["0.28", "0.29"])
      allow(subject).to receive(:related_issues).and_return([])
      allow(subject).to receive(:extract_backport_pull_request_for_version).with(kind_of(Array), "0.28").and_return(nil)
      allow(subject).to receive(:extract_backport_pull_request_for_version).with(kind_of(Array), "0.29").and_return(nil)

      allow(subject).to receive(:system).and_raise(RuntimeError)

      expect(subject).to receive(:create_backport_task).with("0.28")
      expect(subject).to receive(:create_backport_task).with("0.29")

      subject.call
    end
  end

  describe ".extract_versions" do
    it "returns the versions" do
      allow(subject).to receive(:pull_request_metadata).and_return({ labels: ["type: fix", "release: v0.28", "release: v0.29"], is_merged: true })
      expect(subject.send(:extract_versions)).to eq(["0.28", "0.29"])
      expect(subject.send(:extract_versions).size).to eq(2)
    end

    it "returns empty array" do
      allow(subject).to receive(:pull_request_metadata).and_return({ labels: ["type: fix", "team: documentation", "module: initiatives"], is_merged: true })
      expect(subject.send(:extract_versions)).to eq([])
      expect(subject.send(:extract_versions).size).to eq(0)
    end
  end

  describe ".create_backport_task" do

    before do
      allow(subject).to receive(:pull_request_metadata).and_return({ title: "Foo Bar", labels: ["type: fix", "release: v0.28"]})
    end

    it "returns the respose from the server" do
      expect(subject.send(:create_backport_task, "0.29")).to be_a Faraday::Response
    end
  end

end

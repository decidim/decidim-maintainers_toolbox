# frozen_string_literal: true

require "decidim/maintainers_toolbox/github_manager/querier/by_issue_id"
require "webmock/rspec"

RSpec.describe Decidim::MaintainersToolbox::GithubManager::Querier::ByIssueId do
  let(:querier) { described_class.new(token: "abc", issue_id: 12_345) }

  before do
    stub_request(:get, "https://api.github.com/repos/decidim/decidim/issues/12345")
      .to_return(status: 200, body: body, headers: {})
  end

  describe ".call" do
    context "when ticket is an issue" do
      let(:body) { '{"number": 12345, "title": "Fix whatever", "labels": [{"name": "type: fix"}, {"name": "module: admin"}]}' }
      let(:response) do
        {
          labels: ["module: admin", "type: fix"],
          modules: ["module: admin"],
          type: ["type: fix"],
          id: 12_345,
          state: nil,
          is_merged: false,
          is_pull_request: false,
          title: "Fix whatever"
        }
      end

      it "returns a valid response" do
        expect(querier.call).to eq response
      end
    end

    context "when issue is a PR" do
      context "when merged" do
        let(:body) { '{"number": 12345, "pull_request": {"merged_at": "2024-09-19T08:08:50Z" }, "title": "Fix whatever", "labels": [{"name": "type: fix"}, {"name": "module: admin"}]}' }
        let(:response) do
          {
            labels: ["module: admin", "type: fix"],
            modules: ["module: admin"],
            type: ["type: fix"],
            id: 12_345,
            state: nil,
            is_merged: true,
            is_pull_request: true,
            title: "Fix whatever"
          }
        end

        it "returns a valid response" do
          expect(querier.call).to eq response
        end
      end

      context "when closed" do
        let(:body) { '{"number": 12345, "pull_request": {"merged_at": "" }, "title": "Fix whatever", "labels": [{"name": "type: fix"}, {"name": "module: admin"}]}' }
        let(:response) do
          {
            labels: ["module: admin", "type: fix"],
            modules: ["module: admin"],
            type: ["type: fix"],
            id: 12_345,
            state: nil,
            is_merged: false,
            is_pull_request: true,
            title: "Fix whatever"
          }
        end

        it "returns a valid response" do
          expect(querier.call).to eq response
        end
      end

      context "when active" do
        let(:body) { '{"number": 12345, "pull_request": {"merged_at": "" }, "title": "Fix whatever", "labels": [{"name": "type: fix"}, {"name": "module: admin"}]}' }
        let(:response) do
          {
            labels: ["module: admin", "type: fix"],
            modules: ["module: admin"],
            type: ["type: fix"],
            id: 12_345,
            state: nil,
            is_merged: false,
            is_pull_request: true,
            title: "Fix whatever"
          }
        end

        it "returns a valid response" do
          expect(querier.call).to eq response
        end
      end
    end

  end
end

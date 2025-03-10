# frozen_string_literal: true

require "decidim/maintainers_toolbox/backporter"

RSpec.describe Decidim::MaintainersToolbox::Backporter do
  subject { described_class.new(token: token, pull_request_id: pull_request_id, version_number: version_number, exit_with_unstaged_changes: exit_with_unstaged_changes, with_console: with_console) }

  let(:token) { "1234" }
  let(:pull_request_id) { 123 }
  let(:version_number) { "0.1" }
  let(:exit_with_unstaged_changes) { true }
  let(:with_console) { true }

  describe ".backport_branch" do
    let(:pull_request_title) { "Hello world" }

    it "works as expected" do
      expect(subject.send(:backport_branch, pull_request_title)).to eq "backport/0.1/hello-world-123"
    end

    context "when the title has a backtick" do
      let(:pull_request_title) { "Hello world `free -m`" }

      it "escapes it" do
        expect(subject.send(:backport_branch, pull_request_title)).to eq "backport/0.1/hello-world-free--m-123"
      end
    end

    context "when the title has a dollar sign" do
      let(:pull_request_title) { "Hello world $(free -m)" }

      it "escapes it" do
        expect(subject.send(:backport_branch, pull_request_title)).to eq "backport/0.1/hello-world-free--m-123"
      end
    end

    # @see https://unix.stackexchange.com/a/270979
    context "when the title has a character that needs to be escaped" do
      let(:pull_request_title) { %q(Hello world `~!$&*(){[|\;'"↩<>?) }

      it "escapes it" do
        expect(subject.send(:backport_branch, pull_request_title)).to eq "backport/0.1/hello-world--123"
      end
    end
  end
end

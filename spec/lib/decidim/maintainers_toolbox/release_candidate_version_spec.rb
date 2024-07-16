# frozen_string_literal: true

require "decidim/maintainers_toolbox/release_candidate_version"
require_relative "../../../shared/releaser_repository_shared_context"

RSpec.describe Decidim::MaintainersToolbox::ReleaseCandidateVersion do
  subject { described_class.new(token: token, working_dir: tmp_repository_dir) }

  let(:token) { "1234" }
  let(:tmp_repository_dir) { "/tmp/decidim-release-candidate-version-test-#{rand(1_000)}" }

  include_context "releaser repository"

  describe "#release_branch" do
    it "returns the correct branch" do
      expect(subject.send(:release_branch)).to eq release_branch
    end
  end

  describe "#next_version_number_for_release_candidate" do
    context "when it is a dev version" do
      let(:version_number) { "0.1.0.dev" }

      it "returns the first release candidate" do
        expect(subject.send(:next_version_number_for_release_candidate, version_number)).to eq "0.1.0.rc1"
      end
    end

    context "when it is a release candidate version" do
      let(:version_number) { "0.1.0.rc1" }

      it "returns the correct next version number" do
        expect(subject.send(:next_version_number_for_release_candidate, version_number)).to eq "0.1.0.rc2"
      end
    end

    context "when it is a patch version" do
      let(:version_number) { "0.1.0" }

      it "raises an error" do
        expect { subject.send(:next_version_number_for_release_candidate, version_number) }.to raise_error(Decidim::MaintainersToolbox::ReleaserUtils::InvalidVersionTypeError)
      end
    end
  end

  context "if this is release branch with a patch version" do
    let(:decidim_version) { "0.99.0" }
    let(:release_branch) { "release/0.99-stable" }

    it "exits" do
      expect { subject.call }.to raise_error SystemExit
    end
  end

  context "if this is feature branch" do
    let(:decidim_version) { "0.99.0.rc1" }
    let(:release_branch) { "feature/fix-my-street" }

    it "exits" do
      expect { subject.call }.to raise_error SystemExit
    end
  end
end

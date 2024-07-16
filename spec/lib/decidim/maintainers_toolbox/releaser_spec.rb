# frozen_string_literal: true

require "decidim/maintainers_toolbox/releaser"
require_relative "../../../shared/releaser_repository_shared_context"

RSpec.describe Decidim::MaintainersToolbox::Releaser do
  subject { described_class.new(token: token, version_type: version_type, exit_with_unstaged_changes: exit_with_unstaged_changes, working_dir: tmp_repository_dir) }

  let(:token) { "1234" }
  let(:version_type) { "patch" }
  let(:exit_with_unstaged_changes) { true }

  let(:tmp_repository_dir) { "/tmp/decidim-releaser-test-#{rand(1_000)}" }

  include_context "releaser repository"

  describe "#branch" do
    it "returns the correct branch" do
      expect(subject.send(:branch)).to eq release_branch
    end
  end

  describe "#parsed_version_number" do
    context "when it is a dev version" do
      let(:version_number) { "1.2.3.dev" }

      it "parses the version number" do
        expect(subject.send(:parsed_version_number, version_number)).to eq([1, 2, 3])
      end
    end

    context "when it is a release candidate version" do
      let(:version_number) { "1.2.3.rc1" }

      it "parses the version number" do
        expect(subject.send(:parsed_version_number, version_number)).to eq([1, 2, 3])
      end
    end

    context "when it is a patch version" do
      let(:version_number) { "1.2.3" }

      it "parses the version number" do
        expect(subject.send(:parsed_version_number, version_number)).to eq([1, 2, 3])
      end
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
        expect { subject.send(:next_version_number_for_release_candidate, version_number) }.to raise_error(Decidim::MaintainersToolbox::Releaser::InvalidVersionTypeError)
      end
    end
  end

  describe "#next_version_number_for_patch_release" do
    context "when it is a dev version" do
      let(:version_number) { "0.1.0.dev" }

      it "returns the correct next version number" do
        expect { subject.send(:next_version_number_for_patch_release, version_number) }.to raise_error(Decidim::MaintainersToolbox::Releaser::InvalidVersionTypeError)
      end
    end

    context "when it is a release candidate version" do
      let(:version_number) { "0.1.0.rc1" }

      it "returns first patch number" do
        expect(subject.send(:next_version_number_for_patch_release, version_number)).to eq "0.1.0"
      end
    end

    context "when it is a patch version" do
      let(:version_number) { "0.1.0" }

      it "raises an error" do
        expect(subject.send(:next_version_number_for_patch_release, version_number)).to eq "0.1.1"
      end
    end
  end

  describe "#old_version_number" do
    let(:decidim_version) { "0.1.0" }

    it "returns the correct version number" do
      expect(subject.send(:old_version_number)).to eq "0.1.0"
    end
  end
end

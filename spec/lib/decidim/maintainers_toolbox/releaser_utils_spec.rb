# frozen_string_literal: true

require "decidim/maintainers_toolbox/releaser"
require_relative "../../../shared/releaser_repository_shared_context"

RSpec.describe Decidim::MaintainersToolbox::ReleaserUtils do

  subject do
    class DummyClass
      include Decidim::MaintainersToolbox::ReleaserUtils
    end

    klass = DummyClass.new
    klass
  end

  let(:tmp_repository_dir) { "/tmp/decidim-releaser-utils-test-#{rand(1_000)}" }

  include_context "releaser repository"

  describe "#bump_decidim_version" do
    it "writes the file" do
      version_number = File.read(".decidim-version").strip
      expect(version_number).to eq("0.99.0.rc1")

      subject.bump_decidim_version("0.99.0.rc2")

      new_version_number = File.read(".decidim-version").strip
      expect(new_version_number).to eq("0.99.0.rc2")
    end
  end

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

  describe "#old_version_number" do
    let(:decidim_version) { "0.1.0" }

    it "returns the correct version number" do
      expect(subject.send(:old_version_number)).to eq "0.1.0"
    end
  end
end

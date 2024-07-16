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
end

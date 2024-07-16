# frozen_string_literal: true

require "decidim/maintainers_toolbox/release_patch_version"
require_relative "../../../shared/releaser_repository_shared_context"

RSpec.describe Decidim::MaintainersToolbox::ReleasePatchVersion do
  subject { described_class.new(token: token, working_dir: tmp_repository_dir) }

  let(:token) { "1234" }
  let(:tmp_repository_dir) { "/tmp/decidim-release-patch-version-test-#{rand(1_000)}" }

  include_context "releaser repository"

  describe "#release_branch" do
    it "returns the correct branch" do
      expect(subject.send(:release_branch)).to eq release_branch
    end
  end
end


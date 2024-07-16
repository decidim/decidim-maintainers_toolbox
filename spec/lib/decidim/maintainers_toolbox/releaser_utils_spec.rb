# frozen_string_literal: true

require "decidim/maintainers_toolbox/releaser"

RSpec.describe Decidim::MaintainersToolbox::ReleaserUtils do

  subject do
    class DummyClass
      include Decidim::MaintainersToolbox::ReleaserUtils
    end

    klass = DummyClass.new
    klass
  end

  let(:working_dir) { File.expand_path("../../..", __dir__) }
  let(:tmp_repository_dir) { "/tmp/decidim-releaser-utils-test-#{rand(1_000)}" }
  let(:decidim_version) { "0.99.0.rc1" }
  let(:release_branch) { "release/0.99-stable" }

  before do
    FileUtils.mkdir_p("#{tmp_repository_dir}/code")
    Dir.chdir("#{tmp_repository_dir}/code")
    `
      git init --initial-branch=develop .
      git config user.email "decidim_releaser@example.com"
      git config user.name "Decidim::ReleaserUtils test"

      touch a_file.txt && git add a_file.txt
      echo #{decidim_version} > .decidim-version && git add .decidim-version
      git commit -m "Initial commit (#1234)"

      git branch #{release_branch}
      git switch --quiet #{release_branch}
    `
  end

  after do
    Dir.chdir(working_dir)
    FileUtils.rm_r(Dir.glob(tmp_repository_dir))
  end

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

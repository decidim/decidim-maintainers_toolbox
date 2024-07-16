# frozen_string_literal: true

RSpec.shared_context "releaser repository" do
  let(:working_dir) { File.expand_path("../../..", __dir__) }
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

end

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
end

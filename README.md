# Decidim::MaintainersToolbox

Release related tools for the Decidim project.

Tools for releasing, backporting, changelog generating, and working with GitHub

## Installation

TODO: Replace `UPDATE_WITH_YOUR_GEM_NAME_PRIOR_TO_RELEASE_TO_RUBYGEMS_ORG` with your gem name right after releasing it to RubyGems.org. Please do not do it earlier due to security reasons. Alternatively, replace this section with instructions to install your gem from git if you do not plan to release to RubyGems.org.

This gem is meant to be used outside of bundler/Gemfile so we do not need to bump the version every time we release a new one to each of the releases branch.

```console
gem install UPDATE_WITH_YOUR_GEM_NAME_PRIOR_TO_RELEASE_TO_RUBYGEMS_ORG
```

## Usage

This gem allows preparing and working with Decidim releases. Is it meant to be used by maintainers of the project. In the near future most of these tools will be used by `decidim-bot`.

There are a couple differences with the rest of the gems of this repository:

* About the versioning: as it has not decidim nor decidim-core as dependencies, and to keep it easy to work with, we will not have the same versioning as the others gems.
* About the ruby version: to make it possible to work with older decidim versions, we will support the lowest supported ruby version.

This is the reason why its in a different repository and not in the decidim repository.

The main scripts are `decidim-backporter`, `decidim-backports-checker`, `decidim-changelog-generator` and `decidim-releaser`.

### decidim-backporter

See [Backports documentation](https://docs.decidim.org/en/develop/develop/backports)

### decidim-backports-checker

See [Backports documentation](https://docs.decidim.org/en/develop/develop/backports)

### decidim-changelog-generator

Used for generating the changelog with all the Pull Requests that goes to the current release. To be used automatically by the `releaser` script.

### decidim-releaser

See [Releasing new versions documentation](https://docs.decidim.org/en/develop/develop/maintainers/releases)

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Releases

As this gem is meant to be used outside of the main decidim gems, we will not follow the same versioning. We will release a new version of this gem every time we have a new feature or bugfix that we need to use. This also means that we will not follow the same release process.

To release this gem, follow these steps:

. Bump the version number in `lib/decidim/maintainers_toolbox/version.rb` following [Semantic Versioning](https://semver.org/).
. Update the `CHANGELOG.md` with the new version and the changes.
. Commit the changes.
. Create a new tag with the version number.
. Push the changes and the tag to the repository.
. Run `rake build` to build the gem.
. Run `rake release` to publish the gem to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/decidim/decidim.

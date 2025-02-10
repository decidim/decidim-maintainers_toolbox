# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.0] - 2025-02-10

### Fixed

-  Fix rspec call with environment variables

## [0.4.0] - 2025-02-10

### Changed

- Update ruby version from 2.7.5 to 3.0.2

### Fixed

-  Make directory check compatible with latest versions of ruby (#11)

## [0.3.0] - 2024-09-25

### Added

- decidim-action-backporter: Add action backporter

## [0.2.0] - 2024-04-25

### Fixed

- Fix activesupport dependency requirement (#5)

## [0.1.0] - 2024-03-15

### Added

- Initial release with the scripts:
  - `decidim-backporter`: to do the backports itself.
  - `decidim-backports-checker`: to see the status of the pending backports.
  - `decidim-changelog-generator`: to generate the changelog for a release.
  - `decidim-releaser`: to do the release itself.

[0.0.1]: https://github.com/decidim/decidim-maintainers_toolbox/releases/tag/v0.1.0

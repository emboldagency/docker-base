<!-- markdownlint-disable MD024 -->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org).

## [Unreleased]

[What's this section for?](https://keepachangelog.com/en/1.1.0/#effort)

<!-- ### Added  -->
<!-- ### Changed  -->
<!-- ### Deprecated -->
<!-- ### Removed -->
<!-- ### Fixed -->
<!-- ### Security -->

## [v1.3.0](https://github.com/emboldagency/docker-base/tree/v1.3.0) - 2025-06-11

### Added

- Install additional system administration, development, and troubleshooting tools in the base image.

### Changed

- Refactor Dockerfile to streamline package installation by combining all packages into a single `apt-get install` block, grouped and alphabetized for clarity.
- Update Dockerfile to use Ubuntu 24.04 as the base image and Node.js 20.19.0 as the default Node version.

[Full Changelog](https://github.com/emboldagency/docker-base/compare/v1.2.0...v1.3.0)

## [v1.2.0](https://github.com/emboldagency/docker-base/tree/v1.2.0) - 2024-12-03

### Deprecated

- Deprecated getting dotfiles URL from API on staging

[Full Changelog](https://github.com/emboldagency/docker-base/compare/v1.1.0...v1.2.0)

## [v1.1.0](https://github.com/emboldagency/docker-base/tree/v1.1.0) - 2024-08-07

### Added

- Workflow can be run manually

### Changed

- Fix deprecations

[Full Changelog](https://github.com/emboldagency/docker-base/compare/v1.0.0...v1.1.0)

## [v1.0.1](https://github.com/emboldagency/docker-base/tree/v1.0.1) - 2024-08-07

### Added

- Changelog

### Changed

- Set GitHub Actions to only run when a new tag is published

[Full Changelog](https://github.com/emboldagency/docker-base/compare/v1.0.0...v1.0.1)

## [v1.0.0](https://github.com/emboldagency/docker-base/tree/v1.0.0) - 2024-08-07

Initial release

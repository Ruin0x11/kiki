# kiki
A Danbooru2 to [szurubooru](https://github.com/rr-/szurubooru) mass post importer. Automatically adds new tags if they are missing.

## Notes
- The code is specific to my needs and hardcodes a few constants. It is provided as-is. More work is needed for out of the box use.
- The necessary tags that Danbooru2 provides must be set up in szurubooru first before importing anything.
- Only the Danbooru2-to-szurubooru scenario is fully supported. There is preliminary code for using a few other sites as sources.
- Since szurubooru does not support pools or artist commentary, there is no ability to import them yet.

## Usage
```
bundle install
bundle exec rake jobs:work

# example import task, needs customization
bundle exec import:execute
```

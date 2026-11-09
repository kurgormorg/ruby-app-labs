ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
# Bootsnap's native file cache cannot open this Windows path containing Cyrillic.
# Bundler and Rails work without the optional cache.

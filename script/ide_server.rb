# RubyMine entry point: Dir.pwd preserves Cyrillic paths on Windows Ruby.
ARGV.unshift("server", "-b", "127.0.0.1", "-p", "3000")
load File.join(Dir.pwd, "bin/rails")

require 'thor'
require 'pry'

module KeywordIdeas
  class CLI < Thor
    desc 'volumes', 'estimate search volumes from keywords'
    def volumes(words)
      puts KeywordIdeas::Search.new.volumes(words)
    end

    desc 'volumes_from_file', 'estimate search volumes from keywords'
    def volumes_from_file(file)
      binding.pry
      whole_words = File.open(file).map(&:chomp)

    end

    desc 'related', 'explore related words from seed'
    def related(word, opts={})
      arr = KeywordIdeas::Search.new.related_volumes(word, opts)
      File.open("#{word}_related_keywords.txt", 'w') do |fo|
        arr.each do |row|
          row = row.join("\t") if row.kind_of? Array
          fo.write(row)
          fo.write("\n")
        end
      end
    end

    desc 'related_from_file', 'explore related words from seeds_file'
    def related_from_file(file)
      File.open(file).each do |line|
        related(line.chomp)
      end
    end

    desc 'wide_related', 'explore related words from seed'
    def wide_related(word)
      related(word, split: true, depth: 3)
    end
  end
end

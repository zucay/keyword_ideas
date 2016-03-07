require 'thor'

module KeywordIdeas
  class CLI < Thor
    desc 'volumes', 'estimate search volumes from keywords'
    def volume(words)
      puts KeywordIdeas::Search.new.related_volumes(words)
    end

    desc 'related', 'explore related words from seed'
    def related(word)
      arr = KeywordIdeas::Search.new.related_volumes(word)
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
  end
end

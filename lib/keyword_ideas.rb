require 'keyword_ideas/version'
require 'keyword_ideas/cli'
require 'adwords_api'

module KeywordIdeas
class Search
  PAGE_SIZE = 100
  def initialize(opts = {})
    @api_version = opts[:api_version] # nilを許容.nilの場合はDefault(:v201601等）が利用される
    @config_file = opts[:config_file] # nilを許容.nilの場合はENV['HOME']/adwords_api.ymlからファイルを読み込む
  end

  def volumes(keywords, opts = {})
    execute(selector(keywords, opts)).map do |result|
      [result[:data]['KEYWORD_TEXT'][:value], result[:data]['SEARCH_VOLUME'][:value]]
    end
  end

  def related_volumes(search_word, opts = {})
    opts[:depth] ||= 1
    opts[:split] ||= false

    next_search_queries = [search_word] # 再帰的に次に検索するためのワード一次保存変数
    queries = [] # 累計で調べ済みのワード
    query_volumes = []
    (1..opts[:depth]).each do |i|
      p next_search_queries
      break if next_search_queries.empty?
      results = execute(related_selector(next_search_queries.shift(50), opts))
      results.map do |result|
        query = result[:data]['KEYWORD_TEXT'][:value].to_s
        volume = result[:data]['SEARCH_VOLUME'][:value]
        # p [query, volume]
        query_volumes << [query, volume]

        if opts[:split]
          words = query.split(' ')
        else
          words = [query]
        end
        words.each do |word|
          next_search_queries <<  word unless queries.include?(word)
          queries << word
        end

      end
    end
    query_volumes.sort {|a, b| b[1] <=> a[1]}.uniq
  end

  private

  def service
    @adwords ||= AdwordsApi::Api.new(@config_file)
    @service ||= @adwords.service(:TargetingIdeaService, @api_version)
    @service
  end

  def selector(queries_or_query, opts={})
    opts[:language_id] = 1005 #日本語
    opts[:start_index] = 0

    queries = [queries_or_query] if queries_or_query.kind_of?(String)
    queries ||= queries_or_query

    {
      idea_type: 'KEYWORD',
      #:request_type => 'IDEAS',
      request_type: 'STATS',
      requested_attribute_types: ['KEYWORD_TEXT', 'SEARCH_VOLUME', 'CATEGORY_PRODUCTS_AND_SERVICES'],
      search_parameters: [
        {
          # The 'xsi_type' field allows you to specify the xsi:type of the object
          # being created. It's only necessary when you must provide an explicit
          # type that the client library can't infer.
          xsi_type: 'RelatedToQuerySearchParameter',
          queries: queries
        },
        {
          # Language setting (optional).
          # The ID can be found in the documentation:
          #  https://developers.google.com/adwords/api/docs/appendix/languagecodes
          # Only one LanguageSearchParameter is allowed per request.
          xsi_type: 'LanguageSearchParameter',
          languages: [{id: opts[:language_id]}] #日本語
        }
      ],
      paging: {
        start_index: opts[:start_index],
        number_results: PAGE_SIZE
      }
    }
  end

  def related_selector(queries, opts={})
    selector = selector(queries, opts)
    selector[:request_type] = 'IDEAS'
    selector
  end

  def execute(selector)
    offset = 0
    results = []
    begin
      # p "#{selector[:search_parameters][0][:queries]} offset: #{offset}"
      page = invoke_api(selector)
      results += page[:entries] if page and page[:entries]
      offset += PAGE_SIZE
      selector[:paging][:start_index] = offset
    end while offset < page[:total_num_entries]
    results.uniq
  end

  def invoke_api(selector)
    fail_count = 0
    begin
      page = service.get(selector)
    rescue => e
      #binding.pry
      p e
      fail_count +1
      sleep(30 + (4 * fail_count * fail_count))
      if fail_count < 3
        retry
      else
        return {}
      end
    end
    print '.'
    sleep(10)
    return page
  end
end
end
KeywordIdeas::CLI.start

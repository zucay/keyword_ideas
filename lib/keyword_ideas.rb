require 'keyword_ideas/version'
require 'keyword_ideas/cli'
require 'adwords_api'
require 'pry'
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

  def related_volumes(keyword, opts = {})
    opts[:depth] ||= 3

    next_search_keywords = [keyword] # 再帰的に次に検索するためのワード一次保存変数
    keyword_texts = [] # 累計で調べ済みのワード
    volumes = []
    (1..opts[:depth]).each do |i|
      p next_search_keywords
      break if next_search_keywords.empty?
      results = execute(related_selector(next_search_keywords, opts))
      next_search_keywords.clear
      results.map do |result|
        next_search_keywords << result[:data]['KEYWORD_TEXT'][:value] unless keyword_texts.include?(result[:data]['KEYWORD_TEXT'][:value])
        keyword_texts << result[:data]['KEYWORD_TEXT'][:value]
        arr = [result[:data]['KEYWORD_TEXT'][:value], result[:data]['SEARCH_VOLUME'][:value]]
        # p arr
        volumes << arr
      end
    end
    volumes.uniq
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
      results = page[:entries] if page and page[:entries]
      offset += PAGE_SIZE
      selector[:paging][:start_index] = offset
    end while offset < page[:total_num_entries]
    results
  end

  def invoke_api(selector)
    fail_count = 0
    begin
      page = service.get(selector)
    rescue => e
      #binding.pry
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

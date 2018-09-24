# frozen_string_literal: true

require 'uri'
require 'json'

module QuickSearch
  # QuickSearch seacher for archivesspace
  class ArchivesSpaceSearcher < QuickSearch::Searcher
    include ActionView::Helpers::SanitizeHelper

    def search
      @response = @http.get(uri, follow_redirect: true)
      @results = JSON.parse response.body
      @total = total
    end

    def results
      return @results_list if @results_list

      @results_list = @results.dig('response', 'docs').map do |row|
        OpenStruct.new(
          link: get_hyperlink(row),
          title: get_title(row),
          description: get_description(row)
        )
      end
      @results_list
    end

    def total
      @results.dig('response', 'numFound') || 0
    end

    def loaded_link
      base = URI.parse native_host
      term = http_request_queries['uri_escaped'] || ''
      q_params = { 'q' => native_base_query_params['q'].dup << term }
      base.query = native_base_query_params.deep_merge(q_params).to_query
      base.to_s
    end

    private

      def host
        QuickSearch::Engine::ARCHIVES_SPACE_CONFIG['search_url']
      end

      def native_host
        QuickSearch::Engine::ARCHIVES_SPACE_CONFIG['loaded_link']
      end

      def record_types
        query = Array(QuickSearch::Engine::ARCHIVES_SPACE_CONFIG['object_types']).map do |type|
          "\"#{type}\""
        end.join(' OR ')
        "types:#{query}"
      end

      def fq_query
        base_query_params['fq'].dup << record_types
      end

      def uri
        base = URI.parse host
        base.query = base_query_params.deep_merge(
          'q' => term_query,
          'fq' => fq_query
        ).to_query
        base
      end

      def term_query
        params = base_query_params['q'].dup <<
                 "fullrecord:(#{http_request_queries['uri_escaped'] || ''})"
        params.join(' AND ')
      end

      def base_query_params
        QuickSearch::Engine::ARCHIVES_SPACE_CONFIG['query_params'].dup
      end

      def native_base_query_params
        QuickSearch::Engine::ARCHIVES_SPACE_CONFIG['native_query_params'].dup
      end

      # Returns the hyperlink to use
      def get_hyperlink(row)
        URI.join(native_host, row.dig('uri')).to_s
      end

      # Returns the string to use for the result title
      def get_title(row)
        strip_tags(row.dig('title'))
      end

      # Returns the string to use for the result description
      def get_description(row)
        description = row.dig('summary') || ''
        content_tag(:div,
                    content_tag(:p, strip_tags(description)),
                    class: ['block-with-text'])
      end
  end
end

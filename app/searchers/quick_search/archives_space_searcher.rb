# frozen_string_literal: true

require 'uri'
require 'nokogiri'

module QuickSearch
  # QuickSearch seacher for archivesspace
  class ArchivesSpaceSearcher < QuickSearch::Searcher
    def search
      @response = @http.get(uri, follow_redirect: true)
      @results = Nokogiri::HTML response.body
      @total = total
    end

    def results
      return @results_list if @results_list

      @results_list = @results.css(row_selector).map do |row|
        OpenStruct.new(
          link: get_hyperlink(row),
          title: get_title(row),
          description: get_description(row)
        )
      end
      @results_list
    end

    def total
      return '' unless @results.title

      @results.title.match(/(\d+)/).to_s
    end

    def loaded_link
      uri.to_s
    end

    private

      def host
        QuickSearch::Engine::ARCHIVES_SPACE_CONFIG['search_url']
      end

      def uri
        base = URI.parse host
        search_term = Array.wrap(http_request_queries['uri_escaped'] || '')
        base.query = base_query_params.merge('q' => search_term).to_query
        base
      end

      def base_query_params
        QuickSearch::Engine::ARCHIVES_SPACE_CONFIG['query_params']
      end

      def sanitize_tags
        QuickSearch::Engine::ARCHIVES_SPACE_CONFIG['sanitize_tags']
      end

      def row_selector
        QuickSearch::Engine::ARCHIVES_SPACE_CONFIG['row_selector']
      end

      def link_selector
        QuickSearch::Engine::ARCHIVES_SPACE_CONFIG['link_selector']
      end

      def description_selector
        QuickSearch::Engine::ARCHIVES_SPACE_CONFIG['description_selector']
      end

      # Returns the hyperlink to use
      def get_hyperlink(row)
        URI.join(host, row.at(link_selector)['href']).to_s
      end

      # Returns the string to use for the result title
      def get_title(row)
        row.at(link_selector).text.strip
      end

      # Returns the string to use for the result description
      def get_description(row)
        description = row.at(description_selector) || ''
        content_tag(:div,
                    content_tag(:p, sanitize_html(description)),
                    class: ['block-with-text'])
      end

      def sanitize_html(html)
        return html if html.is_a? String

        html.children.each do |node|
          node.remove if sanitize_tags.include? node.name
        end
        html.text.strip
      end
  end
end

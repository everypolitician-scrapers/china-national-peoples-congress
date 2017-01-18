#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(url)
  noko = noko_for(url)

  section = noko.xpath('//h2[contains(span,"选举单位")]')
  areas = section.xpath('following-sibling::h2 | following-sibling::dl').slice_before { |e| e.name == 'h2' }.first

  areas.each do |area|
    ps = area.xpath('following-sibling::p | following-sibling::dl').slice_before { |e| e.name == 'dl' }.first
    ps.each do |p|
      p.css('a').each do |person|
        data = {
          name:     person.text,
          wikiname: person.attr('class') == 'new' ? '' : person.attr('title'),
          area:     area.css('dt').first.text.split('（').first.tidy,
          term:     '12',
        }
        ScraperWiki.save_sqlite(%i(name wikiname area), data)
      end
    end
  end
end

ScraperWiki.sqliteexecute('DELETE FROM data') rescue nil
scrape_list('https://zh.wikipedia.org/wiki/%E7%AC%AC%E5%8D%81%E4%BA%8C%E5%B1%8A%E5%85%A8%E5%9B%BD%E4%BA%BA%E6%B0%91%E4%BB%A3%E8%A1%A8%E5%A4%A7%E4%BC%9A%E4%BB%A3%E8%A1%A8%E5%90%8D%E5%8D%95')

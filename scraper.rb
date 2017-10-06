#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'


def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(url)
  noko = noko_for(url)
  section = noko.css('h2').find { |h2| h2.text.include? '选举单位' } or raise "Can't find section"
  section.xpath('.//preceding::*').remove

  section_end = noko.css('h2').find { |h2| h2.text.include? '代表变动情况' } or raise "Can't find section end"
  section_end.xpath('.//following::*').remove

  noko.css('dl dt').each do |area|
    area.xpath('.//following::p').first.css('a').each do |person|
      data = {
        name:     person.text,
        wikiname: person.attr('class') == 'new' ? '' : person.attr('title'),
        area:     area.text.split('（').first.tidy,
        term:     '12',
      }
      puts data.reject { |_, v| v.to_s.empty? }.sort_by { |k, _| k }.to_h if ENV['MORPH_DEBUG']
      ScraperWiki.save_sqlite(%i(name wikiname area), data)
    end
  end
end

ScraperWiki.sqliteexecute('DELETE FROM data') rescue nil
scrape_list('https://zh.wikipedia.org/wiki/%E7%AC%AC%E5%8D%81%E4%BA%8C%E5%B1%8A%E5%85%A8%E5%9B%BD%E4%BA%BA%E6%B0%91%E4%BB%A3%E8%A1%A8%E5%A4%A7%E4%BC%9A%E4%BB%A3%E8%A1%A8%E5%90%8D%E5%8D%95')

# frozen_string_literal: true

require_relative '../spec/rails_helper'
require 'benchmark/ips'

include PerformanceHelpers
include TestHelpers

clear_test_data!
build_blog_models!
build_real_estate_models!

author = Darwin::Runtime.const_get('Author')
article = Darwin::Runtime.const_get('Article')
comment = Darwin::Runtime.const_get('Comment')
listing = Darwin::Runtime.const_get('Listing')
lead = Darwin::Runtime.const_get('Lead')

puts "Seeding baseline data..."
faker_blog_records(count: 100)
faker_real_estate_records(count: 50)

Benchmark.ips do |x|
  x.report('blog insert author+articles+comments') do
    faker_blog_records(count: 1)
  end

  x.report('blog author query with join') do
    article.joins(:author).order('articles.id DESC').limit(50).to_a
  end

  x.report('real estate insert city+listing+leads') do
    faker_real_estate_records(count: 1)
  end

  x.report('real estate listings query') do
    listing.joins(:city, :agent).where('price > 0').limit(50).to_a
  end

  x.compare!
end

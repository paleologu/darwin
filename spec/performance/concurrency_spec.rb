# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Concurrency and scalability', type: :model do
  before(:each) do
    clear_test_data!
  end

  it 'supports concurrent runtime reloads without losing columns' do
    build_blog_models!

    threads = []
    errors = Queue.new

    4.times do
      threads << Thread.new do
        begin
          Darwin::Runtime.reload_all!(builder: true)
        rescue => e
          errors << e
        end
      end
    end

    threads.each(&:join)
    expect(errors.empty?).to be(true), "Errors encountered: #{errors.pop&.message}"

    author = Darwin::Runtime.const_get('Author')
    expect(author.column_names).to include('name', 'bio')
  end

  it 'can bulk insert blog records and query efficiently' do
    build_blog_models!
    author = Darwin::Runtime.const_get('Author')
    article = Darwin::Runtime.const_get('Article')
    comment = Darwin::Runtime.const_get('Comment')

    time_block('blog bulk insert 5 authors') do
      faker_blog_records(count: 5)
    end

    expect(author.count).to eq(5)
    expect(article.count).to eq(10) # 2 per author
    expect(comment.count).to eq(30) # 3 per article

    time_block('blog aggregate query') do
      article.joins(:author).limit(50).to_a
    end
  end

  it 'can bulk insert real estate records and query efficiently' do
    build_real_estate_models!
    listing = Darwin::Runtime.const_get('Listing')
    lead = Darwin::Runtime.const_get('Lead')

    time_block('real estate bulk insert 5 cities') do
      faker_real_estate_records(count: 5)
    end

    expect(listing.count).to eq(15) # 3 per city
    expect(lead.count).to eq(75)   # 5 per listing

    time_block('real estate aggregate query') do
      listing.joins(:city, :agent).where('price > 0').limit(100).to_a
    end
  end
end

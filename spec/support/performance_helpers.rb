# frozen_string_literal: true

module PerformanceHelpers
  def build_blog_models!
    require 'faker'
    author = Darwin::Model.create!(name: 'Author')
    article = Darwin::Model.create!(name: 'Article')
    comment = Darwin::Model.create!(name: 'Comment')

    # attributes
    author.columns.create!(name: 'name', column_type: 'string')
    author.columns.create!(name: 'bio', column_type: 'text')
    article.columns.create!(name: 'title', column_type: 'string')
    article.columns.create!(name: 'content', column_type: 'text')
    comment.columns.create!(name: 'body', column_type: 'text')

    # associations
    author.blocks.create!(method_name: 'has_many', args: ['articles'])
    article.blocks.create!(method_name: 'belongs_to', args: ['author'])
    article.blocks.create!(method_name: 'has_many', args: ['comments'], options: { dependent: :destroy })
    comment.blocks.create!(method_name: 'belongs_to', args: ['article'])

    Darwin::SchemaManager.sync!(author)
    Darwin::SchemaManager.sync!(article)
    Darwin::SchemaManager.sync!(comment)
    Darwin::Runtime.reload_all!(builder: true)
  end

  def build_real_estate_models!
    listing = Darwin::Model.create!(name: 'Listing')
    agent = Darwin::Model.create!(name: 'Agent')
    city = Darwin::Model.create!(name: 'City')
    lead = Darwin::Model.create!(name: 'Lead')

    # attributes
    city.columns.create!(name: 'name', column_type: 'string')
    city.columns.create!(name: 'state', column_type: 'string')
    agent.columns.create!(name: 'name', column_type: 'string')
    agent.columns.create!(name: 'email', column_type: 'string')
    listing.columns.create!(name: 'address', column_type: 'string')
    listing.columns.create!(name: 'price', column_type: 'integer')
    lead.columns.create!(name: 'email', column_type: 'string')
    lead.columns.create!(name: 'interest_level', column_type: 'integer')

    # associations
    city.blocks.create!(method_name: 'has_many', args: ['listings'])
    listing.blocks.create!(method_name: 'belongs_to', args: ['city'])
    listing.blocks.create!(method_name: 'belongs_to', args: ['agent'])
    agent.blocks.create!(method_name: 'has_many', args: ['listings'])
    listing.blocks.create!(method_name: 'has_many', args: ['leads'], options: { dependent: :destroy })
    lead.blocks.create!(method_name: 'belongs_to', args: ['listing'])

    [listing, agent, city, lead].each { |m| Darwin::SchemaManager.sync!(m) }
    Darwin::Runtime.reload_all!(builder: true)
  end

  def faker_blog_records(count:)
    require 'faker'
    author_class = Darwin::Runtime.const_get('Author')
    article_class = Darwin::Runtime.const_get('Article')
    comment_class = Darwin::Runtime.const_get('Comment')

    count.times do
      author = author_class.create!(name: Faker::Book.author, bio: Faker::Lorem.paragraph_by_chars(number: 200))
      2.times do
        article = article_class.create!(
          author_id: author.id,
          title: Faker::Book.title,
          content: Faker::Lorem.paragraphs(number: 3).join("\n\n")
        )
        3.times do
          comment_class.create!(article_id: article.id, body: Faker::Lorem.sentence(word_count: 12))
        end
      end
    end
  end

  def faker_real_estate_records(count:)
    require 'faker'
    city_class = Darwin::Runtime.const_get('City')
    agent_class = Darwin::Runtime.const_get('Agent')
    listing_class = Darwin::Runtime.const_get('Listing')
    lead_class = Darwin::Runtime.const_get('Lead')

    count.times do
      city = city_class.create!(name: Faker::Address.city, state: Faker::Address.state_abbr)
      agent = agent_class.create!(name: Faker::Name.name, email: Faker::Internet.email)
      3.times do
        listing = listing_class.create!(
          city_id: city.id,
          agent_id: agent.id,
          address: Faker::Address.street_address,
          price: Faker::Number.number(digits: 6)
        )
        5.times do
          lead_class.create!(
            listing_id: listing.id,
            email: Faker::Internet.email,
            interest_level: Faker::Number.between(from: 1, to: 5)
          )
        end
      end
    end
  end

  def time_block(label)
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
    puts "#{label}: #{format('%.3f', elapsed)}s"
    elapsed
  end
end

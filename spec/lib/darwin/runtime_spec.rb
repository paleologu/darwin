# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Darwin::Runtime do
  before(:all) do
    setup_test_data!
  end

  describe '.reload_all!' do
    it 'defines the runtime classes' do
      expect(Object.const_defined?('Author')).to be true
      expect(Object.const_defined?('Article')).to be true
      expect(Object.const_defined?('Comment')).to be true
    end

    it 'correctly builds the schema' do
      expect(Author.column_names).to include('name', 'desc')
      expect(Article.column_names).to include('title', 'content')
      expect(Comment.column_names).to include('message')
    end
  end

  describe 'has_one associations' do
    before do
      # Using find_or_create_by to avoid creating duplicate models on re-runs
      @user_model = Darwin::Model.find_or_create_by!(name: 'User')
      @profile_model = Darwin::Model.find_or_create_by!(name: 'Profile')

      # Define has_one association from User to Profile
      @user_model.blocks.find_or_create_by!(
        method_name: 'has_one',
        args: ['profile']
      )

      # Define an attribute on Profile to test against
      @profile_model.blocks.find_or_create_by!(
        method_name: 'attribute',
        args: %w[bio string]
      )

      # Undefine classes if they exist to ensure a clean load
      %i[User Profile].each do |const|
        Object.send(:remove_const, const) if Object.const_defined?(const)
      end

      # Reload the runtime to apply the new definitions
      Darwin::Runtime.reload_all!

      # Define constants in the global namespace for the test
      Object.const_set('User', Darwin::Runtime.const_get('User'))
      Object.const_set('Profile', Darwin::Runtime.const_get('Profile'))
    end

    after do
      # Clean up models and constants
      @user_model.destroy
      @profile_model.destroy
      %i[User Profile].each do |const|
        Object.send(:remove_const, const) if Object.const_defined?(const)
      end
    end

    it 'defines the has_one association on the runtime class' do
      expect(User.new).to respond_to(:profile)
    end

    it 'correctly links the associated records' do
      user = User.create!
      profile = user.create_profile!(bio: 'A brief bio.')

      expect(user.profile).to eq(profile)
      expect(profile.user).to eq(user)
    end
  end
end

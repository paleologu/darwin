Darwin::Engine.routes.draw do
  root to: 'models#index'
  constraints format: /html|turbo_stream/ do
    resources :models, param: :name, except: [:show], path: '/' do
      resources :blocks, only: [:new, :create, :destroy]
      get :attribute_type, on: :member
      post :columns, to: "models#add_column", on: :member
      patch '/columns/:id', to: "models#update_column", as: :column, on: :member
      delete '/columns/:id', to: "models#destroy_column", as: :column_delete, on: :member
    end
    namespace :v2 do 
      get '/editor(/:model_name)' => 'models#editor', as: :editor
      get '/home' => "static#home", as: :home
      post '/models/:model_name/columns' => 'models#add_column', as: :model_columns
    end
    get '/:model_name' => 'records#index', as: :records
    get '/:model_name/new' => 'records#new', as: :new_record
    post '/:model_name' => 'records#create'
    get '/:model_name/:id' => 'records#show', as: :record
    get '/:model_name/:id/edit' => 'records#edit', as: :edit_record
    patch '/:model_name/:id' => 'records#update'
    delete '/:model_name/:id' => 'records#destroy'
  end
end

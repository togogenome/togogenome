TogoGenome::Application.routes.draw do
  root to: 'root#index'

  resources :facets, only: %w(show) do
    get :search, on: :member
  end

  match '/proteins/search', via: :get, as: :search_proteins
  resources :genomes, only: %w(index) do
    get :search, on: :collection
  end

  match '/converter', via: :get, as: :converter, to: 'converter#index'
  match '/resolver', via: :get, as: :resolver, to: 'resolver#index'
  get '/identifiers/convert'
  get '/identifiers/teach'

  # 複数形にしたい所だけど、利用者にはこちらの方が分かりやすいらしい
  resources :gene,        only: %w(show), constraints: { id: /[\w\-\:\.\/]+/ }
  resources :organism,    only: %w(show), constraints: { id: /[\w\-\:\.]+/ }
  resources :environment, only: %w(show), constraints: { id: /[\w\-\:\.]+/ }
  resources :phenotype,   only: %w(show), constraints: { id: /MPO_\d+/ }

  namespace :api do
    match '/gggenome' => 'gggenome#show', via: :post
  end
end

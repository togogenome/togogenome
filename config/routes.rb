TogoGenome::Application.routes.draw do
  root to: 'root#index'

  resources :facets, only: %w(show) do
    get :search, on: :member
  end

  match '/proteins/search', via: :get, as: :search_proteins
  resources :genomes, only: %w(index) do
    get :search, on: :collection
  end

  match '/mappings/index', via: :get, as: :mappings
  match '/mappings/convert', via: :get, as: :convert_mappings

  # 複数形にしたい所だけど、利用者にはこちらの方が分かりやすいらしい
  resources :gene,        only: %w(show), constraints: { id: /[\w\-\:\.\/]+/ }
  resources :organism,    only: %w(show), constraints: { id: /[\w\-\:\.]+/ }
  resources :environment, only: %w(show), constraints: { id: /[\w\-\:\.]+/ }
  resources :phenotype,   only: %w(show), constraints: { id: /MPO_\d+/ }

  namespace :api do
    match '/gggenome' => 'gggenome#show', via: :post
  end
end

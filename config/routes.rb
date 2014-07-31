TogoGenome::Application.routes.draw do
  root to: 'root#index'

  resources :facets, only: %w(show) do
    get :search, on: :member
  end

  get '/proteins/search', as: :search_proteins
  resources :genomes, only: %w(index) do
    get :search, on: :collection
  end

  resources :text, only: %w(index) do
    get :search, on: :collection
  end

  get '/converter', as: :converter, to: 'converter#index'
  get '/resolver', as: :resolver, to: 'resolver#index'
  get '/identifiers/convert'
  get '/identifiers/teach'

  # デフォルトだと id にドットを含められないので、id が取り得る文字列を正規表現で指定する
  resources :stanza, only: [], id: /[^\/]+/ do
    get :search, on: :member, controller: :text, action: :search_stanza
  end

  # 複数形にしたい所だけど、利用者にはこちらの方が分かりやすいらしい
  resources :gene,        only: %w(show), constraints: { id: /[\w\-\:\.\/]+/ }
  resources :organism,    only: %w(show), constraints: { id: /[\w\-\:\.]+/ }
  resources :environment, only: %w(show), constraints: { id: /[\w\-\:\.]+/ }
  resources :phenotype,   only: %w(show), constraints: { id: /MPO_\d+/ }

  namespace :api do
    post '/gggenome', to: 'gggenome#show'
  end
end

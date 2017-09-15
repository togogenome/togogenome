TogoGenome::Application.routes.draw do
  root to: 'root#index'

  resources :facets, only: %w(show) do
    get :search, on: :member
  end

  namespace :report_type do
    resources :genes, only: %w(index)
    resources :organisms, only: %w(index)
    resources :environments, only: %w(index)
    resources :phenotypes, only: %w(index)
  end

  resources :genomes, only: %w(index) do
    get :search, on: :collection
  end

  get '/compare', to: 'comparative_genome#index'

  get '/sequence', as: :sequence_index, to: 'sequence#index'
  get '/sequence/search', as: :sequence_search, to: 'sequence#search'

  get '/converter', as: :converter, to: 'converter#index'
  get '/resolver', as: :resolver, to: 'resolver#index'
  get '/identifiers/convert'
  get '/identifiers/teach'

  get '/text', as: :text_index, to: 'stanza_search#index'
  get '/text/search', as: :text_search, to: 'stanza_search#show'

  # 複数形にしたい所だけど、利用者にはこちらの方が分かりやすいらしい
  resources :gene,        only: %w(show), constraints: { id: /[\w\-\:\.\/]+/ }
  resources :organism,    only: %w(show), constraints: { id: /[\w\-\:\.]+/ }
  resources :environment, only: %w(show), constraints: { id: /[\w\-\:\.]+/ }
  resources :phenotype,   only: %w(show), constraints: { id: /MPO_\d+/ }

  namespace :api do
    post '/gggenome', to: 'gggenome#show'
  end
end

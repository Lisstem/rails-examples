Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  resources :collections do
    member do
      get :add_book
      post :insert_book
    end
  end
  resources :authors, only: :show do
    get :search, on: :collection
  end

  root 'collections#index'
end

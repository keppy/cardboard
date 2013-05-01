# Routes for admin interface
Cardboard::Engine.routes.draw do

  get "account", to: "users#edit", as: "user"
  put "account", to: "users#update", as: "user"

  get "pages/:id", to: "pages#edit"
  resources :pages

  get "/yoda", to: "super_user#index"

  get "/settings", to: "settings#index"
  put "/settings/update", to: "settings#update", as: "setting"

  get "/", to: "dashboard#index", as: "dashboard"
  #Don't put a root path here, use "/" instead... (to be able to use root_path in the pages)

  
  scope as: 'cardboard' do
    #generate routes for custom cardboard resources controllers
    Cardboard::AdminController.descendants.map{|x|x.controller_name.to_sym}.each do |controller|
      resources controller
    end
  end

end


# Routes for public pages
Rails.application.routes.draw do
  scope  :constraints => { :format => 'html' } do #:format => true,
    get "*id", to: "pages#show", as: :page
  end

  root :to => "pages#show"
end


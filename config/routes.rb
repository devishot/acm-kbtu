AcmKbtu::Application.routes.draw do

  resources :submits

  resources :problems

  resources :contests
  match '/contests/:id/upload' => 'contests#upload'
  post  '/contests/:id/unpack' => 'contests#unpack'
  post  '/contests/:id/participate' => 'contests#participate'
  delete 'kill_participant' => 'contests#kill_participant'

  match '/contests/:id/control' => 'contests#control'
  post  '/contests/:id/control/update' => 'contests#control_update'

  match '/contests/:id/statement' => 'contests#download_statement'

  match '/contests/:id/problems'=> 'problems#index'
  match '/contests/:id/standings'=> 'contests#standings'
  match '/contests/:id/messages' => 'contests#messages'
  match '/contests/:id/summary' => 'contests#summary'

  put '/contests/:id/:problem' => 'problems#update'
  match '/contests/:id/:problem' => 'problems#show'
  match '/contests/:id/:problem/edit' => 'problems#edit'

  match '/submits/:contest/:participant' => 'submits#index'
  match '/submits/:contest/:participant/:submit' => 'submits#src_code'
  post 'send_submit' => 'submits#create'

  devise_for :users

  resources :users

  root :to => 'pages#main'

  resources :nodes

  resources :pages

  match '/list' => 'pages#list'

  match '/my_account' => 'users#my_account'

  match '/pages/:node/:page' => 'pages#show'
  match '/pages/:node/:page/edit' => 'pages#edit'
  match '/pages/:node/:page/destroy' => 'pages#destroy'

  post '/upd_pages_order' => 'nodes#upd_pages_order'
  post '/upd_nodes_order' => 'nodes#upd_nodes_order'

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  #root :to => 'pages#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end

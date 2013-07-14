Sramplicons::Application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
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

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  get 'run/:run_id' => 'sramplicons#run', as: :run
  get 'run_iframe/:run_id' => 'sramplicons#run_iframe', as: :run_iframe
  get 'overview/:tax_ids' => 'sramplicons#overview', as: :overview
  get 'search' => 'sramplicons#search', as: :search
  get 'overview' => 'sramplicons#overview'
  get 'taxonomy' => 'sramplicons#taxonomy'
  get '' => 'sramplicons#index', as: :index
  get 'study/:study_id/prokmsa_ids/:prokmsa_ids' => 'sramplicons#study', :as => :study_with_prokmsa_ids
  get 'study/:study_id/taxonomy/:taxonomy_id' => 'sramplicons#study', :as => :study_with_taxonomy
  get 'study/:study_id' => 'sramplicons#study_generic', :as => :study
  get 'search_by_sra' => 'sramplicons#search_by_sra'
  get 'search_by_keyword' => 'sramplicons#search_by_keyword'
end

Spree::Core::Engine.routes.append do
  namespace :admin do
    resource :google_merchant_settings do
      post :generate_and_transfer_xml
    end
    resources :product_ad_channels do
      resources :product_ads
    end
    resources :product_ads

    get '/products/:product_id/product_ads', :to => 'product_ads#index'
  end
  get '/last_report', :to => 'last_reports#show'

end

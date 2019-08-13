class Spree::Admin::GoogleMerchantSettingsController < Spree::Admin::BaseController
  helper 'spree/admin/google_merchant'
  
  def update
    params.each do |name, value|
      next unless Spree::GoogleMerchant::Config.has_preference? name
      Spree::GoogleMerchant::Config[name] = value
    end
    
    respond_to do |format|
      format.html {
        redirect_to admin_google_merchant_settings_path
      }
    end
  end

  def generate_and_transfer_xml
    SpreeGoogleMerchant::FeedBuilder.generate_and_transfer

    redirect_to admin_google_merchant_settings_path, flash: {
      success: 'Wygenerowany plik został pomyślnie wysłany do Google Merchant Center.'
    }
  end

end

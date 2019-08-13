require 'net/ftp'

namespace :solidus_google_merchant do

  task :update_cpc_values => [:environment] do |t, args|
    cpc_manager = Spree::CpcManager.new
    Spree::Variant.all.each{|v|cpc_manager.set_variant_cpc_and_update_ads(v)} if cpc_manager.is_setup?
  end

  task :generate_and_transfer => [:environment] do |t, args|
    SolidusGoogleMerchant::FeedBuilder.generate_and_transfer
  end

  task :generate => [:environment] do |t, args|
    SolidusGoogleMerchant::FeedBuilder.generate
  end

  task :transfer => [:environment] do |t, args|
    SolidusGoogleMerchant::FeedBuilder.transfer
  end

  task :generate_and_transfer_shipments => [:environment] do |t, args|
    SolidusGoogleMerchant::ShippingFeedBuilder.generate_and_transfer
  end

  task :generate_shipments => [:environment] do |t, args|
    SolidusGoogleMerchant::ShippingFeedBuilder.generate
  end

  task :transfer_shipments => [:environment] do |t, args|
    SolidusGoogleMerchant::ShippingFeedBuilder.transfer
  end

  task :generate_and_transfer_cancellations => [:environment] do |t, args|
    SolidusGoogleMerchant::CancellationFeedBuilder.generate_and_transfer
  end

  task :generate_cancellations => [:environment] do |t, args|
    SolidusGoogleMerchant::CancellationFeedBuilder.generate
  end

  task :transfer_cancellations => [:environment] do |t, args|
    SolidusGoogleMerchant::CancellationFeedBuilder.transfer
  end

  task :generate_and_transfer_amazon => [:environment] do |t, args|
    SolidusGoogleMerchant::AmazonFeedBuilder.generate_and_transfer
  end

  task :generate_amazon => [:environment] do |t, args|
    SolidusGoogleMerchant::AmazonFeedBuilder.generate
  end

  task :transfer_amazon => [:environment] do |t, args|
    SolidusGoogleMerchant::AmazonFeedBuilder.transfer
  end

  task :generate_and_transfer_ebay => [:environment] do |t, args|
    SolidusGoogleMerchant::EbayFeedBuilder.generate_and_transfer
  end

  task :generate_ebay => [:environment] do |t, args|
    SolidusGoogleMerchant::EbayFeedBuilder.generate
  end

  task :transfer_ebay => [:environment] do |t, args|
    SolidusGoogleMerchant::EbayFeedBuilder.transfer
  end

  task :generate_and_transfer_bing => [:environment] do |t, args|
    SolidusGoogleMerchant::BingFeedBuilder.generate_and_transfer
  end

  task :generate_bing => [:environment] do |t, args|
    SolidusGoogleMerchant::BingFeedBuilder.generate
  end

  task :transfer_bing => [:environment] do |t, args|
    SolidusGoogleMerchant::BingFeedBuilder.transfer
  end
end

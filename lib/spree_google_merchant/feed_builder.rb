require 'net/ftp'

module SpreeGoogleMerchant
  class FeedBuilder
    include Spree::Core::Engine.routes.url_helpers

    attr_reader :store, :domain, :title
    SpreeGoogleMerchant::FeedBuilder::GOOGLE_MERCHANT_ATTR_MAP = [
        ['g:id', 'id'],
        ['g:gtin','gtin'],
        ['g:mpn', 'mpn'],
        ['title', 'title'],
        ['description', 'description'],
        ['g:price', 'price'],
        ['g:sale_price','sale_price'],
        ['g:condition', 'condition'],
        ['g:product_type', 'product_type'],
        ['g:brand', 'brand'],
        ['g:quantity','quantity'],
        ['g:availability', 'availability'],
        #['g:image_link','image_link'],
        ['g:google_product_category','product_category'],
        ['g:shipping_weight','shipping_weight'],
        ['g:gender','gender'],
        ['g:age_group','age_group'],
        ['g:color','color'],
        ['g:size','size'],
        ['g:adwords_grouping','adwords_group']
    ]

    def self.generate_and_transfer
      self.builders.each do |builder|
        builder.generate_and_transfer_store
      end
    end

    def self.generate
      self.builders.each do |builder|
        builder.generate_store
      end
    end

    def self.transfer
      self.builders.each do |builder|
        builder.transfer_xml
      end
    end

    def self.builders
      if defined?(Spree::Store)
        Spree::Store.all.map{ |store| self.new(:store => store) }
      else
        [self.new]
      end
    end

    def initialize(opts = {})
      raise "Please pass a public address as the second argument, or configure :public_path in Spree::GoogleMerchant::Config" unless
          opts[:store].present? or (opts[:path].present? or Spree::GoogleMerchant::Config[:public_domain])

      @store = opts[:store] if opts[:store].present?
      @title = @store ? @store.name : Spree::GoogleMerchant::Config[:store_name]

      @domain = @store ? @store.url : opts[:path]
      @domain ||= Spree::GoogleMerchant::Config[:public_domain]
    end

    def ads
      Spree::ProductAd.active.in_feed#.google_shopping
    end

    def prepare_ads
      ActiveRecord::Base.transaction do
        Spree::ProductAd.delete_all

        products = Spree::Product.has_description.in_stock.has_image.has_sku.content_verified
        Spree::Variant.where(product: products).where(is_master: true).find_each(batch_size: 1000).with_index do |variant, index|
          Spree::ProductAd.create!(
            variant: variant,
            state: :enabled
          )
          GC::start if index % 200 == 0
        end
      end
      true
    end

    def generate_store
      delete_xml_if_exists
      prepare_ads

      File.open(path, 'w') do |file|
        generate_xml file
      end

    end

    def generate_and_transfer_store
      delete_xml_if_exists
      prepare_ads

      File.open(path, 'w') do |file|
        generate_xml file
      end

      transfer_xml
      cleanup_xml
    end

    def path
      "#{::Rails.root}/tmp/#{filename}"
    end

    def filename
      if Rails.env.development?
        "google_merchant_test.xml"
      else
        "google_merchant_v#{@store.try(:code)}.xml"
      end
    end

    def delete_xml_if_exists
      File.delete(path) if File.exists?(path)
    end

    def validate_record(ad)
      product = ad.variant.product
      # return false if product.google_merchant_brand.nil?
      return false if product.respond_to?(:discontinued?) && product.discontinued?# && product.google_merchant_quantity <= 0
      # return false unless validate_upc(ad.variant.upc)

      true
    end    
    
    def generate_xml output
      xml = Builder::XmlMarkup.new(:target => output, indent: 2)
      xml.instruct!

      xml.rss(:version => '2.0', :"xmlns:g" => "http://base.google.com/ns/1.0") do
        xml.channel do
          build_meta(xml)

          ads.find_each(batch_size: 50).with_index do |ad, index|
            next unless ad && ad.variant && ad.variant.product && validate_record(ad)
            build_feed_item(xml, ad)
          end
        end
      end
    end

    def transfer_xml
      raise "Please configure your Google Merchant :ftp_username and :ftp_password by configuring Spree::GoogleMerchant::Config" unless
          Spree::GoogleMerchant::Config[:ftp_username] and Spree::GoogleMerchant::Config[:ftp_password]
      require 'net/sftp'
      r = Net::SFTP.start('partnerupload.google.com', Spree::GoogleMerchant::Config[:ftp_username], :password => Spree::GoogleMerchant::Config[:ftp_password], port: 19321 ) do |sftp|
        sftp.upload!(path, filename)
        puts sftp.inspect
      end

      r

    end

    def cleanup_xml
      File.delete(path)
    end

    def build_feed_item(xml, ad)
      product = ad.variant.product
      xml.item do
        xml.tag!('link', product_url(product.slug, :host => domain))
        build_images(xml, product)

        GOOGLE_MERCHANT_ATTR_MAP.each do |k, v|
          value = ad.variant.send("google_merchant_#{v}")
          xml.tag!(k, value.to_s) if value.present?
        end
        build_shipping(xml, ad)
        build_adwords_labels(xml, ad)
        build_custom_labels(xml, ad)
      end
    end

    def build_images(xml, product)
      main_image, *more_images = product.master.images

      if !main_image.blank?
        more_images += product.variants.map(&:images).flatten
      else
        main_image, *more_images = product.variants.map(&:images).flatten
      end


      return unless main_image
      xml.tag!('g:image_link', main_image.attachment.url(:large))

      more_images.each do |image|
        xml.tag!('g:additional_image_link', image.attachment.url(:large))
      end
    end

    def image_url image
      base_url = image.attachment.url(:large)
      base_url = "#{protocol}#{domain.sub(/\/\Z/, '').sub(/\Ahttp:\/\//, '')}#{base_url}"# unless Spree::Config[:use_s3]

      base_url
    end

    def validate_upc(upc)
      return true if upc.nil?
      digits = upc.split('')
      len = upc.length
      return false unless [8,12,13,14].include? len
      check = 0
      digits.reverse.drop(1).reverse.each_with_index do |i,index|
        check += (index.to_i % 2 == len % 2 ? i.to_i * 3 : i.to_i )
      end
      ((10 - check % 10) % 10) == digits.last.to_i
    end

    # <g:shipping>
    def build_shipping(xml, ad)
      product = ad.variant.product
      shipping_cost = product.google_merchant_shipping_cost
      if shipping_cost && shipping_cost > 0
        xml.tag!('g:shipping') do
          xml.tag!('g:country', "US")
          xml.tag!('g:service', "Ground")
          xml.tag!('g:price', shipping_cost.to_f)
        end
      end
    end

    # <g:adwords_labels>
    def build_adwords_labels(xml, ad)
      product = ad.variant.product
      labels = []

      taxon = product.taxons.first
      unless taxon.nil?
        labels = taxon.self_and_ancestors.pluck(:name)
      end

      labels.slice(0..9).each do |l|
        xml.tag!('g:adwords_labels', l)
      end
    end

    def build_custom_labels(xml, ad)
      product = ad.variant.product

      # Set availability
      xml.tag!('g:custom_label_0', product.google_merchant_availability)

      # Set CPC
      channel = ad.channel
      max_cpc = nil
      if ad.max_cpc
        max_cpc = ad.max_cpc
      elsif ad.variant && ad.variant.max_cpc
        max_cpc = ad.variant.max_cpc / 0.65
      elsif channel && channel.default_max_cpc
        max_cpc = channel.default_max_cpc
      end
      xml.tag!('g:custom_label_1', '%.2f' % max_cpc) if max_cpc
    end

    def build_meta(xml)
      xml.title @title
      xml.link @domain
    end

    def protocol
      'http://'
    end
  end
end

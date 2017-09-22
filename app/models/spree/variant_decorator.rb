Spree::Variant.class_eval do
  has_many :product_ads
  after_create :create_product_ads

  def create_product_ads
    Spree::ProductAdChannel.all.each do |channel|
      if product_ads.select{|ad|ad.channel == channel}.empty?
        product_ads.create(
          :channel => channel, 
          :state => "enabled", 
          :max_cpc => (self.max_cpc || channel.default_max_cpc)
        )
      end
    end
  end


  def google_merchant_description
    product.description
  end

  def google_merchant_title
    product.name
  end

  # <g:google_product_category> Apparel & Accessories > Clothing > Dresses (From Google Taxon Map)
  def google_merchant_product_category
    product.google_merchant_product_category
  end

  def google_merchant_product_type
    product.google_merchant_product_type
  end

  # <g:condition> new | used | refurbished
  def google_merchant_condition
    'new'
  end

  # <g:availability> in stock | available for order | out of stock | preorder
  def google_merchant_availability
    google_merchant_quantity > 0 ? 'in stock' : 'out of stock'
  end

  def google_merchant_quantity
    @quantity_available ||= begin
      stock_items.reduce(0){|sum, item|sum + item.count_on_hand}
    end
  end

  def google_merchant_image_link
    # self.max_image_url
    first_image.attachment.url(:large) rescue nil
  end

  def google_merchant_brand
    product.google_merchant_brand
  end

  # <g:price> 15.00 USD
  def google_merchant_price
    format("%.2f %s", self.price, self.currency).to_s
  end

  # <g:sale_price> 15.00 USD
  def google_merchant_sale_price
    if self.on_sale?
      format("%.2f %s", self.price, self.currency).to_s
    end
  end


  def google_merchant_id
    self.id
  end

  # <g:gtin> 8-, 12-, or 13-digit number (UPC, EAN, JAN, or ISBN)
  def google_merchant_gtin
    product.google_merchant_gtin
  end

  # <g:mpn> Alphanumeric characters
  def google_merchant_mpn
    self.sku.gsub(/[^0-9a-z ]/i, '')
  end

  # <g:gender> Male, Female, Unisex
  def google_merchant_gender
    return product.google_merchant_gender
  end


  # <g:age_group> Adult, Kids
  def google_merchant_age_group
    product.google_merchant_age_group
  end

  # <g:color>
  def google_merchant_color
    ov = self.option_values.where(option_type_id: 1).first
    return "" unless ov
    ov.presentation
  end

  # <g:size>
  def google_merchant_size
    ov = self.option_values.where(option_type_id: 2).first
    return "" unless ov
    ov.presentation
  end

  # <g:adwords_grouping> single text value
  def google_merchant_adwords_group
    product.google_merchant_adwords_group
  end

  # <g:shipping_weight> # lb, oz, g, kg.
  def google_merchant_shipping_weight
    product.google_merchant_shipping_weight
  end

  def google_merchant_shipping_cost
    # use_fulfiller_fulfillment_cost? ? fulfiller_fulfillment_cost : master.fulfillment_cost
    0
  end
end
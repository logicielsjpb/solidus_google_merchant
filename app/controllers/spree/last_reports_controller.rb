module Spree
  class LastReportsController < Spree::StoreController


    def show
      data = open(Spree::LastReport::where(locale: I18n.locale).last.url)
      send_data data.read, filename: "products.xml", type: "application/xml", disposition: 'attachment', stream: 'true', buffer_size: '4096'

    end

  end
end

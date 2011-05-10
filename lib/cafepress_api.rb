# Copyright 2011 Benjamin Lee Smith <benjamin.lee.smith@gmail.com>
#
# This file is part of CafePressAPI.
# CafePressAPI is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# CafePressAPI is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with CafePressAPI.  If not, see <http://www.gnu.org/licenses/>.

require 'rexml/document'
require 'open-uri'
require 'product_genders'
require 'product_colors'
module CafePressAPI
  RESULTS_PER_PAGE = 100
  FRONT_PRODUCT_VIEW = 'f'
  BACK_PRODUCT_VIEW = 'b'
  ADD_TO_CART_BASE_URL = 'http://www.cafepress.com/cp/addtocart.aspx'
  VIEW_CART_BASE_URL = 'http://www.cafepress.com/cp/viewcart.aspx'
  include ProductGenders
  include ProductColors

  def self.store_url(cafepress_store_id)
    "http://cafepress.com/#{cafepress_store_id}"
  end

  # Generates a url to add one product to a CafePress cart.
  # This isn't part of the CafePress API, use at your own risk!
  def self.add_to_cart_url(product_id, size, color, quantity, keep_shopping_url)
    "#{ADD_TO_CART_BASE_URL}?color_#{product_id}=#{color}&size_#{product_id}=#{size}&qty_#{product_id}=#{quantity}&keepshopping=#{keep_shopping_url}&storeid=search"
  end

  def self.user_token(app_key = ENV['cp_app_key'], email = ENV['cp_email'], password = ENV['cp_password'])
    content = ''
    open("http://open-api.cafepress.com/authentication.getUserToken.cp?appKey=#{app_key}&email=#{email}&password=#{password}") do |s| content = s.read end
    REXML::Document.new(content).root.text
  end

  def self.get_store_products(cafepress_store_id, app_key = ENV['cp_app_key'])
    content = ''
    products = []
    open("http://open-api.cafepress.com/product.listByStore.cp?v=3&appKey=#{app_key}&storeId=#{cafepress_store_id}&page=0&pageSize=#{RESULTS_PER_PAGE}") do |s| content = s.read end
    doc = REXML::Document.new(content)
    doc.root.elements.to_a.each do |product|
      begin
        cafepress_back_design_id = product.get_elements("mediaConfiguration[@perspectives='Back']").first.attributes['designId']
      rescue
        cafepress_back_design_id = nil
      end

      # The CafePress API doesn't have a concept of genders... so I'm faking it
      # Gender mapping was created by hand, use at own risk
      if (gender = PRODUCT_GENDERS[product.attributes['merchandiseId']]).nil?
        gender = PRODUCT_GENDERS[product.attributes['defaultCaption']]
        if gender.nil?
          gender = UNISEX
          warn(%{
\nWARNING: the product with defaultCaption '#{product.attributes['defaultCaption']}' and merchandiseId #{product.attributes['merchandiseId']} does not exist in the gender mapping!\n
Please send benjamin.lee.smith@gmail.com an email and copy/paste this warning message.\n
Or better yet, add the mapping yourself in product_genders.rb and submit it back https://github.com/benjaminleesmith/cafepress_api\n
})
        end
      end

      # The CafePress API (at the time of this code) doesn't correctly return
      # product images only for the colors which are available for the product.
      # as such, I am filtering out "invalid" colors from the productUrl(s).
      # Except in the case where the API returns NO colors... then I am accepting
      # all images with a color id of "0", whatever that means...
      valid_color_ids = []
      product.get_elements('color').each do |color|
        color_id = color.attributes['id']
        valid_color_ids << color.attributes['id']

        # Check to see if this color should be added to ProductColors
        if COLORS[color_id].nil?
          warn(%{
\nWARNING: the color with id "#{color_id}", name "#{color.attributes['name']}", merchandiseId "#{product.attributes['merchandiseId']}", and colorSwatchUrl "#{color.attributes['colorSwatchUrl']}" does not exist in the color mapping!\n
Please send benjamin.lee.smith@gmail.com an email and copy/paste this warning message.\n
Or better yet, add the mapping yourself in product_colors.rb and submit it back https://github.com/benjaminleesmith/cafepress_api\n
          })
        end
      end

      image_urls = []
      product.get_elements("productImage").each do |product_image|
        # only parse if it is a product image for an available color
        if valid_color_ids.include?(product_image.attributes['colorId']) || valid_color_ids.length == 0
          if product_image.attributes['productUrl'].include?('_Front')
            image_urls << {:color_id => product_image.attributes['colorId'], :url => product_image.attributes['productUrl'], :view => FRONT_PRODUCT_VIEW, :size => product_image.attributes['imageSize']}
          elsif product_image.attributes['productUrl'].include?('_Back')
            image_urls << {:color_id => product_image.attributes['colorId'], :url => product_image.attributes['productUrl'], :view => BACK_PRODUCT_VIEW, :size => product_image.attributes['imageSize']}
          else
            warn("\nWARNING: the image url #{product_image.attributes['productUrl']} does not appear to be a front or back image, assuming it is a front image.")
            image_urls << {:color_id => product_image.attributes['colorId'], :url => product_image.attributes['productUrl'], :view => FRONT_PRODUCT_VIEW, :size => product_image.attributes['imageSize']}
          end
        end
      end

      # For some reason, there are some products without colors...
      if valid_color_ids.length == 0
        default_color_id = nil
      else
        begin
          default_color_id = product.get_elements("color[@default='true']").first.attributes['id']
        rescue
          # Some products HAVE colors, but don't have any set to default=true
          default_color_id = nil
        end
      end

      sizes = []
      default_size_id = nil
      product.get_elements("size").each do |size|
        sizes << {
          :cafepress_size_id => size.attributes['id'],
          :full_name => size.attributes['fullName'],
          :display_sell_price => size.attributes['displaySellPrice']
        }
        if size.attributes['default'] == 'true'
          default_size_id = size.attributes['id']
        end
      end

      products << {
        :name => product.attributes['name'],
        :default_caption => product.attributes['defaultCaption'],
        :cafepress_product_id => product.attributes['id'],
        :url => product.attributes['storeUri'],
        :cafepress_design_id => product.get_elements("mediaConfiguration[@perspectives='Front']").first.attributes['designId'],
        :cafepress_back_design_id => cafepress_back_design_id,
        :gender => gender, # See comment above
        :cafepress_merchandise_id => product.attributes['merchandiseId'],
        :default_color_id => default_color_id,
        :image_urls => image_urls,
        :default_cafepress_size_id => default_size_id,
        :sizes => sizes,
        :price => product.attributes['sellPrice']
      }
    end
    products
  end

  def self.get_design_url(cafepress_design_id, app_key = ENV['cp_app_key'])
    content = ''
    open("http://open-api.cafepress.com/design.find.cp?v=3&appKey=#{app_key}&id=#{cafepress_design_id}") do |s| content = s.read end
    doc = REXML::Document.new(content)
    doc.root.attributes['mediaUrl']
  end

  def self.get_store(cafepress_store_id, app_key = ENV['cp_app_key'])
    content = ''
    open("http://open-api.cafepress.com/store.findByStoreId.cp?v=3&appKey=#{app_key}&storeId=#{cafepress_store_id}") do |s| content = s.read end
    doc = REXML::Document.new(content)

    {:store_id => cafepress_store_id, :description => doc.root.attributes['description'], :title => doc.root.attributes['title']}
  end
end

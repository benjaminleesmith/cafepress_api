# Mapping between colors and colorIds
module ProductColors
  # color_id => color_description
  COLORS = {
    '6' => {
      :description =>'Black',
      :merchandise_swatches => {
        '1234' => 'http://www.cafepress.com/content/marketplace/img/swatches/swatch_darktshirt_black.gif'
      }
    }
  }

  module ClassMethods
    def lookup_swatch(color_id, merchandise_id)
      COLORS[color_id][:merchandise_swatches][merchandise_id]
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end
end
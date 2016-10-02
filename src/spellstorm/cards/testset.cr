
require "../cards.cr"

module Spellstorm

class ShieldCard < Card

  def typ_name : String
    "Щит"
  end

end


def init_card_db (arr : Array(Card))
  arr << ShieldCard.new()
end

end

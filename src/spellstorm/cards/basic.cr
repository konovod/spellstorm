require "../cards.cr"

module Spellstorm
  class ShieldCard < Card
    def typ_name : String
      "Щит"
    end

    def field_location(state : CardState) : CardLocation
      CardLocation::FieldShield
    end
  end

  class DangerCard < Card
    def typ_name : String
      "Угроза"
    end

    def field_location(state : CardState) : CardLocation
      CardLocation::FieldDanger
    end
  end

  class ActionCard < Card
    def typ_name : String
      "Действие"
    end
  end

  class EnchantCard < Card
    def typ_name : String
      "Чары"
    end
  end

  class SourceCard < Card
    def typ_name : String
      "Накопитель"
    end

    def field_location(state : CardState) : CardLocation
      CardLocation::FieldSource
    end
  end
end

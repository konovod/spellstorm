require "../cards.cr"

module Spellstorm
  class ShieldCard < Card
    def typ_name : String
      "Щит"
    end
  end

  class DangerCard < Card
    def typ_name : String
      "Угроза"
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
  end
end

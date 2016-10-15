require "../cards.cr"

module Spellstorm
  class ShieldCard < Card
    def typ_name : String
      "Щит"
    end

    def field_location(state : CardState) : CardLocation
      CardLocation::FieldShield
    end

    def estim_shield(state : CardState) : Int32
      @power
    end

    def hook_shield(state : CardStateMutable, other : CardStateMutable, value : Int32) : Int32
      if value > state.hp
        value -= state.hp
        state.hp = 0
        state.need_processing = true
        return value
      else
        state.hp -= value
        return 0
      end
    end

    def hook_played(state : CardStateMutable)
      state.hp = @power
    end

    def hook_processing(state : CardStateMutable)
      state.move CardLocation::Drop
    end
  end

  class DangerCard < Card
    def typ_name : String
      "Угроза"
    end

    def field_location(state : CardState) : CardLocation
      CardLocation::FieldDanger
    end

    def get_damage(state : CardState) : Int32
      @power
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

    def hook_processing(state : CardStateMutable)
      state.move CardLocation::Drop
    end

    def mana_feed(state : CardStateMutable, element : Element, value : Int32)
      return false if element != @element || state.hp + value > @power
      state.hp += value
      state.need_processing = state.hp >= @power
      true
    end

    def mana_provide(state : CardStateMutable, element : Element, value : Int32)
      return false if element != @element || state.hp < value
      state.hp -= value
      state.need_processing = state.hp >= @power
      true
    end

    def mana_source(state : CardState, element : Element)
      return 0 if element != @element
      state.hp
    end

    def mana_sink(state : CardState, element : Element)
      return 0 if element != @element
      @power - state.hp
    end
  end
end

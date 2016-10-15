require "./engine/*"
require "./utils.cr"

module Spellstorm
  enum CardLocation
    Deck
    Hand
    FieldShield
    FieldDanger
    FieldSource
    FieldOther
    Drop

    def self.field
      {FieldShield, FieldDanger, FieldSource, FieldOther}
    end
  end
  N_CARD_LOCATIONS = 7

  enum Element
    Neutral
    Fire
    Water
    Earth
    Air
  end
  N_ELEMENTS = 5

  alias ActionArray = Array(Action)

  abstract class Card
    property cost : Int32
    property element : Element
    property power : Int32
    property name : String

    abstract def typ_name : String

    def initialize(@name, @cost, @element, @power)
    end

    macro is_pure(x)
      def {{x}}(state : CardStateMutable, *args)
        {{x}}(state.raw, *args)
      end
    end

    def playable(player_state : PlayerState) : Bool
      player_state.max_mana(@element) >= @cost
    end

    # redefinable methods
    def field_location(state : CardState) : CardLocation
      CardLocation::FieldOther
    end

    def get_damage(state : CardState) : Int32
      0
    end

    def estim_shield(state : CardState) : Int32
      0
    end

    is_pure(field_location)
    is_pure(get_damage)
    is_pure(estim_shield)

    def hook_shield(state : CardStateMutable, other : CardStateMutable, value : Int32) : Int32
      value
    end

    def hook_damage(state : CardStateMutable, other : CardStateMutable, value : Int32) : Int32
      value
    end

    def damage_player(state : CardStateMutable, value : Int32)
      state.owner.opponent.hp -= value
    end

    def hook_played(state : CardStateMutable)
    end

    def hook_processing(state : CardStateMutable)
    end

    def mana_feed(state : CardStateMutable, element : Element, value : Int32)
      false
    end

    def mana_provide(state : CardStateMutable, element : Element, value : Int32)
      false
    end

    def mana_source(state : CardState, element : Element)
      0
    end

    def mana_sink(state : CardState, element : Element)
      0
    end

    is_pure(mana_source)
    is_pure(mana_sink)
  end

  abstract class Action
    abstract def perform

    def initialize
    end
  end

  class ActionPlay < Action
    getter card_index

    def initialize(@what : CardStateMutable)
    end

    def perform
      st = @what.owner
      card = @what.card
      raise "IMPOSSIBLE" unless st.pay_mana(card.element, card.cost)
      @what.move(card.field_location(@what))
      card.hook_played(@what)
    end
  end
end

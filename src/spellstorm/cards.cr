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

  alias CardIndex = Int32
  alias ActionArray = Array(Action)

  abstract class Card
    property cost : Int32
    property element : Element
    property power : Int32
    property name : String

    abstract def typ_name : String

    def initialize(@name, @cost, @element, @power)
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

    def damage_hook(state : CardState, other : Card, other_state : CardState, value : Int32) : Int32
      value
    end

    def damage_player(state : CardState, game : GameState, value : Int32)
      game.parts[state.side.opponent.to_i].hp -= value
    end

    def shield_card(state : CardState, other : Card, other_state : CardState, value : Int32) : Int32
      value
    end
  end

  abstract class Action
    abstract def perform(state : GameState)

    def initialize(@player : Player)
    end
  end

  class ActionPlay < Action
    getter card_index

    def initialize(@player, @card_index : CardIndex)
    end

    def perform(state : GameState)
      st = state.parts[@player.to_i]
      card = st.deck.cards[card_index]
      raise "IMPOSSIBLE" unless st.pay_mana(card.element, card.cost)
      loc = st.deck.cards[card_index].field_location(st.card_state(@card_index))
      st.move_card(card_index, loc)
    end
  end
end

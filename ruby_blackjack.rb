# https://jedi.mycohort.download/second-language/week-19/day-3/labs/ruby-blackjack/

# Game Class
class Game
  attr_accessor :human_player, :computer_dealer, :round_winner, :game_winner, :round_number, :num_decks, :deck

  def initialize(human, computer, deck_count)
    @human_player = human
    @computer_dealer = computer
    @round_winner = 'none yet'
    @game_winner = 'none yet'
    @round_number = 0
    @num_decks = deck_count
    compose_deck
  end

  def compose_deck
    empty_deck
    fill_deck
    shuffle_deck
    @num_decks -= 1
  end

  def empty_deck
    @deck = []
  end

  def fill_deck
    suits = %w[diamonds clubs hearts spades]
    (0..(suits.length - 1)).each do |s|
      @deck.push(Card.new(11, suits[s], 'ace'))
      (1..9).each do |c|
        @deck.push(Card.new((c + 1), suits[s], 'numbered'))
      end
      @deck.push(Card.new(10, suits[s], 'jack'))
      @deck.push(Card.new(10, suits[s], 'queen'))
      @deck.push(Card.new(10, suits[s], 'king'))
    end
  end

  def shuffle_deck
    @deck = @deck.shuffle
  end

  def deal
    @human_player.hand = []
    @computer_dealer.hand = []

    cards_to_deal = 4
    dealing_to_house = true
    while cards_to_deal.positive? && @num_decks.positive?
      if @deck.length.zero?
        compose_deck
        redo
      end
      if dealing_to_house
        deal_one(@computer_dealer)
      else
        deal_one(@human_player)
      end
      dealing_to_house = !dealing_to_house
      cards_to_deal -= 1
    end
    puts 'No more cards left to deal' unless @num_decks.positive?
  end

  def deal_one(player)
    @human_player.hand.push(@deck.shift) if player.instance_of?(Human)
    @computer_dealer.hand.push(@deck.shift) if player.instance_of?(Computer)
  end

  def swap_anti
    @human_player.bankroll -= 10
    @computer_dealer.bankroll += 10
  end

  def balance_tie
    @human_player.bankroll += 10
    @computer_dealer.bankroll -= 10
  end

  def reward_human
    @computer_dealer.bankroll -= 20
    @human_player.bankroll += 20
  end

  def end_round
    puts "round winner: #{@round_winner}"
    puts "#{human_player.name}'s bankroll: $#{human_player.bankroll}."
    puts "#{computer_dealer.name}'s bankroll: $#{computer_dealer.bankroll}"
  end
end

# Player Module
class Player
  attr_accessor :name, :bankroll, :hand

  def initialize(name, bankroll)
    @name = name
    @bankroll = bankroll
    @hand = []
  end

  def print_hand
    @hand.each { |e| puts "#{e.suit}, #{e.value}, #{e.face}" }
  end

  def sum_hand
    sum = 0
    aces = @hand.select { |k| k.value == 11 }

    # add all non-aces first
    @hand.map do |k, _|
      sum += k.value if k.value != 11
    end
    aces.map do |k, _|
      if (sum + k.value) > 21
        sum += 1
      elsif (sum + k.value) <= 21
        sum += k.value
      end
    end
    sum
  end
end

# Human Class extends PLayer
class Human < Player
  attr_accessor :wants_hit

  def initialize(name, bankroll)
    super
    @wants_hit = true
  end

  def stay
    @wants_hit = false
  end
end

# Computer Class extends PLayer
class Computer < Player
  def initialize
    super 'the_house', 10_000
  end

  def print_first
    e = @hand[0]
    puts "#{e.suit}, #{e.value}, #{e.face}"
  end

  def print_second
    e = @hand[1]
    puts "#{e.suit}, #{e.value}, #{e.face}"
  end
end

# Card Class
class Card
  attr_accessor :suit, :face
  attr_reader :value

  def initialize(value, suit, face)
    @value = value
    @suit = suit
    @face = face
  end
end

# ! Init Game
puts 'Welcome to ruby blackjack!'
puts 'Please enter your name'
human_name = gets.chomp
human = Human.new human_name, 1000
house = Computer.new
game = Game.new human, house, 5
# game.deck.each { |e| puts "#{e.suit}, #{e.value}, #{e.face}" }
puts 'Enter (d) to play a round. Enter (q) at any time to quit.'

cmd = ''
in_round = false
while cmd != 'q'
  cmd = gets.chomp
  if (cmd == 'd') && !in_round
    in_round = true
    game.swap_anti
    puts "#{human.name} bets $10. bankroll = $#{human.bankroll}"
    puts "#{house.name} holds bet. bankroll = $#{house.bankroll}"
    game.deal

    puts "#{human.name}'s Hand: "
    human.print_hand
    human_sum = human.sum_hand
    puts "#{human.name}'s Sum: #{human_sum}"

    puts "#{house.name}'s First Card: "
    house.print_first
    # puts "#{house.name}'s Hand: "
    # house.print_hand
    house_sum = house.sum_hand
    # puts "#{house.name}'s Sum: #{house_sum}"

    if (human_sum == 21) && (house_sum == 21)
      puts 'Blackjacks for everyone!'
      puts "#{house.name}'s Hidden Card: "
      house.print_second
      in_round = false
      game.round_winner = 'tie'
      game.balance_tie
      game.end_round
      next
    elsif human_sum == 21
      puts 'You got Blackjack!'
      in_round = false
      game.round_winner = human.name
      game.reward_human
      game.end_round
      next
    elsif house_sum == 21
      puts 'Dealer dealt themselves Blackjack :('
      puts "#{house.name}'s Hidden Card: "
      house.print_second
      in_round = false
      game.round_winner = house.name
      game.end_round
    else
      puts 'hit (h) or stay (s)?'
    end
  elsif (cmd == 's') && in_round
    puts 'you have decided to stay'

    puts "#{human.name}'s Hand: "
    human.print_hand
    human_sum = human.sum_hand
    puts "#{human.name}'s Sum: #{human_sum}"

    # puts "#{house.name}'s First Card: "
    # house.print_first
    puts "#{house.name}'s Hand: "
    house.print_hand
    house_sum = house.sum_hand
    puts "#{house.name}'s Sum: #{house_sum}"

    while house_sum < 17
      game.deal_one(house)
      house_sum = house.sum_hand
      puts "#{house.name} hits. Hand: "
      house.print_hand
      puts "#{house.name}'s Sum: #{house_sum}"
    end

    if house_sum > 21
      puts "#{house.name} busts at #{house_sum}!"
      game.round_winner = human.name
      game.reward_human
      game.end_round
      in_round = false
      next
    else
      puts "#{house.name} must stand at #{house_sum}"
    end

    if human_sum == house_sum
      game.round_winner = 'tie'
      game.balance_tie
    end
    if human_sum > house_sum
      game.round_winner = human.name
      game.reward_human
    end
    game.round_winner = house.name if human_sum < house_sum
    game.end_round
    in_round = false

  elsif (cmd == 'h') && in_round
    puts 'you have decided to hit'
    game.deal_one(human)

    puts "#{human.name}'s Hand: "
    human.print_hand
    human_sum = human.sum_hand
    puts "#{human.name}'s Sum: #{human_sum}"

    puts "#{house.name}'s First Card: "
    house.print_first
    # puts "#{house.name}'s Hand: "
    # house.print_hand
    house_sum = house.sum_hand
    # puts "#{house.name}'s Sum: #{house_sum}"

    if (human_sum == 21) && (house_sum == 21)
      in_round = false
      game.round_winner = 'tie'
      game.balance_tie
      game.end_round
      next
    elsif human_sum == 21
      in_round = false
      game.round_winner = human.name
      game.reward_human
      game.end_round
      next
    elsif house_sum == 21
      in_round = false
      game.round_winner = house.name
      game.end_round
    elsif human_sum > 21
      puts "#{human.name} busts!"
      in_round = false
      game.round_winner = house.name
      game.end_round

    else
      puts 'hit (h) or stay (s)?'
    end

  elsif cmd != 'q'
    puts 'invalid input'
  end
end
puts 'game over'

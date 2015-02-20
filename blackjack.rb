# encoding: UTF-8
require 'pry'

def logo
  '
   ______ _            _    _            _    
   | ___ \ |          | |  (_)          | |   
   | |_/ / | __ _  ___| | ___  __ _  ___| | __
   | ___ \ |/ _` |/ __| |/ / |/ _` |/ __| |/ /
   | |_/ / | (_| | (__|   <| | (_| | (__|   < 
   \____/|_|\__,_|\___|_|\_\ |\__,_|\___|_|\_\
                          _/ |                
                         |__/ '
end

# Cards and deck -------------------------------------------
def suits
  ['Hearts', 'Diamonds', 'Clubs', 'Spades']
end

def ranks
  ['Ace', 'King', 'Queen', 'Jack', 
    '10', '9', '8', '7', '6', '5', '4', '3', '2']
end

def value(rank)
  case rank
    when 'Ace' then [1,11]
    when 'King' then [10]
    when 'Queen' then [10]
    when 'Jack' then [10]
    else [rank.to_i]
  end
end

def face_down
  lambda do
    [
      ' ________ ',
      '|' + "".center(8) +'|',            
      '|' + "?".center(8) + '|',
      '|' + "".center(8) +'|',
      '|' + "".center(8) +'|',
      '|' + "?".center(8) + '|',       
      '|________|'
    ] 
  end
end

def face_up(suit, rank)
  lambda do
    [
      ' ________ ',
      '|' + "".center(8) +'|',            
      '|' + "#{rank}".center(8) + '|',
      '|' + "".center(8) +'|',
      '|' + "".center(8) +'|',
      '|' + "#{suit}".center(8) + '|',
      '|________|'
    ]
  end 
end

def deck
  deck = []
  suits.each do |suit| 
    ranks.each do |rank|
      deck << {
        name: "#{rank} of #{suit}", 
        suit: "#{suit}", 
        rank: "#{rank}", 
        value: value("#{rank}"), 
        face_up: face_up("#{suit}", "#{rank}"), 
        face_down: face_down
      }
    end
  end
  deck.shuffle!
end

def display_hand(hand)
  segments = []
  hand.each { |card| segments << card[:face_up].call }
  ['','','','','','',''].zip(*segments).each do |joined_segments| 
    puts joined_segments.inject { |a,b| a+b }
  end  
end

def display_hand_hidden(hand)
  segments = []
  segments << hand[0][:face_down].call
  hand[1..-1].each { |card| segments << card[:face_up].call }
  ['','','','','','',''].zip(*segments).each do |joined_segments| 
    puts joined_segments.inject { |a,b| a+b }
  end  
end

def get_card_by_name(name)
  deck.select { |card| card[:name] == name }.first
end
# Cards and deck -------------------------------------------

# Counting points ------------------------------------------
def aces(hand)
  aces = []
  hand.each { |card| aces << card if card[:rank] == 'Ace' }
  aces
end

def other_cards(hand)                                     
  other_cards = []
  hand.each { |card| other_cards << card if card[:rank] != 'Ace' }
  other_cards
end 

def points_aces(hand)  
  posibilities = []
  counter = 0
  while counter < aces(hand).size + 1
    posibilities << aces(hand).size + 10 * counter
    counter += 1
  end
  posibilities == [0] ? [0,0] : posibilities
end

def points_other_cards(hand)   
  points = 0                                  
  other_cards(hand).each { |card| points += 
    card[:value][0] }
  points
end

def points(hand)
  p_aces = points_aces(hand) 
  p_other = points_other_cards(hand)
  p_other + p_aces[1] > 21 ? p_other + p_aces[0] : p_other + p_aces[1]
end
# Counting points ------------------------------------------

# Initialization of game -----------------------------------
def game_state
  {
    deck: [],
    player_name: '',   
    dealer_bank: 50000,
    player_bank: 0,
    bet: 0,
    player_points: 0,
    dealer_points: 0,
    player_hand: [],
    dealer_hand: []
  }
end

def player_name(game_state)
  begin
    puts "\nWhat is your name, friend?"
    name = gets.chomp
  end while name == ''
  game_state[:player_name] = name
end


def player_bank(game_state)
  begin
    puts "\nHow much money do you have on you? (Max $1,000)"
    total_funds = gets.chomp.to_i 
  end while total_funds <= 0 || total_funds > 1000
  game_state[:player_bank] = total_funds
end

def initial_state_of_game
  system 'clear'
  puts logo
  puts "Welcome to the table!"
  puts "Blackjack pays 3 to 2."
  puts "Dealer must draw on 16 and stand on all 17's."
  puts "\n"
  state = game_state
  player_name(state)
  player_bank(state)
  state[:deck] = lambda { deck }
  state
end
# Initialization of game -----------------------------------

# Game internals -------------------------------------------
def bet(game_state)   
  begin
    system 'clear' 
    puts logo
    puts "You have #{game_state[:player_bank]} dollars left."
    puts "The Dealer has #{game_state[:dealer_bank]} dollars left."    
    puts "\nWhat is your bet for this hand?"
    bet = gets.chomp.to_i
  end while bet <= 0 || bet > game_state[:player_bank]
  game_state[:bet] = bet
end

def first_deal(game_state)
  cards = game_state[:deck].call
  2.times do
    game_state[:player_hand] << cards.shift
    game_state[:dealer_hand] << cards.shift
  end
  game_state[:deck] = lambda { cards }
  update_points(game_state)
end

def player_deal(game_state)
  cards = game_state[:deck].call
  game_state[:player_hand] << cards.shift
  game_state[:deck] = lambda { cards }
end

def player_bust?(game_state)
  points(game_state[:player_hand]) > 21
end 

def any_blackjacks?(game_state)
  if points(game_state[:player_hand]) == 21 then true
  elsif points(game_state[:dealer_hand]) == 21 then true
  else false
  end
end

def direct_win(game_state)
  if game_state[:player_points] == 21 && game_state[:dealer_points] == 21
    puts "\nIt's a Push"
    reset_stats(game_state)
  elsif game_state[:player_points] == 21
    puts "\nBlackjack! You win!"    
    game_state[:player_bank] += game_state[:bet]
    game_state[:dealer_bank] -= game_state[:bet]
    reset_stats(game_state)    
  elsif game_state[:dealer_points] == 21
    puts "\nBlackjack! The Dealer wins!"    
    game_state[:player_bank] -= game_state[:bet]
    game_state[:dealer_bank] += game_state[:bet]
    reset_stats(game_state)
  end
end

def non_direct_win(game_state)
  if game_state[:player_points] > game_state[:dealer_points]
    puts "\nYou win!"    
    game_state[:player_bank] += game_state[:bet]
    game_state[:dealer_bank] -= game_state[:bet]
    reset_stats(game_state)    
  elsif game_state[:player_points] < game_state[:dealer_points]
    puts "\nThe Dealer wins!"    
    game_state[:player_bank] -= game_state[:bet]
    game_state[:dealer_bank] += game_state[:bet]
    reset_stats(game_state)
  else
    puts "\nPush!" 
    reset_stats(game_state)
  end
end

def reset_stats(game_state)
  game_state[:deck] = lambda { deck }
  game_state[:bet] = 0,
  game_state[:player_hand].clear
  game_state[:dealer_hand].clear
end

def display_table(game_state, hidden)  
  system 'clear'
  puts logo
  puts "\nDealer:"
  if hidden
    display_hand_hidden(game_state[:dealer_hand])
  else
    display_hand(game_state[:dealer_hand])    
    puts game_state[:dealer_points]
  end
  puts "\n#{game_state[:player_name]}:"
  display_hand(game_state[:player_hand])
  puts game_state[:player_points]
end

def update_points(game_state)
  game_state[:player_points] = points(game_state[:player_hand])
  game_state[:dealer_points] = points(game_state[:dealer_hand])
end
# Game internals -------------------------------------------

# Main loop ------------------------------------------------
state = initial_state_of_game
loop do
  bet(state)
  first_deal(state)
  if any_blackjacks?(state)
    display_table(state, false)
    direct_win(state)
  else
    display_table(state, true)
    player_hits_or_stands(state)
    dealer_hits_or_stands(state)
    display_table(state, false)
    non_direct_win(state)
  end
  puts "\nDo you want to play again? (y/n)"
  again = gets.chomp.downcase 
  break if again != 'y'
  break if state[:player_bank] == 0
  reset_stats(state)
end
puts "\nGame Over!"
puts "You have #{state[:player_bank]} dollars on you!"

binding.pry
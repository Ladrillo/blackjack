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
                          _/ |Tealeaf rules!!!                
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
  deck.shuffle!.shuffle!.shuffle!
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
def blank_state
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

def player_name(state)
  begin
    puts "\nWhat is your name, friend?"
    name = gets.chomp
  end while name == ''
  state[:player_name] = name
end


def player_bank(state)
  begin
    puts "\nHow much money do you have on you? (Max $1000)"
    total_funds = gets.chomp.to_i 
  end while total_funds <= 0 || total_funds > 1000
  state[:player_bank] = total_funds
end

def initial_state_of_game
  system 'clear'
  puts logo
  puts "Welcome to the table!"
  puts "Blackjack pays 3 to 2."
  puts "Dealer must draw on 16 and stand on all 17's."
  puts "\n"
  initial_state = blank_state
  player_name(initial_state)
  player_bank(initial_state)
  initial_state[:deck] = lambda { deck }
  initial_state
end
# Initialization of game -----------------------------------

# Game internals -------------------------------------------
def bet(state)   
  begin
    system 'clear' 
    puts logo
    puts "\nYou have #{state[:player_bank]} dollars left."
    puts "The Dealer has #{state[:dealer_bank]} dollars left."    
    puts "\nWhat is your bet for this hand?"
    bet = gets.chomp.to_i
  end while bet <= 0 || bet > state[:player_bank]
  state[:bet] = bet
end

def first_deal(state)
  cards = state[:deck].call
  2.times do
    state[:player_hand] << cards.shift
    state[:dealer_hand] << cards.shift
  end
  state[:deck] = lambda { cards }
  update_points(state)
end

def deal(state, hand)
  cards = state[:deck].call
  state[hand] << cards.shift
  state[:deck] = lambda { cards }
  update_points(state)  
end

def hit(state, hand)
  deal(state, hand)
  display_table(state, true)
end 

def bust?(state, hand)
  points(state[hand]) > 21
end 

def any_blackjacks?(state)
  if points(state[:player_hand]) == 21 then true
  elsif points(state[:dealer_hand]) == 21 then true
  else false
  end
end

def update_for_win(state)
  state[:player_bank] += state[:bet]
  state[:dealer_bank] -= state[:bet]
end

def update_for_loss(state)
  state[:player_bank] -= state[:bet]
  state[:dealer_bank] += state[:bet]
end  

def direct_win(state)
  if state[:player_points] == 21 && state[:dealer_points] == 21
    puts "\nPush!"
    reset_stats(state)
  elsif state[:player_points] == 21
    puts "\nBlackjack! You win!"    
    update_for_win(state)
    reset_stats(state)    
  elsif state[:dealer_points] == 21
    puts "\nBlackjack! The Dealer wins!"    
    update_for_loss(state)
    reset_stats(state)
  end
end

def non_direct_win(state)
  if bust?(state, :player_hand)
    puts "\nYou bust!"
    update_for_loss(state)
    reset_stats(state)
  elsif bust?(state, :dealer_hand)
    puts "\nDealer busts!"
    update_for_win(state)
    reset_stats(state)
  elsif state[:player_points] > state[:dealer_points]
    puts "\nYou win!"    
    update_for_win(state)
    reset_stats(state)    
  elsif state[:player_points] < state[:dealer_points]
    puts "\nThe Dealer wins!"    
    update_for_loss(state)
    reset_stats(state)
  else
    puts "\nPush!" 
    reset_stats(state)
  end
end

def reset_stats(state)
  state[:deck] = lambda { deck }
  state[:bet] = 0,
  state[:player_hand].clear
  state[:dealer_hand].clear
end

def display_table(state, hidden)  
  system 'clear'
  puts logo
  puts "\nDealer:"
  if hidden
    display_hand_hidden(state[:dealer_hand])
    puts "?"
  else
    display_hand(state[:dealer_hand])    
    puts state[:dealer_points]
  end
  puts "\n#{state[:player_name]}:"
  display_hand(state[:player_hand])
  puts state[:player_points]
  puts state[:deck].call.size
end

def update_points(state)
  state[:player_points] = points(state[:player_hand])
  state[:dealer_points] = points(state[:dealer_hand])
end

def player_hits_or_stands(state)
  loop do
    begin
      puts "\nHit or Stand? (h/s)" 
      option = gets.chomp.downcase
    end while option != 'h' && option != 's'
    hit(state, :player_hand) if option == 'h'
    break if option == 's' || bust?(state, :player_hand)
  end
end   

def dealer_hits_or_stands(state)
  loop do
    hit(state, :dealer_hand)
    break if bust?(state, :dealer_hand) || (state[:dealer_points] > 16)
  end
end  

# Game internals -------------------------------------------

# Main loop ------------------------------------------------
def game_loop(state)  
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
    puts "\nDo you wish to bet again? (y/n)"
    again = gets.chomp.downcase 
    break if again != 'y'
    break if state[:player_bank] == 0
    reset_stats(state)
  end
end
# Main loop ------------------------------------------------


st = initial_state_of_game
game_loop(st)
puts "\nGame Over!"
puts "You have #{state[:player_bank]} dollars on you!"

binding.pry
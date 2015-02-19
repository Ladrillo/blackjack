# encoding: UTF-8
require 'pry'

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
  puts "\nYour cards:"
  segments = []
  hand.each { |card| segments << card[:face_up].call }
  ['','','','','','',''].zip(*segments).each do |joined_segments| 
    puts joined_segments.inject { |a,b| a+b }
  end  
end

def display_hand_hidden(hand)
  system 'clear'
  puts "Dealer's cards:"
  segments = []
  segments << hand[0][:face_down].call
  hand[1..-1].each { |card| segments << card[:face_up].call }
  ['','','','','','',''].zip(*segments).each do |joined_segments| 
    puts joined_segments.inject { |a,b| a+b }
  end  
end

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

def get_card_by_name(name)
  deck.select { |card| card[:name] == name }.first
end

def deal(deck, hand, number_to_deal)
  number_to_deal.times do
    card = deck.shift
    hand << card
  end
end

def reset_hand(hand)
  hand.clear
end

# def display_new_game(deck, dealer_hand, player_hand)
#   reset_hand(dealer_hand); reset_hand(player_hand)
#   deal(deck, dealer_hand, 2); deal(deck, player_hand, 2)
#   display_hand_hidden(dealer_hand); display_hand(player_hand)
#   p points(player_hand)
# end

# def display_game(deck, dealer_hand, player_hand)
#   deal(deck, dealer_hand, 2); deal(deck, player_hand, 2)
#   display_hand_hidden(dealer_hand); display_hand(player_hand)
#   p points(player_hand)
# end

def game_state
  {
    decks: [],
    player_name: '',    
    dealer_bank: 0,
    player_bank: 0,
    bet: 0,
    points: 0,
    player_hand_1: [],
    player_hand_2: [],
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
    puts "\nHow much money are you putting into play? (Max $1,000)"
    total_funds = gets.chomp.to_i 
  end while total_funds <= 0 || total_funds > 1000
  game_state[:player_bank] = total_funds
end

# This is in case player wants to choose number of decks in shoe
# def decks(game_state)
#   begin
#     puts "\nHow many decks do you want to mix together? (Min 1; Max 8)"
#     number_of_decks = gets.chomp.to_i
#   end while !(1..8).include?(number_of_decks) 
#   decks = []
#   number_of_decks.times { decks += deck }
#   game_state[:decks] = lambda { decks }
# end

def initial_state_of_game
  system 'clear'
  puts "Welcome to the table!"
  puts "Blackjack pays 3 to 2."
  puts "Dealer must draw on 16 and stand on all 17's."
  puts "\n"
  state = game_state
  player_name(state)
  player_bank(state)
  state[:dealer_bank] = 50000
  state[:decks] = lambda { deck }
  state
end

def bet(game_state) 
  system 'clear'
  begin
    puts "You have #{game_state[:player_bank]} dollars left."
    puts "What is your bet for this hand?"
    bet = gets.chomp.to_i
  end while bet <= 0 || bet > game_state[:player_bank]
  game_state[:bet] = bet
end

def first_deal(game_state)
  2.times do
    card = game_state[:decks].call.shift
    game_state[:player_hand_1] << card
    card = game_state[:decks].call.shift
    game_state[:dealer_hand] << card
  end
end

def hit_or_stay
  begin
    puts "\n\nWhat do you wish to do?"
    puts "\n(h to HIT, s to STAY)"
    action = gets.chomp.downcase
  end while !['h','s'].include?(action) 
  puts "\nYou have chosen to HIT!" if action == 'h'
  puts "\nYou have decided to STAY." if action == 's'
end
    




state = initial_state_of_game
bet(state)
first_deal(state)
display_hand_hidden(state[:dealer_hand])
display_hand(state[:player_hand_1])
hit_or_stay

binding.pry
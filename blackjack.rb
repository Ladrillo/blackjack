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

def display_player_hand(array_of_cards)
  segments = []
  array_of_cards.each { |card| segments << card[:face_up].call }
  ['','','','','','',''].zip(*segments).each do |joined_segments| 
    puts joined_segments.inject { |a,b| a+b }
  end  
end

def display_dealer_hand(array_of_cards)
  segments = []
  segments << array_of_cards[0][:face_down].call
  array_of_cards[1..-1].each { |card| segments << card[:face_up].call }
  ['','','','','','',''].zip(*segments).each do |joined_segments| 
    puts joined_segments.inject { |a,b| a+b }
  end  
end

def player_hand
  []
end

def dealer_hand
  []
end

d = deck

hand = [deck[0], deck[1], deck[2]]

display_dealer_hand(hand)

# binding.pry
# encoding: UTF-8
require 'pry'

def suits
	['Hearts', 'Diamonds', 'Clubs', 'Spades']
end

def ranks
	['Ace', 'King', 'Queen', 'Jack', '10', '9', '8', '7', '6', '5', '4', '3', '2']
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

def visual(suit, rank)
	visual = lambda do
		puts ' ________'
		puts '|' + "".center(8) +'|'	 					
		puts '|' + "#{rank}".center(8) + '|'
		puts '|' + "".center(8) +'|'
		puts '|' + "#{suit}".center(8) + '|'       
		puts '|________|' 
	end
end

def deck
	deck = []
	suits.each do |suit| 
		ranks.each do |rank|
		 deck << {name:"#{rank} of #{suit}", suit:"#{suit}", rank:"#{rank}", 
		 	value:value("#{rank}"), visual:visual("#{suit}", "#{rank}")}
		end
	end
	deck
end

binding.pry
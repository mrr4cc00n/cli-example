require 'httparty'
require 'json'
require 'thor'

class Card < Thor

  desc 'ruby card.rb request_cards','request a set of cards to the magic the gathering API'
  def request_cards
    cards = JSON.parse(HTTParty.get('https://api.magicthegathering.io/v1/cards').body)['cards']
    pp cards
    cards
  end

  desc "ruby card.rb filter_by --fields setName:'Tenth Edition' colors:White,Blue",
       'filter the result by the specified hash --fields{}'
  method_option :fields, :type => :hash, :required => true
  def filter_by
    fields = options[:fields] || {}
    result = request_cards.select do |card|
      apply_filters(fields: fields.keys, values: fields.values, card: card)
    end
    pp result
    result
  end

  desc 'ruby card.rb group_by --fields colors rarity',
       'group the result by the specified values on --fields[]'
  method_option :fields, :type => :array, :required => true
  def group_by
    fields = options[:fields] || []
    cards = request_cards
    fields.each do |f|
      cards = group(elements: cards, field: f)
    end
    pp cards
    cards
  end

  private

  def group(elements:, field:)
    if elements.is_a? Hash
      elements.each do |k, v|
        elements[k] = group(elements: v, field: field)
      end
    else
      elements.group_by{ |e| e[field] }
    end
  end

  def apply_filters(fields:, values:, card:)
    pass_filters = true
    fields.each_with_index do |f, i|
      pass_filters = case card[f]
                     when Array
                       pass_filters && filter_array?(elements: card[f], values: values[i].split(','))
                     else
                       pass_filters && card[f] == values[i]
                     end
    end
    pass_filters
  end

  def filter_array?(elements:, values:)
    values.each do |e|
      return false unless elements.include? e
    end
    true
  end
end


Card.start(ARGV)

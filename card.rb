require 'httparty'
require 'json'

class Card
  def request_cards
    JSON.parse(HTTParty.get('https://api.magicthegathering.io/v1/cards').body,
               symbolize_names: true)[:cards]
  end

  def filter_by(fields: [:setName, :colors], values: [])
    request_cards.select do |card|
      apply_filters(fields: fields, values: values, card: card)
    end
  end

  def group_by(fields:, cards:)
    fields.each do |f|
      cards = group(elements: cards, field: f)
    end
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
                       pass_filters && filter_array?(elements: card[f], values: values[i])
                     when Hash
                       pass_filters && filter_hash?(elements_hash: card[f], values: values[i])
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

  def filter_hash?(elements_hash:, values:)
    values.each do |k, v|
      return false unless elements_hash[k] == v
    end
    true
  end
end

c = Card.new
# c.request_cards.each do |e|
#   p e[:id]
#   p e[:setName]
# end
# c.filter_by(values: ['Tenth Edition', ['White']]).each do |e|
#   p e[:id]
#   p e[:setName]
#   p e[:colors]
# end
pp c.group_by(fields: [:colors, :rarity], cards: c.request_cards)
# p c.filter_by(values: ['Tenth Edition', ['White']]).size

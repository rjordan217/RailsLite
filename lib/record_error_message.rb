require 'active_support/inflector'

class RecordErrorMessage
  attr_accessor :messages

  def initialize(messages = {})
    @messages = messages
  end

  def full_messages
    @messages.map { |k,v| "#{k.to_s.titleize} #{v.join(" and ")}" }
  end

  def [](key)
    @messages[key] ||= []
    @messages[key]
  end

  def []=(key,val)
    @messages[key] = val
  end
end

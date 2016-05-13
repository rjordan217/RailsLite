require 'active_support/inflector'

class RecordErrors
  attr_accessor :messages

  def initialize(messages = {})
    @messages = messages
  end

  def full_messages
    message_array = []
    @messages.each do |k,v|
      message_array << "#{k.to_s.classify} #{v}"
    end
    message_array
  end

  def [](key)
    @messages[key]
  end
end

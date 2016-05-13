require_relative 'db_connection'
require_relative 'record_errors'

module Validatable
  include Hooks

  define_hook :before_save

  def before_save
    @callbacks.each do |callback|
      callback.call(self)
    end
    errors
  end

  def self.validates(*attrs, options = {})
    # RecordErrors.new
    options.each do |key, val|
      normalized_opts = _normalize_options(val)
      case key
      when :presence
        validate_presence(attrs,val)
      when :inclusion
        validate_inclusion(attrs,normalized_opts)
      when :length
        validate_length(attrs,normalized_opts)
      when :uniqueness
        validate_uniqueness(attrs,normalized_opts)
      end
    end
  end

  def self.validates_presence_of

  end

  def validate_presence(attrs, val)
    attrs.each do |attr|
      errors << "#{attr} cannot be blank" unless self.send(attr)
    end
  end

# TODO: Make these RecordErrors
  def errors
    @errors ||= []
  end

  def errors=(errs)
    @errors = errs if errs.is_a?(Array)
  end

  private
  def _normalize_options(possible_hash)
    unless possible_hash.is_a?(Hash)
      {direct_validation: possible_hash}
    else
      possible_hash
    end
  end
end

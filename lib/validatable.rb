require_relative 'db_connection'
require_relative 'record_error_message'

module Validatable
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.send(:before_save, :run_validation_cbs)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def validates(*attrs, options)
      options.each do |key, val|
        callbacks << case key
        when :presence
          Proc.new { |this| this.validate_presence(attrs,val) }
        when :absence
          Proc.new { |this| this.validate_absence(attrs, val) }
        when :inclusion
          Proc.new { |this| this.validate_inclusion(attrs,val) }
        when :length
          Proc.new { |this| this.validate_length(attrs,val) }
        when :uniqueness
          Proc.new { |this| this.validate_uniqueness(attrs,val) }
        end
      end
    end

    def callbacks
      @callbacks ||= []
    end
  end

  module InstanceMethods
    def validate_inclusion(attrs, opts)
      container = opts[:in]
      message = opts[:message] || "must be in #{container}"
      attrs.each do |atr|
        errors[atr] << message unless container.include?(self.send(atr))
      end
    end

    def validate_length(attrs, opts)
      if opts[:minimum]
        verify_min = Proc.new {|atr| self.send(atr).length >= opts[:minimum]}
      else
        verify_min = Proc.new { true }
      end
      if opts[:maximum]
        verify_max = Proc.new {|atr| self.send(atr).length <= opts[:maximum]}
      else
        verify_max = Proc.new { true }
      end
      if opts[:is]
        verify_is = Proc.new {|atr| self.send(atr).length == opts[:is]}
      else
        verify_is = Proc.new { true }
      end
      attrs.each do |atr|
        errors[atr] << "must be at least #{opts[:minimum]} long" unless verify_min.call(atr)
        errors[atr] << "must be less than #{opts[:maximum]} long" unless verify_max.call(atr)
        errors[atr] << "must be #{opts[:is]} long" unless verify_is.call(atr)
      end
    end

    def validate_uniqueness(attrs, opts)
      attrs.each do |atr|
        errors[atr] << "must be at least #{opts[:minimum]} long" unless verify_min.call(atr)
      end
    end

    def validate_presence(attrs, val)
      if val
        attrs.each do |atr|
          errors[atr] << "cannot be blank" unless self.send(atr)
        end
      else
        validate_absence(attrs, true)
      end
    end

    def validate_absence(attrs, val)
      if val
        attrs.each do |atr|
          errors[atr] << "must be blank" if self.send(atr)
        end
      else
        validate_presence(attrs, true)
      end
    end

    def run_validation_cbs
      self.class.callbacks.each do |callback|
        callback.call(self)
      end
      errors
    end

    def errors
      @errors ||= RecordErrorMessage.new
    end

    def errors=(errs)
      @errors = errs
    end
  end


# TODO: add in validation; needs schema; validate_uniqueness
  # def self.validates_presence_of
  #
  # end
end

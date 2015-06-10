module ActiveRecordFlagSupport
  # ----------------------------------------------------------------- included
  def self.included(base)
    base.extend(ClassMethods)
  end
  module ClassMethods
    # ------------------------------------------------------ define_flag_methods
    def define_flag_methods( field, method_hash = nil ) 
      if method_hash.nil?
        method_hash = field
        field = :flags
      end
      unless method_hash.is_a?( Hash )
        col = 1
        method_hash = method_hash.inject( {} ) do |m,x|
          m[x] = col
          col *= 2
          m
        end
      end

      method_hash.each_pair do |key,value|
        class_eval( "def #{key}\n return ( #{field} & #{value} ) == #{value}; end" )
        class_eval( "def #{key}=(v)\n old_value = #{key}; set_flag( :#{field}, v, #{value} ); if old_value != #{key}\n@#{key}_was_changed = true;\nend\n end" )
        class_eval( "def #{key}_changed?\n new_record? || @#{key}_was_changed\n end" )
        class_eval( "def #{key}?\n return ( #{field} & #{value} ) == #{value}; end" )
        class_eval( "def update_#{key}(v)\n set_flag( :#{field}, v, #{value} ); update_attribute( :#{field}, self.#{field} ); end" )
        konst = "%s_MASK" % key.upcase
        unless const_defined?( konst )
          const_set( konst, value )
        end
      end
      cattr_accessor "#{field}_flag_hash"
      class_variable_set( "@@#{field}_flag_hash", method_hash )
      unless method_defined?( :set_flag )
        class_eval("include ActiveRecordFlagSupport::FlagInstanceMethods")
      end
    end
  end
  module FlagInstanceMethods
    if ActiveRecord::ConnectionAdapters::Column.respond_to?( :value_to_boolean )
      # ------------------------------------------------------------------- set_flag
      def set_flag( field, value, bit_field )
        value = if value && ActiveRecord::ConnectionAdapters::Column.value_to_boolean( value )
          ( send(field).to_i | bit_field ) 
        else
          ( send(field).to_i & (~bit_field) ) 
        end
        self.send( "#{field}=", value )
        attributes_before_type_cast[field] = value
      end
    else
      # ------------------------------------------------------------------- set_flag
      def set_flag( field, value, bit_field )
        value = if value && ActiveRecord::Type::Boolean.new.send( :cast_value, value )
          ( send(field).to_i | bit_field ) 
        else
          ( send(field).to_i & (~bit_field) ) 
        end
        self.send( "#{field}=", value )
        attributes_before_type_cast[field] = value
      end
    end
  end
end
require 'active_record'
ActiveRecord::Base.send( :include, ActiveRecordFlagSupport )

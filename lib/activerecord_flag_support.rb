#
module ActiveRecordFlagSupport
  # ----------------------------------------------------------------- included
  def self.included(base)
    base.extend(ClassMethods)
  end

  #
  module ClassMethods
    # ------------------------------------------------------ define_flag_methods
    def define_flag_methods(field, method_hash = nil)
      if method_hash.nil?
        method_hash = field
        field = :flags
      end
      unless method_hash.is_a?(Hash)
        method_hash = method_hash_from_array(method_hash)
      end
      method_hash.each_pair do |key, value|
        define_methods_for_flag(key, value, field)
        add_flag_const(key, value)
      end
      setup_flag_class(field, method_hash)
    end

    ############################################################################

    private

    ############################################################################

    # ------------------------------------------------------ define_flag_methods
    def define_methods_for_flag(key, value, field)
      class_eval("def #{key}\n return (#{field} & #{value}) == #{value}; end",
                 __FILE__, __LINE__)
      class_eval("def #{key}=(v)\n old_value = #{key}; set_flag(:#{field}, "\
                 "v, #{value}); if old_value != #{key}\n@#{key}_was_changed="\
                 "true;\nend\n end", __FILE__, __LINE__)
      class_eval('attr_reader :{key}_was_changed', __FILE__, __LINE__)
      class_eval("def #{key}_changed?\n new_record? || #{key}_was_changed\n "\
                 'end', __FILE__, __LINE__)
      class_eval("def #{key}?\n return (#{field} & #{value}) == #{value}; "\
                 'end', __FILE__, __LINE__)
      class_eval("def update_#{key}(v)\n set_flag(:#{field}, v, #{value}); "\
                 "update_attribute(:#{field}, self.#{field}); end", __FILE__,
                 __LINE__)
    end

    # --------------------------------------------------------- setup_flag_class
    def setup_flag_class
      cattr_accessor "#{field}_flag_hash"
      class_variable_set("@@#{field}_flag_hash", method_hash)
      return if method_defined?(:set_flag)
      class_eval('include ActiveRecordFlagSupport::FlagInstanceMethods')
    end

    # ----------------------------------------------------------- add_flag_const
    def add_flag_const(key, value)
      konst = format('%s_MASK', key.upcase)
      const_set(konst, value) unless const_defined?(konst)
    end

    # --------------------------------------------------- method_hash_from_array
    def method_hash_from_array
      col = 1
      method_hash.each_with_object({}) do |x, m|
        m[x] = col
        col *= 2
      end
    end
  end

  #
  module FlagInstanceMethods
    if ActiveRecord::ConnectionAdapters::Column.respond_to?(:value_to_boolean)
      # --------------------------------------------------------------- set_flag
      def set_flag(field, value, bit_field)
        is_true = value &&
                  ActiveRecord::ConnectionAdapters::Column.value_to_boolean(value)
        value = if is_true
                  (send(field).to_i | bit_field)
                else
                  (send(field).to_i & ~bit_field)
                end
        send("#{field}=", value)
        attributes_before_type_cast[field] = value
      end
    else
      # --------------------------------------------------------------- set_flag
      def set_flag(field, value, bit_field)
        is_true = value && ActiveRecord::Type::Boolean.new.send(:cast_value,
                                                                value)
        value = if is_true
                  (send(field).to_i | bit_field)
                else
                  (send(field).to_i & ~bit_field)
                end
        send("#{field}=", value)
        attributes_before_type_cast[field] = value
      end
    end
  end
end
require 'active_record'
ActiveRecord::Base.send(:include, ActiveRecordFlagSupport)

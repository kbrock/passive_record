require 'ostruct'

require 'active_support'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/numeric/time'

require 'passive_record/version'

require 'passive_record/arithmetic_helpers'
require 'passive_record/core/query'

require 'passive_record/class_inheritable_attrs'

require 'passive_record/associations'
require 'passive_record/hooks'

require 'passive_record/pretty_printing'

require 'passive_record/instance_methods'
require 'passive_record/class_methods'

module PassiveRecord
  def self.included(base)
    base.send :include, InstanceMethods
    base.send :include, ClassLevelInheritableAttributes
    base.send :include, PrettyPrinting

    base.class_eval do
      inheritable_attrs :hooks, :associations
    end

    base.extend(ClassMethods)

    model_classes << base
  end

  def self.model_classes
    @model_classes ||= []
  end

  def self.drop_all
    (model_classes + model_classes.flat_map(&:descendants)).uniq.each(&:destroy_all)
  end
end

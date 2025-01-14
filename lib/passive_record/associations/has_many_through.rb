module PassiveRecord
  module Associations
    class HasManyThroughAssociation < Struct.new(:parent_class, :child_class_name, :target_name_symbol, :through_class, :base_association)
      def to_relation(parent_model)
        HasManyThroughRelation.new(self, parent_model)
      end
    end

    class HasManyThroughRelation < HasManyRelation
      def <<(child)
        if nested_association.is_a?(HasManyAssociation)
          intermediary_id =
            child.send(association.base_association.target_name_symbol.to_s.singularize + "_id")

          if intermediary_id
            intermediary_relation.child_class.find(intermediary_id).
              send(:"#{parent_model_id_field}=", parent_model.id)
          else
            nested_ids_field = nested_association.children_name_sym.to_s.singularize + "_ids"
            intermediary_model = intermediary_relation.singular? ?
                intermediary_relation.lookup_or_create :
                intermediary_relation.where(parent_model_id_field => parent_model.id).first_or_create

            intermediary_model.update(
                nested_ids_field => intermediary_model.send(nested_ids_field) + [ child.id ]
              )
          end
        else
          intermediary_model = intermediary_relation.
            where(
              association.target_name_symbol.to_s.singularize + "_id" => child.id).
              first_or_create
        end
        self
      end

      def create(attrs={})
        child = child_class.create(attrs)
        send(:<<, child)
        child
      end

      def nested_class
        module_name = association.parent_class.name.deconstantize
        module_name = "Object" if module_name.empty?
        (module_name.constantize).
          const_get("#{association.base_association.child_class_name.singularize}")
      end

      def nested_association
        nested_class.associations.detect { |assn|
          assn.child_class_name == association.child_class_name ||
          assn.child_class_name == association.child_class_name.singularize ||

          (assn.parent_class_name == association.child_class_name rescue false) ||
          (assn.parent_class_name == association.child_class_name.singularize rescue false) ||

          assn.target_name_symbol == association.target_name_symbol.to_s.singularize.to_sym
        }
      end

      def all
        join_results = intermediate_results
        if intermediate_results && !join_results.empty?
          final_results = join_results.flat_map(&nested_association.target_name_symbol)
          if final_results.first.is_a?(Associations::Relation)
            final_results.flat_map(&:all)
          else
            Array(final_results)
          end
        else
          []
        end
      end

      def intermediary_relation
        @intermediary_relation ||= association.base_association.to_relation(parent_model)
      end

      def intermediate_results
        if intermediary_relation.singular?
          Array(intermediary_relation.lookup)
        else
          intermediary_relation.all
        end
      end
    end
  end
end

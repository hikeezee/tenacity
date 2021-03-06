module Tenacity
  module OrmExt
    # Tenacity relationships on ActiveRecord objects require that certain columns
    # exist on the associated table. Take the following class for example:
    #
    #   class Car < ActiveRecord::Base
    #     include Tenacity
    #
    #     t_has_many    :wheels
    #     t_has_one     :dashboard
    #     t_belongs_to  :driver
    #   end
    #
    #
    # == t_belongs_to
    #
    # The +t_belongs_to+ association requires that a property exist in the table
    # to hold the id of the assoicated object.
    #
    #   create_table :cars do |t|
    #     t.string :driver_id
    #   end
    #
    #
    # == t_has_one
    #
    # The +t_has_one+ association requires no special column in the table, since
    # the associated object holds the foreign key.
    #
    #
    # == t_has_many
    #
    # The +t_has_many+ association requires nothing special, as the associates
    # are looked up using the associate class.
    #
    module ActiveRecord

      def self.setup(model)
        require 'active_record'
        if model.ancestors.include?(::ActiveRecord::Base)
          model.send :include, ActiveRecord::InstanceMethods
          model.extend ActiveRecord::ClassMethods
        end
      rescue LoadError
        # ActiveRecord not available
      end

      module ClassMethods #:nodoc:
        include Tenacity::OrmExt::Helpers

        def _t_id_type
          @_t_id_type_clazz ||= begin
                                  Kernel.const_get(columns.find{ |x| x.primary }.type.to_s.capitalize)
                                rescue
                                  Integer
                                end
        end

        def _t_find(id)
          find_by(id: _t_serialize(id))
        end

        def _t_find_bulk(ids)
          return [] if ids.nil? || ids.empty?
          where("id in (?)", _t_serialize_ids(ids)).to_a

        end

        def _t_find_first_by_associate(property, id)
          where("#{property} = ?", _t_serialize(id)).first
        end

        def _t_find_all_by_associate(property, id)
          where("#{property} = ?", _t_serialize(id)).to_a
        end

        def _t_find_all_ids_by_associate(property, id)
          connection.select_values("SELECT id FROM #{table_name} WHERE #{property} = #{_t_serialize_id_for_sql(id)}")
        end

        def _t_initialize_has_one_association(association)
          before_destroy { |record| record._t_cleanup_has_one_association(association) }
        end

        def _t_initialize_tenacity
          before_save { |record| record._t_verify_associates_exist }
          after_save { |record| record._t_save_autosave_associations }
        end

        def _t_initialize_has_many_association(association)
          after_save { |record| record.class._t_save_associates(record, association) }
          before_destroy { |record| record._t_cleanup_has_many_association(association) }
        end

        def _t_initialize_belongs_to_association(association)
          after_destroy { |record| record._t_cleanup_belongs_to_association(association) }
        end

        def _t_delete(ids, run_callbacks=true)
          if run_callbacks
            destroy_all(["id in (?)", _t_serialize_ids(ids)])
          else
            delete_all(["id in (?)", _t_serialize_ids(ids)])
          end
        end
      end

      module InstanceMethods #:nodoc:
        include Tenacity::OrmExt::Helpers

        def _t_reload
          reload
          self
        end

        def _t_save_if_dirty(*args)
          changed? ? save(*args) : true
        end
      end

    end
  end
end

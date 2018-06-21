# frozen_string_literal: true

module SoftDeletable
  extend ActiveSupport::Concern

  included do
    # "Soft delete" - set deleted_at if it is nil, actually destroy the record
    # if forced.
    #
    # @param force [Boolean]
    def destroy(force = nil)
      return force_destroy_record if force == :force
      return self if deleted?
      soft_destroy_record
    end

    # Revive a soft-deleted record and associated records if soft-deleted,
    # otherwise return self
    def revive
      return self unless deleted?
      ActiveRecord::Base.transaction do
        update_attributes(deleted_at: nil)
        revive_associated_records
      end
    end

    # Whether or not a record is deleted
    def deleted?
      deleted_at.present?
    end

    private

    def force_destroy_record
      ActiveRecord::Base.transaction do
        destroy_associated_records(:force)
        method(:destroy).super_method.call
      end
    end

    def soft_destroy_record
      ActiveRecord::Base.transaction do
        destroy_associated_records
        update_attributes(deleted_at: Time.zone.now)
      end
    end

    def destroy_associated_records(force = nil)
      associated_records.each { |r| r.destroy(force) }
    end

    def revive_associated_records
      associated_records.each(&:revive)
    end

    # This should return an array of all associated records of an object that
    # should be soft deleted with it (i.e. those that have dependent: :destroy
    # set). In principle we could figure this out automatically but in the
    # interest of simplicity we'll just define it manually for each class.
    def associated_records
      raise NotImplementedError
    end
  end
end

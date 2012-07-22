module HistoryConcern
  extend ActiveSupport::Concern

  included do
    history_class_name = "#{name}History"

    after_create :create_history
    after_update :expire_current_history_and_create_new_one
    before_destroy :expire_current_history

    has_many :histories, :class_name => history_class_name

    class << history_class_name.constantize
      def at_date(date)
        where "valid_since <= :date && (:date < valid_to || valid_to is null)", date: date
      end
    end
  end

  def create_history
    history = histories.new
    attributes.each_pair do |att_name, att_value|
      unless ['id', 'created_at', 'updated_at'].include? att_name
        history[att_name] = att_value
      end
    end
    history["valid_since"] = updated_at
    history[self.class.name.foreign_key] = id
    history.save!
    history
  end

  def current_history
    histories.where(valid_to: nil).first
  end

  def expire_current_history_and_create_new_one
    expire_current_history
    create_history
  end

  def expire_current_history
    current_history.try :update_attributes!, valid_to: Time.now
  end
end

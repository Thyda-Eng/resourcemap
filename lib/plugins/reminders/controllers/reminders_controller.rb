class RemindersController < ApplicationController
  before_filter :authenticate_user!

  def index
    respond_to do |format|
      format.html do
        show_collection_breadcrumb
        add_breadcrumb "Reminders", collection_reminders_path(collection)
      end
      format.json { render json: reminders.all.as_json(include: [:repeat,:sites])}
    end
  end

  def create
    reminder = reminders.new params[:reminder].except(:sites)
    
    # site references
    reminder.sites = Site.find params[:reminder][:sites] if params[:reminder][:sites].present?
    
    reminder.save!
    render json: reminder
  end
  
  def update
    reminder = reminders.find params[:id]
    reminder.update_attributes! params[:reminder].except(:sites)
    
    # site references
    reminder.sites = params[:reminder][:sites].present? ? Site.find(params[:reminder][:sites]) : []
    
    render json: reminder
  end
  
  def destroy
    reminder.destroy

    render json: reminder
  end

end
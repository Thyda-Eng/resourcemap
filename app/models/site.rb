class Site < ActiveRecord::Base
  include Activity::AwareConcern
  include Site::ActivityConcern
  include Site::GeomConcern
  include Site::TireConcern

  belongs_to :collection

  serialize :properties, Hash
  before_create :assign_id_with_prefix
  before_save :strongly_type_properties
  def strongly_type_properties
    fields = collection.fields.index_by(&:es_code)
    self.properties.keys.each do |key|
      field = fields[key]
      self.properties[key] = properties[key].to_i_or_f if field && field.kind == 'numeric'
    end
  end

  before_save :remove_nil_properties, :if => :properties
  def remove_nil_properties
    self.properties.reject! { |k, v| v.nil? }
  end

  def update_properties(user, site)
  end

  def assign_id_with_prefix
      self.id_with_prefix = generate_id_with_prefix if self.id_with_prefix.nil? 
  end

  def generate_id_with_prefix
    sites = Site.find_by_collection_id(self.collection_id)
    if site.nil?
      #generate new id_with_prefix 
    
    else   
      #get last id_with_prefix and continue
    
    end
  end

  def 
end

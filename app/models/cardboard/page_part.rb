module Cardboard
  class PagePart < ActiveRecord::Base
    has_many :fields, :as => :object_with_field, class_name: "Cardboard::Field", :dependent => :destroy, :inverse_of => :object_with_field
    has_many :subparts, class_name: "Cardboard::PagePart", :dependent => :destroy, :foreign_key => "parent_part_id", :inverse_of => :parent

    belongs_to :parent, class_name: "Cardboard::PagePart",  :foreign_key => "parent_part_id", :inverse_of => :subparts
    belongs_to :page

    accepts_nested_attributes_for :subparts, :allow_destroy => true #, :reject_if => :all_blank
    accepts_nested_attributes_for :fields #, :allow_destroy => true (maybe for super admin?)

    validates :identifier, uniqueness: {:case_sensitive => false, :scope => :page_id}, 
                           :format => {:with => /\A[a-z\_0-9]+\z/, :message => "Only downcase letters, numbers and underscores are allowed"}, 
                           :unless => :subpart?
    validates_associated :fields
    # validates :subparts, presence:true, unless: -> {new_record? || subpart?}
    validate :at_least_one_subpart
    
    # Scopes
    scope :is_subparts, ->{ where("parent_part_id IS NOT NULL")}
    scope :is_parent, ->{where("parent_part_id IS NULL")}

    #gem
    include RankedModel
    ranks :subpart_position, :with_same => :parent_part_id, :column => :position, :scope => :is_subparts
    ranks :part_position, :with_same => :page_id, :column => :position, :scope => :is_parent
    default_scope {order("position ASC")}


    def subpart?
      !self.parent_part_id.nil?
    end

    def repeatable?
       @parent_repeatable ||= self.parent ? self.parent[:repeatable] : super
    end

    def new_subpart
      return nil if !repeatable? || subpart?
      master = self.subparts.first
      master_hash = master.attributes.select do |key, value|
        ["parent_part_id"].include? key
      end
      subpart = Cardboard::PagePart.new(master_hash)
      for field in master.fields
        field_hash = field.attributes.select do |key, value|
          ["identifier", "label", "type", "required", "hint", "placeholder"].include? key
        end 
        subpart.fields << Cardboard::Field.new(field_hash)
      end
      return subpart
    end

    def attr(field)
      field = field.to_s
      @attr ||= {}
      @attr[field] ||= begin
        f = self.fields.where(identifier: field).first
        return nil unless f
        out = f.value_uid.nil? ? nil : f.value
        out = f.default if f.required? && out.nil?
        out
      end
    end

  private

    def at_least_one_subpart
      return true if subpart? || new_record?
      # require a minimum of one task
      undestroyed_part_count = 0
   
      subparts.each { |t| undestroyed_part_count += 1 unless t.marked_for_destruction? }
      if undestroyed_part_count < 1
        errors.add(:base, 'There must be at least one') 
      end
    end
  end
end

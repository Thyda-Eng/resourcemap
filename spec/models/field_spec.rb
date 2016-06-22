require 'spec_helper'

describe Field do
  def history_concern_class
    Field::TextField
  end

  def history_concern_foreign_key
    'field_id'
  end

  def history_concern_histories
    'field_histories'
  end

  def history_concern_class_foreign_key
    'field_id'
  end


  it "sanitizes options" do
    field = Field::SelectOneField.make config: {options: [{code: 'foo', label: 'bar'}]}.with_indifferent_access
    expect(field.config.class).to eq(Hash)
    field.config['options'].each do |option|
      expect(option.class).to eq(Hash)
    end
  end

  it "sanitizes hierarchy" do
    field = Field::HierarchyField.make config: {hierarchy: [{sub: [{}.with_indifferent_access]}]}.with_indifferent_access
    expect(field.config.class).to eq(Hash)
    field.config['hierarchy'].each do |item|
      expect(item.class).to eq(Hash)
      expect(item['sub'].first.class).to eq(Hash)
    end
  end

  it 'should include kind in json' do
    field = Field::SelectOneField.make config: {options: [{code: 'foo', label: 'bar'}]}.with_indifferent_access
    json = JSON.parse field.to_json
    expect(json["kind"]).to eq('select_one')
  end

  describe "sample value" do
    it "for text are strings" do
      field = Field::TextField.make
      expect(field.sample_value).to be_an_instance_of String
      expect(field.sample_value.length).to be > 0
    end

    it "for numbers is a number" do
      field = Field::NumericField.make
      expect(field.sample_value).to be_a_kind_of Numeric
    end

    it "for dates is a date" do
      field = Field::DateField.make
      expect { field.parse_date(field.sample_value) }.to_not raise_error
    end

    it "for user is a string" do
      user = User.make email: 'an@email.com'
      field = Field::UserField.make
      expect(field.sample_value(user)).to eq(user.email)
    end

    it "for 'select one' is one of the choices" do
      config_options = [{id: 1, code: 'one', label: 'One'}, {id: 2, code: 'two', label: 'Two'}]
      field = Field::SelectOneField.make config: { options: config_options }.with_indifferent_access
      codes = config_options.map { |o| o[:code] }
      expect(codes).to include field.sample_value
    end

    it "for 'select many' are among the choices" do
      config_options = [{id: 1, code: 'one', label: 'One'}, {id: 2, code: 'two', label: 'Two'}, {id: 3, code: 'three', label: 'Three'}]
      field = Field::SelectManyField.make config: { options: config_options }.with_indifferent_access
      codes = config_options.map { |o| o[:code] }
      expect(field.sample_value.length).to be > 0
      field.sample_value.each do |option|
        expect(codes).to include option
      end
    end

    it "for hierarchy is a valid item" do
      config_hierarchy = [{ id: 0, name: 'root', sub: [{id: 1, name: 'child'}]}]
      field = Field::HierarchyField.make config: { hierarchy: config_hierarchy }.with_indifferent_access
      expect(['root', 'child']).to include field.sample_value
    end

    it "for email and phone is a string" do
      field = Field::EmailField.make
      expect(field.sample_value).to be_an_instance_of String

      field = Field::PhoneField.make
      expect(field.sample_value).to be_an_instance_of String
    end

    it "for fields with no config should be the empty string" do
      field = Field::SelectManyField.make config: {}
      expect(field.sample_value).to eq('')

      field = Field::SelectOneField.make config: {}
      expect(field.sample_value).to eq('')

      field = Field::HierarchyField.make config: {}
      expect(field.sample_value).to eq('')
    end
  end

  describe "cast strongly type" do
    let!(:config_options) { [{id: 1, code: 'one', label: 'One'}, {id: 2, code: 'two', label: 'Two'}] }

    describe "select_one" do
      let!(:field) { Field::SelectOneField.make config: {options: config_options} }

      it "should convert value" do
        expect(field.strongly_type('1')).to eq 1
      end
    end

    describe "select_many" do
      let!(:field) { Field::SelectManyField.make config: {options: config_options} }

      it "should convert value to integer" do
        expect(field.strongly_type('1')).to eq 1
        expect(field.strongly_type('2')).to eq 2
      end
    end

    describe 'yes_no' do
      let!(:field) { Field::YesNoField.make }

      it "should convert to 'true'" do
        expect(field.strongly_type('true')).to eq true
      end

      it "should convert to 'false'" do
        expect(field.strongly_type('false')).to eq false
        expect(field.strongly_type(nil)).to eq false
      end
    end

    describe 'date' do
      let!(:field) { Field::DateField.make }

      it "should convert nil" do
        expect(field.strongly_type(nil)).to eq nil
      end
    end
  end

  it "should have kind 'user'" do
    expect(Field::UserField.make).to be_valid
  end

  it "should have kind 'email'" do
    expect(Field::EmailField.make).to be_valid
  end

  describe "generate hierarchy options" do
    it "for empty hierarchy" do
      config_hierarchy = []
      field = Field::HierarchyField.make config: { hierarchy: config_hierarchy }.with_indifferent_access
      expect(field.hierarchy_options).to eq([])
    end

    it "for hierarchy with one level" do
      config_hierarchy = [{ id: 0, name: 'root', sub: [{id: 1, name: 'child'}]}]
      field = Field::HierarchyField.make config: { hierarchy: config_hierarchy }.with_indifferent_access
      expect(field.hierarchy_options).to eq([{:id=>0, :name=>"root"}, {:id=>1, :name=>"child"}])
    end

    it "for hierarchy with one level two childs" do
      config_hierarchy = [{ id: 0, name: 'root', sub: [{id: 1, name: 'child'}, {id: 2, name: 'child2'}]}]
      field = Field::HierarchyField.make config: { hierarchy: config_hierarchy }.with_indifferent_access
      expect(field.hierarchy_options).to eq([{:id=>0, :name=>"root"}, {:id=>1, :name=>"child"}, {:id=>2, :name=>"child2"}])
    end
  end

  describe "validations" do
    let!(:user) { User.make }
    let!(:collection) { user.create_collection Collection.make_unsaved }
    let!(:layer) { collection.layers.make }
    let!(:text) { layer.text_fields.make :code => 'text' }
    let!(:numeric) { layer.numeric_fields.make :code => 'numeric', :config => {} }
    let!(:yes_no) { layer.yes_no_fields.make :code => 'yes_no'}

    let!(:numeric_with_decimals) {
      layer.numeric_fields.make :code => 'numeric_with_decimals', :config => {
        :allows_decimals => "true" }.with_indifferent_access
      }

    let!(:select_one) { layer.select_one_fields.make :code => 'select_one', :config => {'next_id' => 3, 'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]} }

    let!(:select_many) { layer.select_many_fields.make :code => 'select_many', :config => {'next_id' => 3, 'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]} }

    config_hierarchy = [{ id: '60', name: 'Dad', sub: [{id: '100', name: 'Son'}, {id: '101', name: 'Bro'}]}]
    let!(:hierarchy) { layer.hierarchy_fields.make :code => 'hierarchy', config: { hierarchy: config_hierarchy }.with_indifferent_access }
    let!(:site_field) { layer.site_fields.make :code => 'site'}
    let!(:date) { layer.date_fields.make :code => 'date' }
    let!(:director) { layer.user_fields.make :code => 'user' }
    let!(:email_field) { layer.email_fields.make :code => 'email' }

    let!(:site) {collection.sites.make name: 'Foo old', id: 1234, properties: {} }

    let!(:collection) { user.create_collection Collection.make_unsaved }

    ['name', 'code'].each do |parameter|
      it "should validate uniqueness of #{parameter} in collection" do
        beds = collection.text_fields.make parameter.to_sym => 'beds'
        beds2 = collection.text_fields.make_unsaved parameter.to_sym => 'beds'

        expect(beds2).not_to be_valid

        collection2 = Collection.make

        beds3 = collection2.text_fields.make_unsaved parameter.to_sym => 'beds'
        expect(beds3).to be_valid
      end
    end

    describe "validations for each field" do

      it { expect(numeric.valid_value?(1)).to be_truthy }
      it { expect(numeric.valid_value?("1")).to be_truthy }

      it { expect(numeric_with_decimals.valid_value?(1.5)).to be_truthy }
      it { expect(numeric_with_decimals.valid_value?("1.5")).to be_truthy }

      it { expect(yes_no.valid_value?(true)).to be_truthy }
      it { expect(yes_no.valid_value?(false)).to be_truthy }

      it { expect(date.valid_value?("2012-11-27T00:00:00Z")).to be_truthy }

      it { expect(hierarchy.valid_value?("101")).to be_truthy }

      it { expect(select_many.valid_value?([1,2])).to be_truthy }
      it { expect(select_many.valid_value?(["1","2"])).to be_truthy }

      it { expect(select_one.valid_value?(1)).to be_truthy }
      it { expect(select_one.valid_value?("1")).to be_truthy }

      it { expect(site_field.valid_value?(1234)).to be_truthy }
      it { expect(site_field.valid_value?("1234")).to be_truthy }

      it { expect(director.valid_value?(user.email)).to be_truthy }

      it { expect(email_field.valid_value?("myemail@resourcemap.com")).to be_truthy }
    end

    describe "decode from ImportWizard format" do

      it { expect(numeric.decode(1)).to eq(1) }
      it { expect(numeric.decode("1")).to eq(1) }

      it { expect(numeric_with_decimals.decode("1.5")).to eq(1.5) }

      it { expect(yes_no.decode("true")).to eq(true) }

      it { expect(date.decode("12/26/1988")).to eq("1988-12-26T00:00:00Z") }

      it { expect(hierarchy.decode("Dad")).to eq("60") }

      it { expect(select_one.decode("one")).to eq(1) }
      it { expect(select_one.decode("One")).to eq(1) }

      it { expect(select_many.decode("one")).to eq([1]) }
      it { expect(select_many.decode("One")).to eq([1]) }
      it { expect(select_many.decode(['one', 'two'])).to eq([1, 2]) }
      it { expect(select_many.decode("one,two")).to eq([1, 2]) }

    end

    # TODO: Delete apply_format_and_validate method and use it's content instead with the corresponding decode
    # decode_fred or decode (for import_wizard)
    describe "apply_format_and_validate" do

      it "should validate format for numeric field" do
        expect(numeric.apply_format_and_validate(2, false, collection)).to be(2)
        expect(numeric.apply_format_and_validate("2", false, collection)).to be(2)
        expect { numeric.apply_format_and_validate("invalid23", false, collection) }.to raise_error(RuntimeError, "Invalid numeric value in field numeric. This numeric field is configured not to allow decimal values.")
      end

      it "should validate format for yes_no field" do
        expect(yes_no.apply_format_and_validate(true, false, collection)).to be_truthy
        expect(yes_no.apply_format_and_validate(1, false, collection)).to be_truthy
        expect(yes_no.apply_format_and_validate("true", false, collection)).to be_truthy
        expect(yes_no.apply_format_and_validate("yes", false, collection)).to be_truthy
        expect(yes_no.apply_format_and_validate("1", false, collection)).to be_truthy
        expect(yes_no.apply_format_and_validate(0, false, collection)).to be_falsey
        expect(yes_no.apply_format_and_validate("0", false, collection)).to be_falsey
        expect(yes_no.apply_format_and_validate("false", false, collection)).to be_falsey
      end

      it "should not allow decimals" do
        expect { numeric.apply_format_and_validate("2.3", false, collection) }.to raise_error(RuntimeError, "Invalid numeric value in field #{numeric.code}. This numeric field is configured not to allow decimal values.")
        expect { numeric.apply_format_and_validate(2.3, false, collection) }.to raise_error(RuntimeError, "Invalid numeric value in field #{numeric.code}. This numeric field is configured not to allow decimal values.")
      end

      it "should allow decimals" do
        expect(numeric_with_decimals.apply_format_and_validate("2.3", false, collection)).to eq(2.3)
        expect(numeric_with_decimals.apply_format_and_validate(2.3, false, collection)).to eq(2.3)
      end

      it "should validate format for date field" do
        expect(date.apply_format_and_validate("11/27/2012",false, collection)).to eq("2012-11-27T00:00:00Z")
        expect { date.apply_format_and_validate("27/10/1298", false, collection) }.to raise_error(RuntimeError, "Invalid date value in field #{date.code}")
        expect { date.apply_format_and_validate("11/27", false, collection) }.to raise_error(RuntimeError, "Invalid date value in field #{date.code}")
        expect { date.apply_format_and_validate("invalid", false, collection) }.to raise_error(RuntimeError, "Invalid date value in field #{date.code}")
      end

      it "should validate format for hierarchy field" do
        expect(hierarchy.apply_format_and_validate("Dad", false, collection)).to eq("60")
        expect { hierarchy.apply_format_and_validate("invalid", false, collection) }.to raise_error(RuntimeError, "Invalid hierarchy option in field #{hierarchy.code}")
      end

      it "should validate format for select_one field" do
        expect(select_one.apply_format_and_validate("one", false, collection)).to eq(1)
        expect(select_one.apply_format_and_validate("One", false, collection)).to eq(1)
        expect { select_one.apply_format_and_validate("invalid", false, collection) }.to raise_error(RuntimeError, "Invalid option in field #{select_one.code}")
      end

      it "should validate format for select_many field" do
        expect(select_many.apply_format_and_validate(["two", "one"], false, collection)).to eq([2, 1])
        expect { select_many.apply_format_and_validate(["two","inv"], false, collection) }.to raise_error(RuntimeError, "Invalid option 'inv' in field #{select_many.code}")
        expect { select_many.apply_format_and_validate("invalid", false, collection) }.to raise_error(RuntimeError, "Invalid option 'invalid' in field #{select_many.code}")
      end

      it "should validate format for site field" do
        expect(site_field.apply_format_and_validate(1234, false, collection)).to eq(1234)
        expect(site_field.apply_format_and_validate("1234", false, collection)).to eq("1234")
        expect { site_field.apply_format_and_validate(124, false, collection) }.to raise_error(RuntimeError, "Non-existent site-id in field #{site_field.code}")
        expect { site_field.apply_format_and_validate("124inv", false, collection) }.to raise_error(RuntimeError, "Non-existent site-id in field #{site_field.code}")
      end

      it "should validate format for user field" do
        expect(director.apply_format_and_validate(user.email, false, collection)).to eq(user.email)
        expect { director.apply_format_and_validate("inexisting@email.com", false, collection) }.to raise_error(RuntimeError, "Non-existent user email address in field #{director.code}")
      end

      it "should validate format for email field" do
        expect(email_field.apply_format_and_validate("valid@email.com", false, collection)).to eq("valid@email.com")
        expect { email_field.apply_format_and_validate("s@@email.c.om", false, collection) }.to raise_error(RuntimeError, "Invalid email address in field #{email_field.code}")
      end
    end
  end

  describe "dbf_field" do
    let(:user) { User.make }
    let(:collection) { user.create_collection Collection.make_unsaved }
    let(:layer) { collection.layers.make }
    let(:field) { layer.yes_no_fields.make :code => 'yes_no'}

    it "should convert to C dbf field" do
      expect(field.to_dbf_field.type).to eq('C')
    end

    context "numeric field" do
      let(:field) { layer.numeric_fields.make :code => 'numeric', :config => {} }

      it "should convert to N dbf field" do
        expect(field.to_dbf_field.type).to eq('N')
      end

      context "with decimal value allowed" do
        let(:field) { layer.numeric_fields.make :code => 'numeric', :config => {allows_decimals: "true"} }

        it "should convert to N dbf field with decimal" do
          dbf_field = field.to_dbf_field

          expect(dbf_field.type).to eq('N')
          expect(dbf_field.decimal).to be > 0
        end
      end
    end
  end

  describe 'telemetry' do
    let!(:collection) { Collection.make }
    let!(:layer) { Layer.make collection: collection }

    it 'should touch collection lifespan on create' do
      field = Field::NumericField.make_unsaved collection: collection, layer: layer

      expect(Telemetry::Lifespan).to receive(:touch_collection).with(collection)

      field.save
    end

    it 'should touch collection lifespan on update' do
      field = Field::NumericField.make collection: collection, layer: layer
      field.touch

      expect(Telemetry::Lifespan).to receive(:touch_collection).with(collection)

      field.save
    end

    it 'should touch collection lifespan on destroy' do
      field = Field::NumericField.make collection: collection, layer: layer

      expect(Telemetry::Lifespan).to receive(:touch_collection).with(collection)

      field.destroy
    end
  end
end

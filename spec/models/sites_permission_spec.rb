require 'spec_helper'

describe SitesPermission do
  it { should belong_to :membership }

  describe "convert to json" do
    its(:to_json) { should_not include "\"id\":" }
    its(:to_json) { should_not include "\"membership_id\":" }
    its(:to_json) { should_not include "\"created_at\":" }
    its(:to_json) { should_not include "\"updated_at\":" }
  end

  it "should have no_permission" do
    SitesPermission.no_permission.should == { read: nil, write: nil }
  end
end

require 'spec_helper'

describe String do
  let!(:template_string) { 'Dear [Site Name], your balance is now [money].' }
  
  it "render a string from a template string" do
    expect(template_string.render_template_string({'Site Name' => 'Dane', 'money' => '10$'})).to eq('Dear Dane, your balance is now 10$.')
  end

end


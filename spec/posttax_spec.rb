require "spec_helper"
require "date"

describe "PostTax" do
  before :each do
    credentials = YAML::load(File.open('credentials.yml'))
    @creds = {:username => credentials['username'], 
          :password => credentials['password'],  
          :clientname => credentials['clientname'],
          :use_production_url => credentials['production']}
    @svc = AvaTax::TaxService.new(@creds)
    @get_tax_request = {
      :doctype => "SalesInvoice",
      :commit => false,
      :detaillevel => "Tax",
      :docdate=>DateTime.now.strftime("%Y-%m-%d"),
      :customercode => "CUST123",
      :origincode => "456",
      :destinationcode => "456",
      :addresses=>[{
        :addresscode=>"456", 
        :line1=>"7070 West Arlington Drive", 
        :postalcode=>"80123", 
        :country=>"US", 
        }], 
      :lines=>[{
        :no=>"1", 
        :itemcode=>"Canoe", 
        :qty=>"1",
        :amount=>"300.43", 
        :description=>"Blue canoe",
        }]}
    
    @get_tax_result = @svc.gettax(@get_tax_request)
        
    @request_required = {
      :companycode => @get_tax_result[:company_code],
      :doctype => @get_tax_result[:doc_type],
      :doccode => @get_tax_result[:doc_code],
      :commit => false,
      :docdate => @get_tax_result[:doc_date],
      :totalamount => @get_tax_result[:total_amount],
      :totaltax => @get_tax_result[:total_tax],
      
    }
    @request_optional = {
      :docid => @get_tax_result[:doc_id],
      :newdoccode => "new doc code: "+ @get_tax_result[:doc_code],
    }

          
  end
  
  describe "returns a meaningful" do
    it "error when URL is missing" do
      @creds[:use_production_url] = nil
      @service = AvaTax::TaxService.new(@creds)
      @service.posttax(@request_required)[:result_code].should eql "Success"
    end
    it "success when URL is specified" do
      @creds[:use_production_url] = false
      @service = AvaTax::TaxService.new(@creds)
      @service.posttax(@request_required)[:result_code].should eql "Success"
    end
    it "error when username is missing" do
      @creds[:username] = nil
      @service = AvaTax::TaxService.new(@creds)
      @service.posttax(@request_required)[:result_code].should eql "Error"
    end
    it "error when password is omitted" do
      @creds[:password] = nil
      @service = AvaTax::TaxService.new(@creds)
      @service.posttax(@request_required)[:result_code].should eql "Error"
    end
    it "success when clientname is omitted" do
      @creds[:clientname] = nil
      @service = AvaTax::TaxService.new(@creds)
      @service.posttax(@request_required)[:result_code].should eql "Success"
    end     
  end
  
  describe "has consistent formatting for" do
    it "server-side errors" do
      @creds[:password] = nil
      @service = AvaTax::TaxService.new(@creds)
      @result = @service.posttax(@request_required)
      @result[:result_code].should eql "Error"
      @result[:messages][:message].should be_a Array
      @result[:messages][:message][0].should include(:details => "The user or account could not be authenticated.")
    end
    it "successful results" do
      @service = AvaTax::TaxService.new(@creds)
      @result = @service.posttax(@request_required)
      @result[:result_code].should eql "Success" and @result[:transaction_id].should_not be_nil
    end
  end  
  describe "requests with" do
    it "missing required parameters fail" do
      @service = AvaTax::TaxService.new(@creds)
      @result = @service.posttax(@request_optional)
      @result[:result_code].should eql "Error" 
    end
    it "invalid parameters ignore them" do
      @service = AvaTax::TaxService.new(@creds)
      @request_required[:bogus] = "data"
      @result = @service.posttax(@request_required)
      @result[:result_code].should eql "Success" 
    end
    it "missing optional parameters succeed" do
      @service = AvaTax::TaxService.new(@creds)
      @result = @service.posttax(@request_required)
      @result[:result_code].should eql "Success" 
    end
    it "all parameters succeed" do
      @service = AvaTax::TaxService.new(@creds)
      @result = @service.posttax(@request_required.merge(@request_optional))
      @result[:result_code].should eql "Success" 
    end
  end
  describe "workflow" do
    it "should succeed on tax amount mismatch" do
      @request_required[:totaltax] = @request_required[:totalamount]
      @result = @svc.posttax(@request_required)
      @history_request = { 
        :doccode => @request_required[:doccode],
        :companycode => @request_required[:companycode],
        :doctype => @request_required[:doctype],
      }
      @history_result = @svc.gettaxhistory(@history_request)
      @result[:result_code].should eql "Warning" and 
      @history_result[:get_tax_result][:doc_status].should eql "Posted"
    end
    it "should succeed on total amount mismatch" do
      @request_required[:totalamount] = @request_required[:totaltax]
      @result = @svc.posttax(@request_required)
      @history_request = { 
        :doccode => @request_required[:doccode],
        :companycode => @request_required[:companycode],
        :doctype => @request_required[:doctype],
      }
      @history_result = @svc.gettaxhistory(@history_request)
      @result[:result_code].should eql "Warning" and 
      @history_result[:get_tax_result][:doc_status].should eql "Posted"
    end
    it "should be able to change the doc code" do
      @request_required[:newdoccode] = "new doc code: "+ @get_tax_result[:doc_code]
      @result = @svc.posttax(@request_required)
      @history_request = { 
        :doccode => @request_required[:newdoccode],
        :companycode => @request_required[:companycode],
        :doctype => @request_required[:doctype],
      }
      @history_result = @svc.gettaxhistory(@history_request)
      @result[:result_code].should eql "Success" and 
      @history_result[:result_code].should eql "Success"
    end
    it "should be able to commit documents" do
      @request_required[:commit] = true
      @result = @svc.posttax(@request_required)
      @history_request = { 
        :doccode => @request_required[:doccode],
        :companycode => @request_required[:companycode],
        :doctype => @request_required[:doctype],
      }
      @history_result = @svc.gettaxhistory(@history_request)
      @result[:result_code].should eql "Success" and 
      @history_result[:get_tax_result][:doc_status].should eql "Committed"
    end
  end
  
end
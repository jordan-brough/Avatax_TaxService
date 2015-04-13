require_relative '../Avatax_TaxService/lib/avatax_taxservice.rb'
#require 'Avatax_TaxService'

accountNumber = "1234567890"
licenseKey = "A1B2C3D4E5F6G7H8"
useProductionURL = false

# Header Level Parameters
taxSvc = AvaTax::TaxService.new(

# Required Header Parameters
  :username => accountNumber, 
  :password => licenseKey,  
  :use_production_url => useProductionURL,
  :clientname => "AvaTaxSample",

# Optional Header Parameters  
  :name => "Development") 

getTaxRequest = {  
  # Document Level Parameters
  # Required Request Parameters
  :customercode => "ABC4335",
  :docdate => "2014-01-01",
  
  # Best Practice Request Parameters
  :companycode => "APITrialCompany",
  :doccode => "INV001",
  :detaillevel => "Tax",
  :commit => false,
  :doctype => "SalesInvoice",

  # Situational Request Parameters
  # :businessidentificationno => "234243",
  # :customerusagetype => "G",
  # :exemptionno => "12345",
  # :discount => 50,
  # :locationcode => "01",
  # :taxoverridetype => "TaxDate",
  # :reason => "Adjustment for return",
  # :taxdate => "2013-07-01",
  # :taxamount => "0",
  # :servicemode => "Automatic",

  # Optional Request Parameters
  :purchaseorderno => "PO123456",
  :referencecode => "ref123456",
  :poslanecode => "09",
  :currencycode => "USD",
  :exchangerate => "1.0",
  :exchangerateeffdate => "2013-01-01",
  :salespersoncode => "Bill Sales",

  # Address Data
  :addresses => 
  [
    {
    :addresscode => "01",
    :line1 => "45 Fremont Street",
    :city => "San Francisco",
    :region => "CA",
    },
    {
    :addresscode => "02",
    :line1 => "118 N Clark St",
    :line2 => "Suite 100",
    :line3 => "ATTN Accounts Payable",
    :city => "Chicago",
    :region => "IL",
    :country => "US",
    :postalcode => "60602",
    },
    {
    :addresscode => "03",
    :latitude => "47.627935",
    :longitude => "-122.51702",
    }
  ],

  # Line Data
  :lines => 
  [
    {
    
    # Required Parameters
    :no => "01",
    :itemcode => "N543",
    :qty => 1,
    :amount => 10,
    :origincode => "01",
    :destinationcode => "02",

    # Best Practice Request Parameters
    :description => "Red Size 7 Widget",
    :taxcode => "NT",

    # Situational Request Parameters
    # :customerusagetype => "L",
    # :exemptionno => "12345",
    # :discounted => true,
    # :taxincluded => true,
    # :taxoverridetypeline => "TaxDate",
    # :reasonline => "Adjustment for return",
    # :taxdateline => "2013-07-01",
    # :taxamountline => "0",

    # Optional Request Parameters
    :ref1 => "ref123",
    :ref2 => "ref456",
    },
    {
    :no => "02",
    :itemcode => "T345",
    :qty => 3,
    :amount => 150,
    :origincode => "01",
    :destinationcode => "03",
    :description => "Size 10 Green Running Shoe",
    :taxcode => "PC030147",
    },
    {
    :no => "02-FR",
    :itemcode => "FREIGHT",
    :qty => 1,
    :amount => 15,
    :origincode => "01",
    :destinationcode => "03",
    :description => "Shipping Charge",
    :taxcode => "FR",
    }
  ]
}

getTaxResult = taxSvc.gettax(getTaxRequest)

# Print Results
puts "GetTaxTest ResultCode: " + getTaxResult[:result_code]
if getTaxResult[:result_code] != "Success"
    getTaxResult[:messages].each { |message| puts message[:details] }
else
  puts "Document Code: " + getTaxResult[:doc_code] + 
    " Total Tax: " + getTaxResult[:total_tax].to_s
  getTaxResult[:tax_lines][:tax_line].each do |taxLine|
      puts "    " + "Line Number: " + taxLine[:no] + " Line Tax: " + taxLine[:tax].to_s
      taxLine[:tax_details][:tax_detail].each do |taxDetail| 
          puts "        " + "Jurisdiction: " + taxDetail[:juris_name] + " Tax: " + taxDetail[:tax].to_s
      end
  end
end
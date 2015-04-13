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

getTaxHistoryRequest = {  
# Required Request Parameters
  :companycode => "APITrialCompany",
  :doctype => "SalesInvoice",
  :doccode => "INV001",
  
# Optional Request Parameters
  :detaillevel=>"Tax"
}

getTaxHistoryResult = taxSvc.gettaxhistory(getTaxHistoryRequest)

# Print Results
puts "GetTaxHistoryTest ResultCode: " + getTaxHistoryResult[:result_code]
if getTaxHistoryResult[:result_code] != "Success"
  getTaxHistoryResult[:messages].each { |message| puts message[:details] }
else
  puts "Document Code: " + getTaxHistoryResult[:get_tax_result][:doc_code] + 
    " Total Tax: " + getTaxHistoryResult[:get_tax_result][:total_tax].to_s
  getTaxHistoryResult[:get_tax_result][:tax_lines][:tax_line].each do |taxLine|
      puts "    " + "Line Number: " + taxLine[:no] + " Line Tax: " + taxLine[:tax].to_s
      taxLine[:tax_details][:tax_detail].each do |taxDetail| 
          puts "        " + "Jurisdiction: " + taxDetail[:juris_name] + " Tax: " + taxDetail[:tax].to_s
      end
  end
end
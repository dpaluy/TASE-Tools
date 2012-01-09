require "rubygems"
require "watir-webdriver"
require 'date'

@OUTPUT_FOLDER = "RESULT"

def month_range(from, to)
  from, to = to, from if from > to
  m = Date.new from.year, from.month
  result = []
  while m <= to
    result << m
    m >>= 1
  end

  result
end

def rename_file(new_name)
  today = Date.today.strftime("%Y%m%d")
  cmd = "mv $HOME/Downloads/Data_#{today}.csv #{@OUTPUT_FOLDER}/#{new_name}.csv"
  result = %x[ #{cmd} ]
end

def extract_csv(strike, exp)
  @browser.radio(:id => "GetDerivativeUC1_rblType_1").set # PUT
  @browser.select_list(:id => "GetDerivativeUC1_cmbDate").select_value(exp)
  sleep 5
  @browser.select_list(:id => "GetDerivativeUC1_cmbPriceOrDerivative").select "#{strike}.00"
  sleep 2
  @browser.execute_script("frmsubmit('0')")
  sleep 10
  @browser.execute_script("OpenExportTable('gridHistoryDataExportButtonUC1')")
  @browser.execute_script("customWindowOpen('/TASE/Pages/Export.aspx?tbl=0&Columns=AddColColumnsHistory&Titles=AddColTitlesHistory&sn=dsHistory&enumTblType=GridHistorydaily&ExportType=3', '_blank', 'scrollbars=yes; toolbar=yes; menubar=yes; resizable=yes', 800, 450);return false;")  
end

def extract_first_csv(strike, exp)
  @browser.radio(:id => "GetDerivativeUC1_rblType_1").set # PUT
  @browser.select_list(:id => "GetDerivativeUC1_cmbDate").select_value(exp)
  sleep 5
  @browser.select_list(:id => "GetDerivativeUC1_cmbPriceOrDerivative").select "#{strike}.00"
  sleep 2
  @browser.radio(:id => "HistoryData1_rbPeriod5").set
  sleep 1
  @browser.checkbox(:id => "HistoryData1_CBDailyDFiledsList_1").clear
  @browser.checkbox(:id => "HistoryData1_CBDailyDFiledsList_4").clear
  @browser.checkbox(:id => "HistoryData1_CBDailyDFiledsList_5").clear
  @browser.checkbox(:id => "HistoryData1_CBDailyDFiledsList_6").clear
  @browser.checkbox(:id => "HistoryData1_CBDailyDFiledsList_7").clear
  @browser.checkbox(:id => "HistoryData1_CBDailyDFiledsList_8").clear
  sleep 1
  @browser.execute_script("frmsubmit('0')")
  sleep 10
  @browser.execute_script("OpenExportTable('gridHistoryDataExportButtonUC1')")
  @browser.execute_script("customWindowOpen('/TASE/Pages/Export.aspx?tbl=0&Columns=AddColColumnsHistory&Titles=AddColTitlesHistory&sn=dsHistory&enumTblType=GridHistorydaily&ExportType=3', '_blank', 'scrollbars=yes; toolbar=yes; menubar=yes; resizable=yes', 800, 450);return false;")  
end

def getcsv(strike, exp)
  extract_csv(strike, exp.strftime('%d/%m/%Y'))  
  new_name = "P#{strike}#{exp.strftime('%b%y')}"
  sleep 3
  rename_file(new_name)
  puts "#{new_name} ready"
end

#main
cmd = "mkdir #{@OUTPUT_FOLDER}"
result = %x[ #{cmd}]
@browser = Watir::Browser.new :ff
@browser.goto "http://www.tase.co.il/TASEEng/MarketData/DerivativesMarket/Derivatives.htm?SubAction=5&Action=1&Type=1"

extract_first_csv("1000", '01/01/2012')
sleep 10
from = Date.new(2012, 1, 1)
to = Date.new(2012, 1, 1)
strike_range = 900..1150
month_range(from, to).each do |exp|
  strike_range.step(10).each { |strike| getcsv(strike, exp) }
end

@browser.close
